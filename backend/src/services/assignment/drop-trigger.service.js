const prisma = require('../../config/database');
const logger = require('../../utils/logger');
const engine = require('./assignment-engine.service');

/**
 * Starts the drop search once every service on the order is done.
 * Instant and Express start immediately. A future scheduled window waits.
 */
async function evaluate(orderId, now = new Date()) {
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: {
            order_id: true,
            order_status: true,
            is_express: true,
            delivery_mode: true,
            delivery_time_from: true,
        },
    });
    if (!order || order.order_status === 'cancelled') return { started: false, reason: 'missing_or_cancelled' };
    if (order.order_status !== 'services_completed') return { started: false, reason: 'not_ready' };

    const drop = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: 'drop' },
    });
    if (!drop) return { started: false, reason: 'no_drop_leg' };
    if (drop.staff_id) return { started: false, reason: 'already_assigned' };

    const pending = await prisma.deliveryAssignmentRequest.findFirst({
        where: { delivery_id: drop.delivery_id, status: 'pending' },
    });
    if (pending) return { started: false, reason: 'search_running' };

    const immediate =
        order.is_express ||
        order.delivery_mode === 'instant' ||
        (order.delivery_time_from && new Date(order.delivery_time_from) <= now);

    if (immediate) {
        await engine.startSearch({ orderId, deliveryType: 'drop', now });
        return { started: true, mode: 'now' };
    }

    if (order.delivery_time_from) {
        try {
            const queue = require('./assignment.queue');
            await queue.scheduleDelayedStart({
                orderId,
                deliveryType: 'drop',
                runAt: order.delivery_time_from,
            });
        } catch (error) {
            logger.warn('Failed to schedule delayed drop search; catch-up will cover it', {
                orderId,
                error: error.message,
            });
        }
        return { started: false, mode: 'scheduled', availableFrom: order.delivery_time_from };
    }

    await engine.startSearch({ orderId, deliveryType: 'drop', now });
    return { started: true, mode: 'now' };
}

module.exports = { evaluate };
