const prisma = require('../../config/database');
const logger = require('../../utils/logger');
const engine = require('./assignment-engine.service');

let timer;

async function runAssignmentCatchup(now = new Date()) {
    const placed = await prisma.order.findMany({
        where: {
            order_status: 'placed',
            OR: [{ is_express: true }, { pickup_mode: 'instant' }, { pickup_time_from: { lte: now } }],
        },
        select: { order_id: true },
        take: 50,
    });
    for (const order of placed) {
        const delivery = await prisma.delivery.findFirst({
            where: { order_id: order.order_id, delivery_type: 'pickup', staff_id: null },
        });
        if (!delivery) continue;
        const pending = await prisma.deliveryAssignmentRequest.findFirst({
            where: { delivery_id: delivery.delivery_id, status: 'pending' },
        });
        if (!pending) {
            await engine.startSearch({ orderId: order.order_id, deliveryType: 'pickup', now });
        }
    }

    const readyForDrop = await prisma.order.findMany({
        where: {
            order_status: 'services_completed',
            OR: [{ is_express: true }, { delivery_mode: 'instant' }, { delivery_time_from: { lte: now } }],
        },
        select: { order_id: true },
        take: 50,
    });
    for (const order of readyForDrop) {
        const delivery = await prisma.delivery.findFirst({
            where: { order_id: order.order_id, delivery_type: 'drop', staff_id: null },
        });
        if (!delivery) continue;
        const pending = await prisma.deliveryAssignmentRequest.findFirst({
            where: { delivery_id: delivery.delivery_id, status: 'pending' },
        });
        if (!pending) {
            await engine.startSearch({ orderId: order.order_id, deliveryType: 'drop', now });
        }
    }

    const dueSlices = await prisma.deliveryAssignmentRequest.findMany({
        where: { status: 'pending', next_slice_at: { lte: now } },
        take: 50,
    });
    for (const request of dueSlices) {
        await engine.advanceSlice(request.request_id, {
            now,
            sliceIndex: request.current_slice + 1,
        });
    }

    const expired = await prisma.deliveryAssignmentRequest.findMany({
        where: { status: 'pending', expires_at: { lte: now } },
        take: 50,
    });
    for (const request of expired) {
        await engine.finishTimeout(request.request_id, { now });
    }

    logger.info('Assignment catch-up finished', {
        started: placed.length,
        slices: dueSlices.length,
        timeouts: expired.length,
    });
}

function startAssignmentCatchupJob() {
    if (timer) return;
    timer = setInterval(() => {
        runAssignmentCatchup().catch((err) => {
            logger.error('Assignment catch-up failed', { error: err.message });
        });
    }, 60 * 1000);
    if (typeof timer.unref === 'function') timer.unref();
}

function stopAssignmentCatchupJob() {
    if (timer) {
        clearInterval(timer);
        timer = null;
    }
}

module.exports = {
    runAssignmentCatchup,
    startAssignmentCatchupJob,
    stopAssignmentCatchupJob,
};
