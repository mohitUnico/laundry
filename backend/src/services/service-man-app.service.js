const prisma = require('../config/database');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');

const normalizePagination = ({ page = 1, limit = 20 } = {}) => {
    const safePage = Number.isInteger(page) ? page : parseInt(page, 10);
    const safeLimit = Number.isInteger(limit) ? limit : parseInt(limit, 10);
    if (!Number.isInteger(safePage) || safePage < 1) throw new ValidationError('page must be >= 1');
    if (!Number.isInteger(safeLimit) || safeLimit < 1 || safeLimit > 100) {
        throw new ValidationError('limit must be between 1 and 100');
    }
    return { safePage, safeLimit, skip: (safePage - 1) * safeLimit };
};

const parseStatusList = (statusCsv) => {
    const raw = typeof statusCsv === 'string' ? statusCsv : '';
    const parts = raw
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
    const allowed = new Set(['pending', 'in_progress', 'completed']);
    const list = parts.length > 0 ? parts : ['pending', 'in_progress'];
    const invalid = list.filter((s) => !allowed.has(s));
    if (invalid.length > 0) throw new ValidationError(`Invalid queue status filter: ${invalid.join(', ')}`);
    return list;
};

const mapQueueItem = (q) => ({
    queueId: q.queue_id,
    orderId: q.order_id,
    orderItemId: q.item_id,
    serviceId: q.service_id,
    itemName: q.item_name,
    quantity: (q.quantity != null) ? q.quantity : null,
    weightKg: (q.weight_kg?.toString?.() != null) ? q.weight_kg.toString() : ((q.weight_kg != null) ? q.weight_kg : null),
    queueStatus: q.queue_status,
    priority: q.priority,
    assignedAt: q.assigned_at,
    startedAt: q.started_at,
    completedAt: q.completed_at,
    comments: q.comments || null,
    order: q.order
        ? {
            orderStatus: q.order.order_status,
            orderType: q.order.order_type,
            customer: q.order.customer
                ? {
                    customerId: q.order.customer.customer_id,
                    fullName: q.order.customer.full_name,
                    phone: q.order.customer.phone || null,
                }
                : null,
        }
        : null,
});

exports.listQueue = async ({ staffId, status, page, limit } = {}) => {
    if (!staffId) throw new ValidationError('staffId is required');
    const statusList = parseStatusList(status);
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = {
        service_man_id: staffId,
        queue_status: { in: statusList.filter((s) => s !== 'completed') },
    };

    const [total, rows] = await Promise.all([
        prisma.serviceQueueItem.count({ where }),
        prisma.serviceQueueItem.findMany({
            where,
            orderBy: [{ priority: 'asc' }, { assigned_at: 'asc' }],
            skip,
            take: safeLimit,
            include: {
                order: {
                    select: {
                        order_status: true,
                        order_type: true,
                        customer: { select: { customer_id: true, full_name: true, phone: true } },
                    },
                },
            },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        queue: rows.map(mapQueueItem),
    };
};

exports.updateQueueItem = async ({ staffId, queueId, action, comments }) => {
    if (!staffId) throw new ValidationError('staffId is required');
    if (!queueId) throw new ValidationError('queueId is required');
    if (!['in_progress', 'completed', 'mark_for_later'].includes(action)) throw new ValidationError('Invalid action');

    const now = new Date();

    return prisma.$transaction(async (tx) => {
        const q = await tx.serviceQueueItem.findUnique({
            where: { queue_id: queueId },
            select: {
                queue_id: true,
                service_man_id: true,
                queue_status: true,
                order_id: true,
                item_id: true,
                service_id: true,
            },
        });
        if (!q) throw new NotFoundError('ServiceQueueItem');
        if (q.service_man_id !== staffId) throw new ConflictError('Queue item does not belong to this service man');

        if (action === 'in_progress') {
            if (q.queue_status === 'completed') throw new ConflictError('Queue item is already completed');

            await tx.serviceQueueItem.update({
                where: { queue_id: queueId },
                data: {
                    queue_status: 'in_progress',
                    started_at: now,
                    ...(typeof comments === 'string' ? { comments } : {}),
                },
            });

            await tx.orderItem.update({
                where: { item_id: q.item_id },
                data: { item_status: 'in_progress' },
            });

            await tx.order.update({
                where: { order_id: q.order_id },
                data: { order_status: 'services_in_progress' },
            });
        }

        if (action === 'completed') {
            if (q.queue_status === 'completed') throw new ConflictError('Queue item is already completed');

            await tx.serviceQueueItem.update({
                where: { queue_id: queueId },
                data: {
                    queue_status: 'completed',
                    completed_at: now,
                    ...(typeof comments === 'string' ? { comments } : {}),
                },
            });

            await tx.orderItem.update({
                where: { item_id: q.item_id },
                data: { item_status: 'completed', completed_at: now },
            });

            const remaining = await tx.serviceQueueItem.count({
                where: { order_id: q.order_id, queue_status: { not: 'completed' } },
            });

            await tx.order.update({
                where: { order_id: q.order_id },
                data: { order_status: remaining === 0 ? 'services_completed' : 'services_in_progress' },
            });
        }

        if (action === 'mark_for_later') {
            if (q.queue_status === 'completed') throw new ConflictError('Cannot requeue a completed item');

            const agg = await tx.serviceQueueItem.aggregate({
                where: { service_man_id: staffId, queue_status: 'pending' },
                _max: { priority: true },
            });
            const newPriority = ((agg?._max?.priority != null) ? agg._max.priority : 0) + 1;

            await tx.serviceQueueItem.update({
                where: { queue_id: queueId },
                data: {
                    queue_status: 'pending',
                    priority: newPriority,
                    started_at: null,
                    ...(typeof comments === 'string' ? { comments } : {}),
                },
            });

            await tx.orderItem.update({
                where: { item_id: q.item_id },
                data: { item_status: 'pending' },
            });
        }

        const refreshed = await tx.serviceQueueItem.findUnique({
            where: { queue_id: queueId },
            include: {
                order: {
                    select: {
                        order_status: true,
                        order_type: true,
                        customer: { select: { customer_id: true, full_name: true, phone: true } },
                    },
                },
            },
        });

        return mapQueueItem(refreshed);
    });
};

exports.listCompleted = async ({ staffId, page, limit } = {}) => {
    if (!staffId) throw new ValidationError('staffId is required');
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = { service_man_id: staffId, queue_status: 'completed' };

    const [total, rows] = await Promise.all([
        prisma.serviceQueueItem.count({ where }),
        prisma.serviceQueueItem.findMany({
            where,
            orderBy: { completed_at: 'desc' },
            skip,
            take: safeLimit,
            include: {
                order: {
                    select: {
                        order_status: true,
                        order_type: true,
                        customer: { select: { customer_id: true, full_name: true, phone: true } },
                    },
                },
                orderItem: {
                    select: {
                        item_id: true,
                        quantity: true,
                        weight_kg: true,
                        created_at: true,
                        completed_at: true,
                    },
                },
            },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        completed: rows.map((q) => ({
            queueId: q.queue_id,
            orderId: q.order_id,
            orderItemId: q.item_id,
            itemName: q.item_name,
            addedOn: q.assigned_at,
            completedOn: q.completed_at,
            clothItemsCount: (q.orderItem?.quantity != null) ? q.orderItem.quantity : null,
            weightKg: (q.orderItem?.weight_kg?.toString?.() != null) ? q.orderItem.weight_kg.toString() : ((q.orderItem?.weight_kg != null) ? q.orderItem.weight_kg : null),
            order: q.order
                ? {
                    orderStatus: q.order.order_status,
                    orderType: q.order.order_type,
                    customer: q.order.customer
                        ? {
                            customerId: q.order.customer.customer_id,
                            fullName: q.order.customer.full_name,
                            phone: q.order.customer.phone || null,
                        }
                        : null,
                }
                : null,
        })),
    };
};

module.exports = exports;

