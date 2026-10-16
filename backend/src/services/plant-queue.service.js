const prisma = require('../config/database');
const configService = require('./config.service');
const { assertTransition, ORDER_STATUS } = require('../constants/order-flow');
const { ConflictError, ForbiddenError, NotFoundError, ValidationError } = require('../utils/errors');
const { emitOrderEvent } = require('./notification-events');
const dropTrigger = require('./assignment/drop-trigger.service');

async function loadServiceMan(staffId) {
    const staff = await prisma.staff.findUnique({
        where: { staff_id: staffId },
        include: { service: true },
    });
    if (!staff || staff.role !== 'service_man' || !staff.is_active) {
        throw new ForbiddenError('Only an active service man can use this queue');
    }
    if (!staff.service_id) {
        throw new ConflictError('This service man is not assigned to a service', 'NO_SERVICE');
    }
    return staff;
}

async function submitToServices({ orderId }) {
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        include: {
            order_items: { include: { service: true, item_selections: true } },
        },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status !== ORDER_STATUS.RECEIVED_BY_COLLECTION) {
        throw new ConflictError('Submit to services is only allowed after the plant has received the order', 'SUBMIT_NOT_ALLOWED');
    }
    assertTransition(order.order_status, ORDER_STATUS.SUBMITTED_TO_SERVICES);

    const serviceIds = [...new Set(order.order_items.map((item) => item.service_id))];
    const men = await prisma.staff.findMany({
        where: {
            role: 'service_man',
            is_active: true,
            service_id: { in: serviceIds },
        },
    });
    const manByService = new Map(men.map((man) => [man.service_id, man]));
    const missing = order.order_items
        .filter((item) => !manByService.has(item.service_id))
        .map((item) => item.service?.service_name || item.service_id);
    if (missing.length) {
        const err = new ConflictError(
            `No active service man for: ${[...new Set(missing)].join(', ')}`,
            'NO_SERVICE_MAN'
        );
        err.details = { services: [...new Set(missing)] };
        throw err;
    }

    const now = new Date();
    await prisma.$transaction(async (tx) => {
        const moved = await tx.order.updateMany({
            where: { order_id: orderId, order_status: ORDER_STATUS.RECEIVED_BY_COLLECTION },
            data: {
                order_status: ORDER_STATUS.SUBMITTED_TO_SERVICES,
                submitted_to_services_at: now,
            },
        });
        if (moved.count === 0) {
            throw new ConflictError('Order was already submitted to services', 'SUBMIT_NOT_ALLOWED');
        }
        for (const item of order.order_items) {
            const man = manByService.get(item.service_id);
            const name = item.service?.service_name || 'Service';
            await tx.serviceQueueItem.create({
                data: {
                    order_id: orderId,
                    service_id: item.service_id,
                    service_man_id: man.staff_id,
                    item_id: item.item_id,
                    item_name: name,
                    quantity: item.quantity,
                    weight_kg: item.weight_kg,
                    queue_status: 'pending',
                    is_express: order.is_express,
                    assigned_at: now,
                },
            });
        }
    });
    return { orderId, orderStatus: ORDER_STATUS.SUBMITTED_TO_SERVICES, queueItems: order.order_items.length };
}

function mapQueueRow(row) {
    return {
        queueId: row.queue_id,
        orderId: row.order_id,
        serviceId: row.service_id,
        serviceName: row.service?.service_name || row.item_name,
        isExpress: row.is_express,
        pricingType: row.orderItem?.pricing_type || null,
        quantity: row.quantity,
        weightKg: row.weight_kg == null ? null : String(row.weight_kg),
        status: row.queue_status,
        assignedAt: row.assigned_at,
    };
}

async function listQueue({ staffId }) {
    const staff = await loadServiceMan(staffId);
    const pollSeconds = await configService.getInt('SERVICE_QUEUE_POLL_SECONDS');
    const items = await prisma.serviceQueueItem.findMany({
        where: {
            service_id: staff.service_id,
            queue_status: { in: ['pending', 'in_progress'] },
        },
        include: { service: true, orderItem: true },
        orderBy: [{ is_express: 'desc' }, { assigned_at: 'asc' }],
    });
    return {
        serviceId: staff.service_id,
        serviceName: staff.service?.service_name || null,
        pollSeconds,
        items: items.map(mapQueueRow),
    };
}

async function listHistory({ staffId, page = 1, limit = 20 }) {
    const staff = await loadServiceMan(staffId);
    const skip = (Number(page) - 1) * Number(limit);
    const where = { service_id: staff.service_id, queue_status: 'completed' };
    const [items, total] = await Promise.all([
        prisma.serviceQueueItem.findMany({
            where,
            include: { service: true, orderItem: true },
            orderBy: { completed_at: 'desc' },
            skip,
            take: Number(limit),
        }),
        prisma.serviceQueueItem.count({ where }),
    ]);
    return { items: items.map(mapQueueRow), pagination: { page: Number(page), limit: Number(limit), total } };
}

async function updateQueueStatus({ staffId, queueId, action }) {
    if (!['in_progress', 'completed'].includes(action)) {
        throw new ValidationError('action must be in_progress or completed');
    }
    const staff = await loadServiceMan(staffId);
    const now = new Date();
    const outcome = await prisma.$transaction(async (tx) => {
        const item = await tx.serviceQueueItem.findUnique({
            where: { queue_id: queueId },
            include: { order: true },
        });
        if (!item) throw new NotFoundError('Queue item');
        if (item.service_id !== staff.service_id) {
            throw new ForbiddenError('This queue item belongs to another service');
        }
        if (item.queue_status === 'completed') {
            throw new ConflictError('Queue item is already completed', 'QUEUE_CLOSED');
        }
        if (action === 'in_progress' && item.queue_status === 'in_progress') {
            return { orderId: item.order_id, status: 'in_progress', becameCompleted: false, allDone: false };
        }
        if (action === 'in_progress' && item.queue_status !== 'pending') {
            throw new ConflictError('Only a pending item can be started', 'QUEUE_CLOSED');
        }

        await tx.serviceQueueItem.update({
            where: { queue_id: queueId },
            data: {
                queue_status: action,
                service_man_id: staff.staff_id,
                ...(action === 'in_progress' ? { started_at: now } : { completed_at: now }),
            },
        });

        let servicesStarted = false;
        if (action === 'in_progress' && item.order.order_status === ORDER_STATUS.SUBMITTED_TO_SERVICES) {
            assertTransition(item.order.order_status, ORDER_STATUS.SERVICES_IN_PROGRESS);
            const moved = await tx.order.updateMany({
                where: { order_id: item.order_id, order_status: ORDER_STATUS.SUBMITTED_TO_SERVICES },
                data: { order_status: ORDER_STATUS.SERVICES_IN_PROGRESS },
            });
            servicesStarted = moved.count > 0;
        }

        let allDone = false;
        if (action === 'completed') {
            await tx.$queryRaw`SELECT order_id FROM orders WHERE order_id = ${item.order_id}::uuid FOR UPDATE`;
            await tx.orderItem.update({
                where: { item_id: item.item_id },
                data: { item_status: 'completed', completed_at: now },
            });
            const open = await tx.serviceQueueItem.count({
                where: {
                    order_id: item.order_id,
                    queue_status: { in: ['pending', 'in_progress'] },
                },
            });
            if (open === 0) {
                const current = await tx.order.findUnique({
                    where: { order_id: item.order_id },
                    select: { order_status: true },
                });
                if (current.order_status === ORDER_STATUS.SUBMITTED_TO_SERVICES) {
                    assertTransition(ORDER_STATUS.SUBMITTED_TO_SERVICES, ORDER_STATUS.SERVICES_IN_PROGRESS);
                    await tx.order.updateMany({
                        where: { order_id: item.order_id, order_status: ORDER_STATUS.SUBMITTED_TO_SERVICES },
                        data: { order_status: ORDER_STATUS.SERVICES_IN_PROGRESS },
                    });
                    current.order_status = ORDER_STATUS.SERVICES_IN_PROGRESS;
                }
                if (current.order_status === ORDER_STATUS.SERVICES_IN_PROGRESS) {
                    assertTransition(ORDER_STATUS.SERVICES_IN_PROGRESS, ORDER_STATUS.SERVICES_COMPLETED);
                    const finished = await tx.order.updateMany({
                        where: { order_id: item.order_id, order_status: ORDER_STATUS.SERVICES_IN_PROGRESS },
                        data: { order_status: ORDER_STATUS.SERVICES_COMPLETED },
                    });
                    allDone = finished.count > 0;
                }
            }
        }
        return { orderId: item.order_id, status: action, servicesStarted, allDone };
    });

    if (outcome.servicesStarted) emitOrderEvent('services_started', { orderId: outcome.orderId }).catch(() => {});
    if (outcome.allDone) {
        emitOrderEvent('services_completed', { orderId: outcome.orderId }).catch(() => {});
        dropTrigger.evaluate(outcome.orderId).catch((error) => {
            require('../utils/logger').warn('Drop trigger failed', { error: error.message, orderId: outcome.orderId });
        });
    }
    return outcome;
}

async function listInPlant() {
    const orders = await prisma.order.findMany({
        where: {
            order_status: {
                in: [
                    ORDER_STATUS.SUBMITTED_TO_SERVICES,
                    ORDER_STATUS.SERVICES_IN_PROGRESS,
                    ORDER_STATUS.SERVICES_COMPLETED,
                ],
            },
        },
        include: {
            service_queue_items: { include: { service: true, service_man: true } },
        },
        orderBy: [{ is_express: 'desc' }, { created_at: 'asc' }],
    });
    return orders.map((order) => ({
        orderId: order.order_id,
        orderStatus: order.order_status,
        isExpress: order.is_express,
        services: order.service_queue_items.map((row) => ({
            queueId: row.queue_id,
            serviceId: row.service_id,
            serviceName: row.service?.service_name || row.item_name,
            serviceManName: row.service_man?.full_name || null,
            status: row.queue_status,
            isExpress: row.is_express,
        })),
    }));
}

module.exports = {
    submitToServices,
    listQueue,
    listHistory,
    updateQueueStatus,
    listInPlant,
};
