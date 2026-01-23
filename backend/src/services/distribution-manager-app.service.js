const prisma = require('../config/database');
const deliveryOperationsService = require('./delivery-operations.service');
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

const mapOrderRow = (o) => ({
    orderId: o.order_id,
    orderStatus: o.order_status,
    orderType: o.order_type,
    createdAt: o.created_at,
    verifiedAt: o.verified_at || null,
    dispatchedAt: o.dispatched_at || null,
    customer: o.customer
        ? {
            customerId: o.customer.customer_id,
            fullName: o.customer.full_name,
            phone: o.customer.phone || null,
        }
        : null,
    actions: {
        canVerify: o.order_status === 'services_completed' && !o.verified_at,
        canDispatch:
            o.order_status === 'services_completed' &&
            !!o.verified_at &&
            !o.dispatched_at &&
            (o.order_type === 'drop_only' || o.order_type === 'both'),
    },
});

exports.listReadyToVerify = async ({ page, limit } = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = {
        order_status: 'services_completed',
        verified_at: null,
    };

    const [total, rows] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { updated_at: 'desc' },
            skip,
            take: safeLimit,
            include: { customer: { select: { customer_id: true, full_name: true, phone: true } } },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        orders: rows.map(mapOrderRow),
    };
};

exports.verifyOrder = async ({ staffId, orderId }) => {
    if (!orderId) throw new ValidationError('orderId is required');
    const now = new Date();

    return prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            select: { order_id: true, order_status: true, verified_at: true },
        });
        if (!order) throw new NotFoundError('Order');
        if (order.order_status !== 'services_completed') {
            throw new ConflictError('Only services_completed orders can be verified');
        }

        // Idempotent verify
        if (order.verified_at) {
            return { orderId, verifiedAt: order.verified_at };
        }

        const updated = await tx.order.update({
            where: { order_id: orderId },
            data: {
                verified_by_distribution_manager_id: staffId,
                verified_at: now,
            },
            select: { order_id: true, verified_at: true },
        });

        return { orderId: updated.order_id, verifiedAt: updated.verified_at };
    });
};

exports.listVerifiedOrders = async ({ page, limit } = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = {
        order_status: 'services_completed',
        verified_at: { not: null },
        dispatched_at: null,
    };

    const [total, rows] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { verified_at: 'desc' },
            skip,
            take: safeLimit,
            include: { customer: { select: { customer_id: true, full_name: true, phone: true } } },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        orders: rows.map(mapOrderRow),
    };
};

exports.dispatchOrder = async ({ staffId, orderId, radiusKm, limit, expiresInSeconds }) => {
    if (!orderId) throw new ValidationError('orderId is required');

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: { order_id: true, order_status: true, order_type: true, verified_at: true, dispatched_at: true },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status !== 'services_completed') throw new ConflictError('Order is not ready for dispatch');
    if (!order.verified_at) throw new ConflictError('Order must be verified by distribution manager before dispatch');
    if (order.dispatched_at) {
        return { orderId, dispatchedAt: order.dispatched_at, alreadyDispatched: true };
    }
    if (!(order.order_type === 'drop_only' || order.order_type === 'both')) {
        throw new ValidationError('Dispatch is only allowed for drop_only or both order types');
    }

    // Create drop delivery assignment request first (transaction in delivery ops)
    const assignment = await deliveryOperationsService.createAssignmentRequest({
        orderId,
        deliveryType: 'drop',
        radiusKm,
        limit,
        expiresInSeconds,
    });

    const now = new Date();
    const updated = await prisma.order.update({
        where: { order_id: orderId },
        data: {
            dispatched_by_distribution_manager_id: staffId,
            dispatched_at: now,
            // This means "dispatch initiated"; delivery staff acceptance may set it again.
            order_status: 'dispatch_assigned',
        },
        select: { order_id: true, dispatched_at: true, order_status: true },
    });

    return {
        orderId: updated.order_id,
        orderStatus: updated.order_status,
        dispatchedAt: updated.dispatched_at,
        assignment,
    };
};

exports.listDispatchHistory = async ({ page, limit } = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = { dispatched_at: { not: null } };

    const [total, rows] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { dispatched_at: 'desc' },
            skip,
            take: safeLimit,
            include: { customer: { select: { customer_id: true, full_name: true, phone: true } } },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        orders: rows.map(mapOrderRow),
    };
};

module.exports = exports;

