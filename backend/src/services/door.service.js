const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const configService = require('./config.service');
const { uploadBuffer } = require('./cloudinary-upload.service');
const { assertTransition, ORDER_STATUS } = require('../constants/order-flow');
const { ConflictError, ForbiddenError, NotFoundError, ValidationError } = require('../utils/errors');
const { emitOrderEvent } = require('./notification-events');

const MAX_WEIGHT_KG = 500;

function money(value) {
    return new Prisma.Decimal(value == null ? 0 : value);
}

function itemGaps(item) {
    const missing = [];
    if (!item.photo_url) missing.push('photo');
    if (item.pricing_type === 'per_kg') {
        const weight = item.weight_kg == null ? 0 : Number(item.weight_kg);
        if (!(weight > 0)) missing.push('weight_kg');
    } else {
        const hasLine = (item.item_selections || []).some((row) => row.quantity >= 1);
        if (!hasLine) missing.push('selections');
    }
    return missing;
}

function primaryAction(order, items) {
    if (order.order_status === ORDER_STATUS.PICKUP_ASSIGNED) {
        const ready = items.length > 0 && items.every((item) => itemGaps(item).length === 0);
        return { key: 'MARK_PICKED_UP', enabled: ready && !order.items_confirmed_at };
    }
    if (order.order_status === ORDER_STATUS.PICKED_UP) {
        return { key: 'SUBMIT_TO_CM', enabled: true };
    }
    if (order.order_status === ORDER_STATUS.SUBMITTED_TO_CM) {
        return { key: 'WAITING_FOR_CM', enabled: false };
    }
    return { key: 'NONE', enabled: false };
}

const doorInclude = {
    order_items: {
        orderBy: { created_at: 'asc' },
        include: {
            service: {
                include: {
                    clothes_items: {
                        where: { is_active: true },
                        orderBy: [{ display_order: 'asc' }, { item_name: 'asc' }],
                    },
                },
            },
            item_selections: true,
        },
    },
    bill: true,
};

async function loadOwnedPickup(staffId, orderId) {
    const delivery = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: 'pickup', staff_id: staffId },
        include: { order: { include: doorInclude } },
    });
    if (!delivery || !delivery.order) {
        throw new ForbiddenError('Only the assigned pickup partner can access this door');
    }
    return delivery;
}

function presentDoor(delivery) {
    const order = delivery.order;
    const services = order.order_items.map((item) => {
        const missing = itemGaps(item);
        return {
            orderItemId: item.item_id,
            serviceId: item.service_id,
            serviceName: item.service?.service_name || null,
            pricingType: item.pricing_type,
            weightKg: item.weight_kg == null ? null : String(item.weight_kg),
            photoUrl: item.photo_url,
            selections: (item.item_selections || []).map((row) => ({
                clothId: row.cloth_id,
                quantity: row.quantity,
                unitPrice: row.unit_price == null ? null : String(row.unit_price),
            })),
            catalogue:
                item.pricing_type === 'per_unit'
                    ? (item.service?.clothes_items || []).map((cloth) => ({
                          clothId: cloth.cloth_id,
                          itemName: cloth.item_name,
                          perUnitPrice: String(cloth.per_unit_price),
                      }))
                    : [],
            isComplete: missing.length === 0,
            missing,
        };
    });
    return {
        orderId: order.order_id,
        orderStatus: order.order_status,
        itemsConfirmed: Boolean(order.items_confirmed_at),
        canMarkPickedUp: primaryAction(order, order.order_items).key === 'MARK_PICKED_UP'
            && primaryAction(order, order.order_items).enabled,
        primaryAction: primaryAction(order, order.order_items),
        services,
        bill: order.bill
            ? {
                  billId: order.bill.bill_id,
                  finalAmount: String(order.bill.final_amount),
                  paymentStatus: order.bill.payment_status,
              }
            : null,
    };
}

async function getDoor({ staffId, orderId }) {
    const delivery = await loadOwnedPickup(staffId, orderId);
    return presentDoor(delivery);
}

async function saveDraft({ staffId, orderId, orderItemId, body }) {
    const delivery = await loadOwnedPickup(staffId, orderId);
    const order = delivery.order;
    if (order.order_status !== ORDER_STATUS.PICKUP_ASSIGNED || order.items_confirmed_at) {
        throw new ConflictError('Door edits are closed after pickup is confirmed', 'DOOR_LOCKED');
    }
    const item = order.order_items.find((row) => row.item_id === orderItemId);
    if (!item) throw new NotFoundError('Order item');

    if (body.photo_url !== undefined) {
        if (body.photo_url != null && typeof body.photo_url !== 'string') {
            throw new ValidationError('photo_url must be a string');
        }
    }

    if (item.pricing_type === 'per_kg') {
        if (body.selections) throw new ValidationError('per-kg services take weight_kg, not selections');
        if (body.weight_kg !== undefined) {
            const weight = Number(body.weight_kg);
            if (!Number.isFinite(weight) || weight <= 0 || weight > MAX_WEIGHT_KG) {
                throw new ValidationError(`weight_kg must be greater than 0 and at most ${MAX_WEIGHT_KG}`);
            }
            await prisma.orderItem.update({
                where: { item_id: item.item_id },
                data: {
                    weight_kg: new Prisma.Decimal(weight.toFixed(2)),
                    ...(body.photo_url !== undefined && { photo_url: body.photo_url || null }),
                },
            });
        } else if (body.photo_url !== undefined) {
            await prisma.orderItem.update({
                where: { item_id: item.item_id },
                data: { photo_url: body.photo_url || null },
            });
        }
    } else {
        if (body.weight_kg !== undefined) throw new ValidationError('per-unit services take selections, not weight_kg');
        if (body.selections) {
            if (!Array.isArray(body.selections)) throw new ValidationError('selections must be an array');
            const cloths = await prisma.clothesItem.findMany({
                where: { service_id: item.service_id, is_active: true },
            });
            const byId = new Map(cloths.map((cloth) => [cloth.cloth_id, cloth]));
            const rows = [];
            for (const line of body.selections) {
                const quantity = Number(line.quantity);
                if (!Number.isInteger(quantity) || quantity < 0) {
                    throw new ValidationError('quantity must be an integer >= 0');
                }
                if (quantity === 0) continue;
                const cloth = byId.get(line.cloth_id);
                if (!cloth) throw new ValidationError('cloth does not belong to this service or is inactive');
                rows.push({ cloth_id: cloth.cloth_id, quantity });
            }
            await prisma.$transaction(async (tx) => {
                await tx.orderItemSelection.deleteMany({ where: { order_item_id: item.item_id } });
                if (rows.length) {
                    await tx.orderItemSelection.createMany({
                        data: rows.map((row) => ({
                            order_item_id: item.item_id,
                            cloth_id: row.cloth_id,
                            quantity: row.quantity,
                        })),
                    });
                }
                const quantitySum = rows.reduce((sum, row) => sum + row.quantity, 0);
                await tx.orderItem.update({
                    where: { item_id: item.item_id },
                    data: {
                        quantity: quantitySum || null,
                        ...(body.photo_url !== undefined && { photo_url: body.photo_url || null }),
                    },
                });
            });
        } else if (body.photo_url !== undefined) {
            await prisma.orderItem.update({
                where: { item_id: item.item_id },
                data: { photo_url: body.photo_url || null },
            });
        }
    }

    return getDoor({ staffId, orderId });
}

async function savePhoto({ staffId, orderId, orderItemId, file }) {
    if (!file || !file.buffer) throw new ValidationError('A photo file is required');
    const delivery = await loadOwnedPickup(staffId, orderId);
    if (delivery.order.order_status !== ORDER_STATUS.PICKUP_ASSIGNED || delivery.order.items_confirmed_at) {
        throw new ConflictError('Door edits are closed after pickup is confirmed', 'DOOR_LOCKED');
    }
    const item = delivery.order.order_items.find((row) => row.item_id === orderItemId);
    if (!item) throw new NotFoundError('Order item');
    const photoUrl = await uploadBuffer({
        buffer: file.buffer,
        folder: `orders/${orderId}/door`,
        mimetype: file.mimetype || 'image/jpeg',
    });
    await prisma.orderItem.update({
        where: { item_id: item.item_id },
        data: { photo_url: photoUrl },
    });
    return { orderItemId, photoUrl };
}

function presentBill(order) {
    const bill = order.bill;
    const lines = (order.order_items || []).map((item) => {
        if (item.pricing_type === 'per_kg') {
            return {
                orderItemId: item.item_id,
                serviceId: item.service_id,
                serviceName: item.service?.service_name || null,
                pricingType: 'per_kg',
                weightKg: item.weight_kg == null ? null : String(item.weight_kg),
                unitPrice: item.unit_price == null ? null : String(item.unit_price),
                subtotal: String(item.subtotal),
            };
        }
        return {
            orderItemId: item.item_id,
            serviceId: item.service_id,
            serviceName: item.service?.service_name || null,
            pricingType: 'per_unit',
            subtotal: String(item.subtotal),
            selections: (item.item_selections || []).map((row) => ({
                clothId: row.cloth_id,
                name: row.cloth_item?.item_name || null,
                quantity: row.quantity,
                unitPrice: row.unit_price == null ? null : String(row.unit_price),
                lineTotal:
                    row.unit_price == null
                        ? null
                        : String(money(row.unit_price).mul(row.quantity)),
            })),
        };
    });
    return {
        orderId: order.order_id,
        lines,
        bill: bill
            ? {
                  billId: bill.bill_id,
                  subtotal: String(bill.subtotal),
                  deliveryFee: String(bill.delivery_fee),
                  expressFee: String(bill.express_fee || 0),
                  discount: String(bill.discount),
                  taxAmount: String(bill.tax_amount),
                  finalAmount: String(bill.final_amount),
                  couponCode: bill.coupon_code,
                  paymentStatus: bill.payment_status,
                  paymentMethod: bill.payment_method,
                  canPay: false,
              }
            : null,
        canPay: false,
    };
}

async function confirmDoor({ staffId, orderId }) {
    const delivery = await loadOwnedPickup(staffId, orderId);
    const result = await prisma.$transaction(async (tx) => {
        const locked = await tx.$queryRaw`
            SELECT order_status::text AS order_status, items_confirmed_at
            FROM orders
            WHERE order_id = ${orderId}::uuid
            FOR UPDATE
        `;
        const row = locked[0];
        if (!row) throw new NotFoundError('Order');
        if (row.items_confirmed_at) {
            const existing = await tx.order.findUnique({
                where: { order_id: orderId },
                include: {
                    bill: true,
                    order_items: { include: { service: true, item_selections: { include: { cloth_item: true } } } },
                },
            });
            return { order: existing, created: false };
        }
        if (row.order_status !== ORDER_STATUS.PICKUP_ASSIGNED) {
            throw new ConflictError('Pickup can be confirmed only while the order is pickup_assigned', 'DOOR_LOCKED');
        }
        assertTransition(row.order_status, ORDER_STATUS.PICKED_UP);

        const items = await tx.orderItem.findMany({
            where: { order_id: orderId },
            include: { service: true, item_selections: { include: { cloth_item: true } } },
        });
        const incomplete = items
            .map((item) => ({ item, missing: itemGaps(item) }))
            .filter((entry) => entry.missing.length > 0);
        if (incomplete.length) {
            const err = new ConflictError('Every service needs a count and a photo before pickup', 'DOOR_INCOMPLETE');
            err.details = {
                services: incomplete.map((entry) => ({
                    orderItemId: entry.item.item_id,
                    serviceId: entry.item.service_id,
                    serviceName: entry.item.service?.service_name || null,
                    missing: entry.missing,
                })),
            };
            throw err;
        }

        let subtotal = new Prisma.Decimal(0);
        for (const item of items) {
            if (item.pricing_type === 'per_kg') {
                const unit = money(item.service.per_kg_price);
                const line = unit.mul(money(item.weight_kg));
                subtotal = subtotal.add(line);
                await tx.orderItem.update({
                    where: { item_id: item.item_id },
                    data: { unit_price: unit, subtotal: line },
                });
            } else {
                let line = new Prisma.Decimal(0);
                for (const selection of item.item_selections) {
                    const unit = money(selection.cloth_item.per_unit_price);
                    line = line.add(unit.mul(selection.quantity));
                    await tx.orderItemSelection.update({
                        where: { selection_id: selection.selection_id },
                        data: { unit_price: unit },
                    });
                }
                subtotal = subtotal.add(line);
                await tx.orderItem.update({
                    where: { item_id: item.item_id },
                    data: { unit_price: null, subtotal: line },
                });
            }
        }

        const deliveryFee = money(await configService.getNumber('DELIVERY_FEE'));
        const expressFee = delivery.order.is_express
            ? money(await configService.getNumber('EXPRESS_FEE'))
            : new Prisma.Decimal(0);
        const finalAmount = subtotal.add(deliveryFee).add(expressFee);
        const now = new Date();

        const bill = await tx.bill.create({
            data: {
                order_id: orderId,
                subtotal,
                delivery_fee: deliveryFee,
                express_fee: expressFee,
                tax_amount: new Prisma.Decimal(0),
                discount: new Prisma.Decimal(0),
                final_amount: finalAmount,
                payment_method: null,
                payment_status: 'pending',
            },
        });

        await tx.order.update({
            where: { order_id: orderId },
            data: {
                order_status: ORDER_STATUS.PICKED_UP,
                items_confirmed_at: now,
                total_amount: finalAmount,
            },
        });
        await tx.pickupForDelivery.update({
            where: { delivery_id: delivery.delivery_id },
            data: { pickup_status: 'picked_up', pickup_time: now },
        });
        await tx.delivery.update({
            where: { delivery_id: delivery.delivery_id },
            data: { delivery_status: 'in_progress' },
        });

        const order = await tx.order.findUnique({
            where: { order_id: orderId },
            include: {
                bill: true,
                order_items: { include: { service: true, item_selections: { include: { cloth_item: true } } } },
            },
        });
        return { order, created: true, billId: bill.bill_id };
    });

    if (result.created) {
        emitOrderEvent('picked_up', { orderId }).catch(() => {});
        emitOrderEvent('bill_ready', { orderId }).catch(() => {});
    }
    const view = presentBill(result.order);
    view.canPay = false;
    if (view.bill) view.bill.canPay = false;
    return view;
}

async function getCustomerBill(customerId, orderId) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
        include: {
            bill: true,
            order_items: { include: { service: true, item_selections: { include: { cloth_item: true } } } },
        },
    });
    if (!order) throw new NotFoundError('Order');
    const view = presentBill(order);
    const payable =
        order.bill &&
        order.bill.payment_status === 'pending' &&
        ['picked_up', 'submitted_to_cm', 'received_by_collection', 'submitted_to_services', 'services_in_progress', 'services_completed', 'out_for_delivery'].includes(
            order.order_status
        );
    view.canPay = Boolean(payable);
    if (view.bill) view.bill.canPay = Boolean(payable);
    return view;
}

module.exports = {
    getDoor,
    saveDraft,
    savePhoto,
    confirmDoor,
    getCustomerBill,
    primaryAction,
    itemGaps,
};
