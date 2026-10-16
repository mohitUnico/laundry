const prisma = require('../config/database');
const logger = require('../utils/logger');
const realtimeService = require('./realtime.service');
const { notifyOrderStatusChange } = require('./fcm.service');

/**
 * event -> who hears it, and on which channels.
 * Channels: fcm and whatsapp go to the customer. sse goes to staff.
 * One row per (order, event, recipient, channel) stops engine retries from repeating a push.
 */
const MATRIX = {
    order_placed: { customer: ['fcm', 'whatsapp'], title: 'Order placed' },
    pickup_offered: { offeredStaff: ['sse'], title: 'Pickup nearby' },
    pickup_assigned: { customer: ['fcm', 'whatsapp'], title: 'Pickup partner assigned' },
    picked_up: { customer: ['fcm', 'whatsapp'], title: 'Laundry picked up' },
    bill_ready: { customer: ['fcm'], title: 'Bill ready' },
    submitted_to_cm: { cm: ['sse'], title: 'Order is on its way to the plant' },
    received_at_plant: { customer: ['fcm', 'whatsapp'], title: 'Received at the plant' },
    services_started: { customer: ['fcm'], title: 'Services started' },
    services_completed: { customer: ['fcm'], dm: ['sse'], title: 'Services completed' },
    drop_offered: { offeredStaff: ['sse'], title: 'Delivery nearby' },
    out_for_delivery: { customer: ['fcm', 'whatsapp'], title: 'Out for delivery' },
    payment_received: { customer: ['fcm', 'whatsapp'], dropStaff: ['sse'], title: 'Payment received' },
    payment_failed: { customer: ['fcm'], dropStaff: ['sse'], title: 'Payment failed' },
    delivered: { customer: ['fcm', 'whatsapp'], title: 'Delivered' },
    cancelled: { customer: ['fcm', 'whatsapp'], offeredStaff: ['sse'], title: 'Order cancelled' },
    rescheduled: { offeredStaff: ['sse'], title: 'Pickup offers withdrawn' },
    assignment_timeout: { manager: ['sse'], title: 'Assignment timed out' },
};

async function claim(orderId, event, recipientKey, channel) {
    try {
        await prisma.notificationDelivery.create({
            data: {
                order_id: orderId,
                event,
                recipient_key: recipientKey,
                channel,
            },
        });
        return true;
    } catch (error) {
        if (error.code === 'P2002') return false;
        logger.warn('Notification dedupe write failed', { error: error.message, orderId, event });
        return false;
    }
}

async function staffByRole(role) {
    return prisma.staff.findMany({
        where: { role, is_active: true },
        select: { staff_id: true },
    });
}

async function offeredStaffIds(orderId) {
    const recipients = await prisma.deliveryAssignmentRecipient.findMany({
        where: { request: { order_id: orderId }, status: { in: ['pending', 'accepted'] } },
        select: { staff_id: true },
    });
    return [...new Set(recipients.map((row) => row.staff_id))];
}

async function legStaffId(orderId, deliveryType) {
    const delivery = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: deliveryType, staff_id: { not: null } },
        select: { staff_id: true },
    });
    return delivery?.staff_id || null;
}

async function emitOrderEvent(event, { orderId, deliveryType = null, staffIds = null } = {}) {
    const spec = MATRIX[event];
    if (!spec || !orderId) return { skipped: true };
    try {
        if (spec.customer) {
            const fresh = await claim(orderId, event, 'customer', 'push');
            if (fresh) {
                await notifyOrderStatusChange({ orderId, status: event });
            }
        }
        const sseTargets = [];
        if (spec.cm) {
            const rows = await staffByRole('collection_manager');
            rows.forEach((row) => sseTargets.push(row.staff_id));
        }
        if (spec.dm) {
            const rows = await staffByRole('distribution_manager');
            rows.forEach((row) => sseTargets.push(row.staff_id));
        }
        if (spec.manager) {
            const role = deliveryType === 'drop' ? 'distribution_manager' : 'collection_manager';
            const rows = await staffByRole(role);
            rows.forEach((row) => sseTargets.push(row.staff_id));
        }
        if (spec.dropStaff) {
            const id = await legStaffId(orderId, 'drop');
            if (id) sseTargets.push(id);
        }
        if (spec.offeredStaff) {
            const ids = staffIds || (await offeredStaffIds(orderId));
            ids.forEach((id) => sseTargets.push(id));
        }
        for (const staffId of [...new Set(sseTargets)]) {
            const fresh = await claim(orderId, event, `staff:${staffId}`, 'sse');
            if (!fresh) continue;
            realtimeService.emitToDeliveryStaff(staffId, event, {
                orderId,
                title: spec.title,
                deliveryType,
            });
        }
        return { ok: true };
    } catch (error) {
        logger.warn('Order event notification failed', { event, orderId, error: error.message });
        return { ok: false };
    }
}

module.exports = {
    MATRIX,
    emitOrderEvent,
};
