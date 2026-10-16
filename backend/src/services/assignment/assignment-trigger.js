const logger = require('../../utils/logger');
const engine = require('./assignment-engine.service');

/**
 * Instant and Express start the pickup search now.
 * Scheduled pickup waits until pickup_time_from (delay 0 if already past).
 */
async function onOrderPlaced(order) {
    const deliveryType = 'pickup';
    const instant = order.is_express || order.pickup_mode === 'instant' || !order.pickup_time_from;
    if (instant) {
        await engine.startSearch({ orderId: order.order_id, deliveryType });
        return;
    }
    const runAt = new Date(order.pickup_time_from);
    if (runAt.getTime() <= Date.now()) {
        await engine.startSearch({ orderId: order.order_id, deliveryType });
        return;
    }
    try {
        const queue = require('./assignment.queue');
        await queue.scheduleDelayedStart({
            orderId: order.order_id,
            deliveryType,
            runAt,
        });
        logger.info('Scheduled pickup search', { orderId: order.order_id, runAt });
    } catch (err) {
        logger.warn('Could not delay pickup search; catch-up will start it', {
            orderId: order.order_id,
            error: err.message,
        });
    }
}

module.exports = {
    onOrderPlaced,
};
