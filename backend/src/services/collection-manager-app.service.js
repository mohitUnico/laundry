const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const deliveryOperationsService = require('./delivery-operations.service');
const { notifyOrderStatusChange } = require('./fcm.service');
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
    // For per_kg orders: check if all per_kg items have weights set (collection manager flow)
    let perKgWeightsComplete = true;
    const perKgItems = Array.isArray(o.order_items) ? o.order_items : [];
    if (perKgItems.length > 0) {
        perKgWeightsComplete = perKgItems.every((item) => {
            const w = item.weight_kg;
            if (w == null) return false;
            const n = Number(w);
            return !Number.isNaN(n) && n > 0;
        });
    }
    return {
        orderId: o.order_id,
        orderStatus: o.order_status,
        orderType: o.order_type,
        pricingModel: o.pricing_model,
        perKgWeightsComplete,
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
                order_items: {
                    where: { pricing_type: 'per_kg' },
                    select: { weight_kg: true },
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

    const result = await prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            select: { order_id: true, order_status: true },
        });
        if (!order) throw new NotFoundError('Order');

        // Idempotency: if already received, return without error (prevents UI double-tap issues)
        if (order.order_status === 'received_by_collection') {
            return {
                orderId: order.order_id,
                orderStatus: order.order_status,
                receivedAt: now,
            };
        }

        // Allow marking received from:
        // - pickup flow statuses (picked_up / submitted_to_cm / pickup_assigned)
        // - placed (for drop-only or manual drop scenarios)
        if (!['placed', 'picked_up', 'submitted_to_cm', 'pickup_assigned'].includes(order.order_status)) {
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

    // Push notify after transaction commits (non-blocking)
    notifyOrderStatusChange({ orderId: result.orderId, status: result.orderStatus }).catch(() => {});
    return result;
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

    const result = await prisma.$transaction(async (tx) => {
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

    // Push notify after transaction commits (non-blocking)
    notifyOrderStatusChange({ orderId, status: 'submitted_to_services' }).catch(() => {});
    return result;
};

const coalesce = (v, fallback) => (v != null && v !== '' ? v : fallback);

exports.getPerKgItems = async ({ orderId }) => {
    if (!orderId) throw new ValidationError('orderId is required');

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: {
            order_id: true,
            pricing_model: true,
            total_amount: true,
            updated_at: true,
        },
    });

    if (!order) throw new NotFoundError('Order');

    const perKgItems = await prisma.orderItem.findMany({
        where: { order_id: orderId, pricing_type: 'per_kg' },
        orderBy: { created_at: 'asc' },
        select: {
            item_id: true,
            service_id: true,
            pricing_type: true,
            weight_kg: true,
            unit_price: true,
            subtotal: true,
            updated_at: true,
            service: {
                select: {
                    service_name: true,
                    category: { select: { category_name: true } },
                },
            },
        },
    });

    if (!perKgItems || perKgItems.length === 0) {
        return null;
    }

    return {
        orderId: order.order_id,
        pricingModel: order.pricing_model,
        totalAmount: coalesce(order.total_amount?.toString?.(), String(order.total_amount)),
        orderUpdatedAt: order.updated_at,
        perKgItems: perKgItems.map((x) => ({
            orderItemId: x.item_id,
            serviceId: x.service_id,
            serviceName: x.service?.service_name || null,
            categoryName: x.service?.category?.category_name || null,
            pricingType: x.pricing_type,
            weightKg: x.weight_kg ? coalesce(x.weight_kg.toString?.(), String(x.weight_kg)) : null,
            unitPrice: coalesce(x.unit_price?.toString?.(), String(x.unit_price)),
            subtotal: coalesce(x.subtotal?.toString?.(), String(x.subtotal)),
            updatedAt: x.updated_at,
        })),
    };
};

exports.updatePerKgWeights = async ({ staffId, orderId, items }) => {
    if (!orderId) throw new ValidationError('orderId is required');
    if (!Array.isArray(items) || items.length === 0) {
        throw new ValidationError('items must be a non-empty array');
    }

    for (const it of items) {
        if (!it || typeof it !== 'object') throw new ValidationError('items must be an array of objects');
        if (!it.orderItemId || typeof it.orderItemId !== 'string') throw new ValidationError('orderItemId is required');
        if (typeof it.weightKg !== 'number' || Number.isNaN(it.weightKg)) {
            throw new ValidationError('weightKg must be a number');
        }
    }

    return prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            select: {
                order_id: true,
                order_status: true,
                pricing_model: true,
            },
        });

        if (!order) throw new NotFoundError('Order');
        if (order.pricing_model !== 'per_kg') {
            throw new ConflictError("Order pricing_model must be 'per_kg' to update weights");
        }

        if (!['placed', 'pickup_assigned', 'picked_up', 'submitted_to_cm'].includes(order.order_status)) {
            throw new ConflictError(
                `Cannot update weights: order must be in placed/pickup_assigned/picked_up/submitted_to_cm status (current: ${order.order_status})`
            );
        }

        const perKgItems = await tx.orderItem.findMany({
            where: { order_id: orderId, pricing_type: 'per_kg' },
            select: {
                item_id: true,
                unit_price: true,
                weight_kg: true,
                subtotal: true,
                service_id: true,
            },
        });

        if (perKgItems.length === 0) {
            throw new ConflictError('No per_kg order items found to update');
        }

        const perKgItemIds = new Set(perKgItems.map((i) => i.item_id));
        const requestIds = new Set(items.map((i) => i.orderItemId));

        const missing = [...perKgItemIds].filter((id) => !requestIds.has(id));
        const extra = [...requestIds].filter((id) => !perKgItemIds.has(id));

        if (missing.length) {
            throw new ValidationError(`Missing weight updates for per_kg order items: ${missing.join(', ')}`);
        }
        if (extra.length) {
            throw new ValidationError(`Provided orderItemId(s) are not per_kg items of this order: ${extra.join(', ')}`);
        }

        const weightById = new Map(items.map((i) => [i.orderItemId, i.weightKg]));

        for (const oi of perKgItems) {
            const weightKg = weightById.get(oi.item_id);
            const newSubtotal = oi.unit_price.mul(weightKg);

            await tx.orderItem.update({
                where: { item_id: oi.item_id },
                data: {
                    weight_kg: weightKg,
                    subtotal: newSubtotal,
                },
            });
        }

        const agg = await tx.orderItem.aggregate({
            where: { order_id: orderId },
            _sum: { subtotal: true },
        });

        const newTotal = agg._sum.subtotal || 0;

        await tx.order.update({
            where: { order_id: orderId },
            data: { total_amount: newTotal },
        });

        return {
            orderId,
            message: 'Weights updated successfully',
        };
    });
};

exports.generateInvoice = async ({ staffId, orderId }) => {
    if (!orderId) throw new ValidationError('orderId is required');

    const now = new Date();

    return prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            select: {
                order_id: true,
                order_status: true,
                billing_status: true,
                customer_id: true,
                pricing_model: true,
                total_amount: true,
                bill: { select: { bill_id: true, payment_status: true, payment_method: true } },
                order_items: {
                    select: {
                        item_id: true,
                        service_id: true,
                        pricing_type: true,
                        quantity: true,
                        weight_kg: true,
                        unit_price: true,
                        subtotal: true,
                        service: {
                            select: {
                                service_id: true,
                                service_name: true,
                                per_kg_price: true,
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
        // Invoice should only be generated after the collection manager has
        // verified and received the order at the collection centre.
        // At this point all per-kg weights should be recorded.
        if (order.order_status !== 'received_by_collection') {
            throw new ConflictError('Invoice can only be generated after order is received by collection manager (received_by_collection)');
        }
        if (!order.order_items || order.order_items.length === 0) {
            throw new ValidationError('Order has no items');
        }
        // NOTE:
        // Even if payment is already completed (per-piece orders can be paid before CM generates invoice),
        // we still allow invoice generation and preserve bill.payment_status as completed.

        // Recompute item subtotals for BOTH per_unit and per_kg items.
        // This is required because when pricing_model is per_kg (mixed orders),
        // order creation intentionally stores 0 totals until billing is generated.
        for (const it of order.order_items) {
            if (it.pricing_type === 'per_unit') {
                const selections = Array.isArray(it.item_selections) ? it.item_selections : [];
                if (selections.length === 0) {
                    throw new ValidationError('Missing per-piece selections for one or more items');
                }

                let qty = 0;
                let subtotal = new Prisma.Decimal(0);

                for (const sel of selections) {
                    const q = sel.quantity;
                    const price = sel.cloth_item?.per_unit_price;
                    if (q == null || q <= 0) continue;
                    if (price == null) {
                        throw new ValidationError('Missing per_unit_price for one or more cloth items');
                    }
                    qty += q;
                    subtotal = subtotal.plus(new Prisma.Decimal(price).mul(q));
                }

                await tx.orderItem.update({
                    where: { item_id: it.item_id },
                    data: {
                        quantity: qty,
                        subtotal,
                        // keep unit_price as-is (already required); subtotal is authoritative for billing
                    },
                });
            } else if (it.pricing_type === 'per_kg') {
                const weight = it.weight_kg;
                if (weight == null || Number(weight) <= 0) {
                    throw new ValidationError('Weight (kg) is required for all kg-wise items before generating invoice');
                }

                const unitPrice = it.unit_price || it.service?.per_kg_price;
                if (unitPrice == null || Number(unitPrice) <= 0) {
                    throw new ValidationError('per_kg_price is missing for one or more services');
                }

                const subtotal = new Prisma.Decimal(unitPrice).mul(new Prisma.Decimal(weight));

                await tx.orderItem.update({
                    where: { item_id: it.item_id },
                    data: {
                        unit_price: new Prisma.Decimal(unitPrice),
                        subtotal,
                    },
                });
            }
        }

        const agg = await tx.orderItem.aggregate({
            where: { order_id: orderId },
            _sum: { subtotal: true },
        });

        const newSubtotal = agg._sum.subtotal || new Prisma.Decimal(0);

        await tx.order.update({
            where: { order_id: orderId },
            data: {
                total_amount: newSubtotal,
                billing_status: 'generated',
            },
        });

        // Create or update bill totals. Keep delivery/tax/discount as 0 for now.
        const existingPaymentStatus = order.bill?.payment_status;
        const normalizedPaymentStatus = existingPaymentStatus === 'completed' ? 'completed' : 'pending';
        const billData = {
            subtotal: newSubtotal,
            delivery_fee: new Prisma.Decimal(0),
            tax_amount: new Prisma.Decimal(0),
            discount: new Prisma.Decimal(0),
            final_amount: newSubtotal,
            payment_method: (order.bill?.payment_method && order.bill.payment_method.length > 0)
                ? order.bill.payment_method
                : 'pending',
            payment_status: normalizedPaymentStatus,
        };

        const bill = await tx.bill.upsert({
            where: { order_id: orderId },
            create: {
                order_id: orderId,
                ...billData,
            },
            update: billData,
            select: {
                bill_id: true,
                order_id: true,
                subtotal: true,
                delivery_fee: true,
                tax_amount: true,
                discount: true,
                final_amount: true,
                payment_method: true,
                payment_status: true,
                created_at: true,
                updated_at: true,
            },
        });

        // Return invoice summary (details can be fetched by customer via /payments/invoice/:orderId)
        return {
            orderId,
            billingStatus: 'generated',
            subtotal: bill.subtotal.toString(),
            deliveryFee: bill.delivery_fee.toString(),
            taxAmount: bill.tax_amount.toString(),
            discount: bill.discount.toString(),
            finalAmount: bill.final_amount.toString(),
            generatedAt: now,
            generatedByStaffId: staffId,
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

