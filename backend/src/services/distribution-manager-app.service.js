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
    dispatchedBy: o.dispatched_by_manager
        ? {
            staffId: o.dispatched_by_manager.staff_id,
            fullName: o.dispatched_by_manager.full_name,
        }
        : null,
    dropDelivery:
        Array.isArray(o.deliveries) && o.deliveries.length
            ? {
                deliveryId: o.deliveries[0].delivery_id,
                deliveryStatus: o.deliveries[0].delivery_status,
                deliveryStaff: o.deliveries[0].staff
                    ? {
                        staffId: o.deliveries[0].staff.staff_id,
                        fullName: o.deliveries[0].staff.full_name,
                    }
                    : null,
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

exports.getOrderItems = async ({ orderId }) => {
    if (!orderId) throw new ValidationError('orderId is required');

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: {
            order_id: true,
            pricing_model: true,
            order_type: true,
            order_status: true,
            created_at: true,
            delivery_address: {
                select: {
                    address_id: true,
                    address_line1: true,
                    address_line2: true,
                    city: true,
                    state: true,
                    pincode: true,
                    latitude: true,
                    longitude: true,
                    label: true,
                },
            },
            order_items: {
                select: {
                    item_id: true,
                    pricing_type: true,
                    quantity: true,
                    weight_kg: true,
                    service: {
                        select: {
                            service_id: true,
                            service_name: true,
                            category: { select: { category_id: true, category_name: true } },
                        },
                    },
                    item_selections: {
                        select: {
                            selection_id: true,
                            quantity: true,
                            cloth_item: {
                                select: {
                                    cloth_id: true,
                                    item_name: true,
                                    per_unit_price: true,
                                },
                            },
                        },
                    },
                },
            },
        },
    });

    if (!order) throw new NotFoundError('Order');

    const items = (order.order_items || []).map((item) => {
        const serviceName = item.service?.service_name || '';
        const categoryName = item.service?.category?.category_name || '';

        const selections = (item.item_selections || [])
            .map((sel) => ({
                selectionId: sel.selection_id,
                quantity: sel.quantity,
                clothId: sel.cloth_item?.cloth_id || null,
                clothName: sel.cloth_item?.item_name || '',
                perUnitPrice: sel.cloth_item?.per_unit_price ? sel.cloth_item.per_unit_price.toString() : null,
            }))
            .filter((s) => s.quantity != null && (s.quantity > 0));

        return {
            itemId: item.item_id,
            pricingType: item.pricing_type,
            quantity: item.quantity ?? null,
            weightKg: item.weight_kg != null ? item.weight_kg.toString() : null,
            serviceName,
            categoryName,
            selections,
        };
    });

    return {
        orderId: order.order_id,
        orderStatus: order.order_status,
        orderType: order.order_type,
        pricingModel: order.pricing_model,
        createdAt: order.created_at,
        deliveryAddress: order.delivery_address
            ? {
                  addressId: order.delivery_address.address_id,
                  addressLine1: order.delivery_address.address_line1,
                  addressLine2: order.delivery_address.address_line2,
                  city: order.delivery_address.city,
                  state: order.delivery_address.state,
                  pincode: order.delivery_address.pincode,
                  latitude: order.delivery_address.latitude ? order.delivery_address.latitude.toString() : null,
                  longitude: order.delivery_address.longitude ? order.delivery_address.longitude.toString() : null,
                  label: order.delivery_address.label,
              }
            : null,
        itemsCount: items.length,
        items,
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

exports.assignDropDirect = async ({ staffId, orderId, deliveryStaffId }) => {
    if (!orderId) throw new ValidationError('orderId is required');
    if (!deliveryStaffId) throw new ValidationError('deliveryStaffId is required');

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: { order_id: true, order_status: true, order_type: true, verified_at: true, dispatched_at: true },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status !== 'services_completed') throw new ConflictError('Order is not ready for delivery assignment');
    if (!order.verified_at) throw new ConflictError('Order must be verified by distribution manager before delivery assignment');
    if (order.dispatched_at) throw new ConflictError('Order is already dispatched');
    if (!(order.order_type === 'drop_only' || order.order_type === 'both')) {
        throw new ValidationError('Delivery assignment is only allowed for drop_only or both order types');
    }

    // Mark dispatch metadata + assign delivery in one atomic transaction inside delivery ops service
    return deliveryOperationsService.directAssignDelivery({
        orderId,
        deliveryType: 'drop',
        deliveryStaffId,
        orderUpdateData: {
            dispatched_by_distribution_manager_id: staffId,
            order_status: 'dispatch_assigned',
        },
        assignedBy: {
            role: 'distribution_manager',
            staffId,
        },
    });
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
            include: {
                customer: { select: { customer_id: true, full_name: true, phone: true } },
                dispatched_by_manager: { select: { staff_id: true, full_name: true } },
                deliveries: {
                    where: { delivery_type: 'drop' },
                    orderBy: { created_at: 'desc' },
                    take: 1,
                    select: {
                        delivery_id: true,
                        delivery_status: true,
                        staff: { select: { staff_id: true, full_name: true } },
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
        orders: rows.map(mapOrderRow),
    };
};

module.exports = exports;

