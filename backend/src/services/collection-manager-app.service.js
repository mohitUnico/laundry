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

const mapOrderRow = (o) => {
    const pickupDelivery = Array.isArray(o.deliveries) ? o.deliveries[0] : null;
    return {
        orderId: o.order_id,
        orderStatus: o.order_status,
        orderType: o.order_type,
        createdAt: o.created_at,
        pickupDate: o.pickup_date,
        deliveryDate: o.delivery_date,
        pickupAddress: o.pickup_address
            ? {
                addressId: o.pickup_address.address_id,
                fullAddress: o.pickup_address.full_address,
                latitude: (o.pickup_address.latitude?.toString?.() != null) ? o.pickup_address.latitude.toString() : o.pickup_address.latitude,
                longitude: (o.pickup_address.longitude?.toString?.() != null) ? o.pickup_address.longitude.toString() : o.pickup_address.longitude,
            }
            : null,
        customer: o.customer
            ? {
                customerId: o.customer.customer_id,
                fullName: o.customer.full_name,
                phone: o.customer.phone || null,
            }
            : null,
        pickupDelivery: pickupDelivery
            ? {
                deliveryId: pickupDelivery.delivery_id,
                deliveryStatus: pickupDelivery.delivery_status,
                assignedAt: pickupDelivery.assigned_at,
                deliveryStaff: pickupDelivery.staff
                    ? {
                        staffId: pickupDelivery.staff.staff_id,
                        fullName: pickupDelivery.staff.full_name,
                        phone: pickupDelivery.staff.phone || null,
                    }
                    : null,
            }
            : null,
        actions: {
            canAssignPickupDelivery: o.order_type === 'pickup_only' || o.order_type === 'both',
            canMarkReceived:
                o.order_status === 'picked_up' ||
                o.order_status === 'submitted_to_cm' ||
                o.order_status === 'pickup_assigned',
            canSubmitToServices: o.order_status === 'received_by_collection',
        },
    };
};

exports.listIncomingOrders = async ({ page, limit } = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = {
        order_status: { in: ['placed', 'pickup_assigned', 'picked_up', 'submitted_to_cm'] },
    };

    const [total, rows] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { created_at: 'desc' },
            skip,
            take: safeLimit,
            include: {
                customer: { select: { customer_id: true, full_name: true, phone: true } },
                pickup_address: { select: { address_id: true, full_address: true, latitude: true, longitude: true } },
                deliveries: {
                    where: { delivery_type: 'pickup' },
                    orderBy: { created_at: 'desc' },
                    take: 1,
                    include: {
                        staff: { select: { staff_id: true, full_name: true, phone: true } },
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
            pickup_address: {
                select: { address_id: true, full_address: true, latitude: true, longitude: true },
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
            quantity: (item.quantity != null) ? item.quantity : null,
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
        pickupAddress: order.pickup_address
            ? {
                addressId: order.pickup_address.address_id,
                fullAddress: order.pickup_address.full_address,
                latitude: order.pickup_address.latitude?.toString?.() ?? order.pickup_address.latitude,
                longitude: order.pickup_address.longitude?.toString?.() ?? order.pickup_address.longitude,
            }
            : null,
        itemsCount: items.length,
        items,
    };
};

exports.markOrderReceived = async ({ staffId, orderId }) => {
    if (!orderId) throw new ValidationError('orderId is required');

    const now = new Date();

    return prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            select: { order_id: true, order_status: true },
        });
        if (!order) throw new NotFoundError('Order');

        if (!['picked_up', 'submitted_to_cm', 'pickup_assigned'].includes(order.order_status)) {
            throw new ConflictError(`Order cannot be marked received from status ${order.order_status}`);
        }

        const updated = await tx.order.update({
            where: { order_id: orderId },
            data: {
                order_status: 'received_by_collection',
                received_by_collection_manager_id: staffId,
                received_at: now,
            },
            select: { order_id: true, order_status: true, received_at: true },
        });

        return {
            orderId: updated.order_id,
            orderStatus: updated.order_status,
            receivedAt: updated.received_at,
        };
    });
};

exports.createPickupAssignment = async ({ orderId, radiusKm, limit, expiresInSeconds }) => {
    if (!orderId) throw new ValidationError('orderId is required');

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: { order_id: true, order_type: true },
    });
    if (!order) throw new NotFoundError('Order');

    if (!(order.order_type === 'pickup_only' || order.order_type === 'both')) {
        throw new ValidationError('Pickup assignment is only allowed for pickup_only or both order types');
    }

    return deliveryOperationsService.createAssignmentRequest({
        orderId,
        deliveryType: 'pickup',
        radiusKm,
        limit,
        expiresInSeconds,
    });
};

exports.assignPickupDirect = async ({ staffId, orderId, deliveryStaffId }) => {
    if (!orderId) throw new ValidationError('orderId is required');
    if (!deliveryStaffId) throw new ValidationError('deliveryStaffId is required');

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: { order_id: true, order_type: true },
    });
    if (!order) throw new NotFoundError('Order');

    if (!(order.order_type === 'pickup_only' || order.order_type === 'both')) {
        throw new ValidationError('Pickup assignment is only allowed for pickup_only or both order types');
    }

    return deliveryOperationsService.directAssignDelivery({
        orderId,
        deliveryType: 'pickup',
        deliveryStaffId,
        orderUpdateData: {
            // For pickup we only need status; no extra tracking fields exist
            order_status: 'pickup_assigned',
        },
        assignedBy: {
            role: 'collection_manager',
            staffId,
        },
    });
};

exports.listReceivedOrders = async ({ page, limit } = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = { order_status: 'received_by_collection' };

    const [total, rows] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { received_at: 'desc' },
            skip,
            take: safeLimit,
            include: {
                customer: { select: { customer_id: true, full_name: true, phone: true } },
                pickup_address: { select: { address_id: true, full_address: true, latitude: true, longitude: true } },
                deliveries: {
                    where: { delivery_type: 'pickup' },
                    orderBy: { created_at: 'desc' },
                    take: 1,
                    include: {
                        staff: { select: { staff_id: true, full_name: true, phone: true } },
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

exports.submitOrderToServices = async ({ staffId, orderId }) => {
    if (!orderId) throw new ValidationError('orderId is required');
    const now = new Date();

    return prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            include: {
                order_items: {
                    select: {
                        item_id: true,
                        service_id: true,
                        quantity: true,
                        weight_kg: true,
                        item_status: true,
                        service: { select: { service_id: true, service_name: true } },
                    },
                },
            },
        });
        if (!order) throw new NotFoundError('Order');
        if (order.order_status !== 'received_by_collection') {
            throw new ConflictError('Order must be received by collection manager before submitting to services');
        }
        if (!order.order_items || order.order_items.length === 0) {
            throw new ValidationError('Order has no items');
        }

        const serviceIds = Array.from(new Set(order.order_items.map((i) => i.service_id)));
        const serviceMen = await tx.staff.findMany({
            where: { role: 'service_man', service_id: { in: serviceIds } },
            select: { staff_id: true, service_id: true },
        });

        const serviceIdToServiceManId = new Map(serviceMen.map((s) => [s.service_id, s.staff_id]));
        const missing = serviceIds.filter((sid) => !serviceIdToServiceManId.has(sid));
        if (missing.length > 0) {
            throw new ValidationError(`No service man assigned for service(s): ${missing.join(', ')}`);
        }

        // Determine FIFO priority per service
        const maxPriorityByService = new Map();
        await Promise.all(
            serviceIds.map(async (sid) => {
                const agg = await tx.serviceQueueItem.aggregate({
                    where: { service_id: sid },
                    _max: { priority: true },
                });
                maxPriorityByService.set(sid, (agg?._max?.priority != null) ? agg._max.priority : 0);
            })
        );

        const queueRows = order.order_items.map((it) => {
            const sid = it.service_id;
            const nextPriority = ((maxPriorityByService.get(sid) != null) ? maxPriorityByService.get(sid) : 0) + 1;
            maxPriorityByService.set(sid, nextPriority);

            return {
                order_id: orderId,
                service_id: sid,
                service_man_id: serviceIdToServiceManId.get(sid),
                item_id: it.item_id,
                item_name: it.service?.service_name || 'Service',
                quantity: (it.quantity != null) ? it.quantity : null,
                weight_kg: (it.weight_kg != null) ? it.weight_kg : null,
                queue_status: 'pending',
                priority: nextPriority,
                assigned_at: now,
            };
        });

        await tx.serviceQueueItem.createMany({ data: queueRows });

        await tx.orderItem.updateMany({
            where: { order_id: orderId },
            data: { assigned_at: now },
        });

        await tx.order.update({
            where: { order_id: orderId },
            data: {
                order_status: 'submitted_to_services',
                submitted_to_services_at: now,
            },
        });

        return {
            orderId,
            submittedToServicesAt: now,
            serviceQueueItemsCreated: queueRows.length,
            submittedByStaffId: staffId,
        };
    });
};

exports.listSubmissionHistory = async ({ page, limit } = {}) => {
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = { submitted_to_services_at: { not: null } };

    const [total, rows] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { submitted_to_services_at: 'desc' },
            skip,
            take: safeLimit,
            include: {
                customer: { select: { customer_id: true, full_name: true, phone: true } },
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

