const prisma = require('../config/database');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');
const { validateSchedule } = require('./schedule-rules');
const engine = require('./assignment/assignment-engine.service');
const { onOrderPlaced } = require('./assignment/assignment-trigger');
const { DELIVERY_STATUS } = require('../constants/order-flow');

async function cancelOrder(customerId, orderId, reason) {
    const trimmed = typeof reason === 'string' ? reason.trim() : '';
    if (trimmed.length < 3 || trimmed.length > 500) {
        throw new ValidationError('reason is required (3 to 500 characters)');
    }

    const when = new Date();
    const updated = await prisma.order.updateMany({
        where: { order_id: orderId, customer_id: customerId, order_status: 'placed' },
        data: {
            order_status: 'cancelled',
            cancel_reason: trimmed,
            cancelled_at: when,
        },
    });
    if (updated.count === 0) {
        const exists = await prisma.order.findFirst({
            where: { order_id: orderId, customer_id: customerId },
            select: { order_id: true },
        });
        if (!exists) throw new NotFoundError('Order');
        throw new ConflictError('Order can only be cancelled while it is placed', 'CANCEL_NOT_ALLOWED');
    }

    await prisma.delivery.updateMany({
        where: { order_id: orderId },
        data: { delivery_status: DELIVERY_STATUS.CANCELLED },
    });
    await engine.stopSearch(orderId, 'pickup', 'cancelled', { now: when });
    require('./notification-events').emitOrderEvent('cancelled', { orderId }).catch(() => {});

    return { order_id: orderId, order_status: 'cancelled', cancel_reason: trimmed, cancelled_at: when };
}

async function rescheduleOrder(customerId, orderId, body) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status !== 'placed' || order.is_express) {
        throw new ConflictError('Order cannot be rescheduled', 'RESCHEDULE_NOT_ALLOWED');
    }

    const schedule = await validateSchedule({
        is_express: false,
        pickup_mode: body.pickup_mode || order.pickup_mode,
        delivery_mode: body.delivery_mode || order.delivery_mode,
        pickup_time_from: body.pickup_time_from !== undefined ? body.pickup_time_from : order.pickup_time_from,
        pickup_time_to: body.pickup_time_to !== undefined ? body.pickup_time_to : order.pickup_time_to,
        delivery_time_from: body.delivery_time_from !== undefined ? body.delivery_time_from : order.delivery_time_from,
        delivery_time_to: body.delivery_time_to !== undefined ? body.delivery_time_to : order.delivery_time_to,
    });

    const locked = await prisma.order.updateMany({
        where: { order_id: orderId, customer_id: customerId, order_status: 'placed', is_express: false },
        data: {
            pickup_mode: schedule.pickup_mode,
            delivery_mode: schedule.delivery_mode,
            pickup_time_from: schedule.pickup_time_from,
            pickup_time_to: schedule.pickup_time_to,
            delivery_time_from: schedule.delivery_time_from,
            delivery_time_to: schedule.delivery_time_to,
        },
    });
    if (locked.count === 0) {
        throw new ConflictError('Order cannot be rescheduled', 'RESCHEDULE_NOT_ALLOWED');
    }

    await engine.stopSearch(orderId, 'pickup', 'rescheduled');
    require('./notification-events').emitOrderEvent('rescheduled', { orderId }).catch(() => {});
    await onOrderPlaced({
        order_id: orderId,
        is_express: false,
        pickup_mode: schedule.pickup_mode,
        pickup_time_from: schedule.pickup_time_from,
    });

    return {
        order_id: orderId,
        order_status: 'placed',
        ...schedule,
    };
}

module.exports = {
    cancelOrder,
    rescheduleOrder,
};
