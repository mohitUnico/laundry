const prisma = require('../config/database');
const configService = require('./config.service');
const { ConflictError, NotFoundError, ValidationError } = require('../utils/errors');
const { ORDER_STATUS } = require('../constants/order-flow');
const { flagsFor } = require('./order-tracker');
const { inspectService } = require('./catalogue-rules');

const HISTORY = [ORDER_STATUS.DELIVERED, ORDER_STATUS.CANCELLED];
const ACTIVE_EXCLUDED = [ORDER_STATUS.DELIVERED, ORDER_STATUS.CANCELLED];
const UPCOMING = new Set([ORDER_STATUS.PLACED, ORDER_STATUS.PICKUP_ASSIGNED]);

function cardType(status) {
    if (UPCOMING.has(status)) return 'upcoming_pickup';
    if (status === ORDER_STATUS.DELIVERED) return 'delivered';
    if (status === ORDER_STATUS.CANCELLED) return null;
    return 'in_progress';
}

function orderTitle(items) {
    const names = [
        ...new Set((items || []).map((item) => item.service?.service_name).filter(Boolean)),
    ];
    if (names.length === 0) return 'Laundry pickup';
    if (names.length > 1) return 'Mixed';
    return names[0];
}

function totalWeightKg(items) {
    const rows = (items || []).filter((item) => item.pricing_type === 'per_kg' && item.weight_kg != null);
    if (!rows.length) return null;
    const sum = rows.reduce((total, item) => total + Number(item.weight_kg), 0);
    if (!Number.isFinite(sum) || sum <= 0) return null;
    return sum.toFixed(2);
}

function captainBlock(delivery) {
    if (!delivery?.staff) return null;
    const staff = delivery.staff;
    return {
        staffId: staff.staff_id,
        name: staff.full_name,
        phone: staff.phone,
        photoUrl: staff.profile_image_url,
        latitude: staff.current_latitude == null ? null : String(staff.current_latitude),
        longitude: staff.current_longitude == null ? null : String(staff.current_longitude),
    };
}

function moneyStr(value) {
    if (value == null || value === '') return null;
    const num = Number(value);
    if (!Number.isFinite(num)) return null;
    return num.toFixed(2);
}

function billContract(bill) {
    if (!bill) return { generated: false };
    return {
        generated: true,
        bill_id: bill.bill_id,
        subtotal: moneyStr(bill.subtotal),
        delivery_fee: moneyStr(bill.delivery_fee),
        express_fee: moneyStr(bill.express_fee),
        tax_amount: moneyStr(bill.tax_amount),
        discount: moneyStr(bill.discount),
        final_amount: moneyStr(bill.final_amount),
        payment_status: bill.payment_status,
        payment_method: bill.payment_method ?? null,
        coupon_code: bill.coupon_code ?? null,
        paid_at: bill.paid_at,
    };
}

function addressSummary(address) {
    if (!address) return null;
    return {
        address_id: address.address_id,
        address_label: address.address_label,
        full_address: address.full_address,
    };
}

function itemCount(items) {
    const perUnit = (items || []).filter((item) => item.pricing_type === 'per_unit');
    if (!perUnit.length) return null;
    const fromLines = perUnit.map((item) => item.quantity).filter((qty) => qty != null);
    if (fromLines.length) return fromLines.reduce((sum, qty) => sum + qty, 0);
    const fromSelections = perUnit.flatMap((item) => item.item_selections || []).map((row) => row.quantity);
    if (!fromSelections.length) return null;
    return fromSelections.reduce((sum, qty) => sum + qty, 0);
}

function detailItem(item, billed) {
    const perKg = item.pricing_type === 'per_kg';
    const linePrice = billed ? item.unit_price : perKg ? item.service?.per_kg_price : null;
    return {
        item_id: item.item_id,
        category_id: item.service?.category_id || null,
        category_name: item.service?.category?.category_name || null,
        service_id: item.service_id,
        service_name: item.service?.service_name || null,
        pricing_type: item.pricing_type,
        per_kg_price: perKg ? moneyStr(linePrice) : null,
        unit_price: perKg ? null : moneyStr(linePrice),
        weight_kg: perKg ? moneyStr(item.weight_kg) : null,
        quantity: perKg ? null : item.quantity ?? null,
        subtotal: billed ? moneyStr(item.subtotal) : null,
        selections: perKg
            ? []
            : (item.item_selections || []).map((row) => ({
                  cloth_id: row.cloth_id,
                  item_name: row.cloth_item?.item_name || null,
                  quantity: row.quantity,
                  unit_price: moneyStr(billed ? row.unit_price : row.cloth_item?.per_unit_price),
              })),
    };
}

function contractFlags(order) {
    const placed = order.order_status === ORDER_STATUS.PLACED;
    return {
        can_cancel: placed,
        can_reschedule: placed,
        can_change_address: placed,
    };
}

const ORDER_ITEM_INCLUDE = {
    service: { include: { category: true } },
    item_selections: { include: { cloth_item: true } },
};

function statusFilter({ bucket, status }) {
    if (status === 'all') return { notIn: [ORDER_STATUS.CANCELLED] };
    if (status === 'completed') return ORDER_STATUS.DELIVERED;
    if (status === 'active') return { notIn: ACTIVE_EXCLUDED };
    if (status != null && status !== '') {
        throw new ValidationError('status must be all, active or completed');
    }
    if (bucket == null || bucket === '' || bucket === 'active') return { notIn: ACTIVE_EXCLUDED };
    if (bucket === 'history') return { in: HISTORY };
    throw new ValidationError('bucket must be active or history');
}

function summaryRow(order) {
    const flags = contractFlags(order);
    const billed = Boolean(order.bill);
    return {
        order_id: order.order_id,
        orderId: order.order_id,
        order_status: order.order_status,
        orderStatus: order.order_status,
        card_type: cardType(order.order_status),
        title: orderTitle(order.order_items),
        is_express: order.is_express,
        created_at: order.created_at,
        createdAt: order.created_at,
        pickup_mode: order.pickup_mode,
        delivery_mode: order.delivery_mode,
        pickup_time_from: order.pickup_time_from,
        pickup_time_to: order.pickup_time_to,
        delivery_time_from: order.delivery_time_from,
        delivery_time_to: order.delivery_time_to,
        pickup_address: addressSummary(order.pickup_address),
        services: order.order_items.map((item) => ({
            service_id: item.service_id,
            service_name: item.service?.service_name || null,
            pricing_type: item.pricing_type,
        })),
        items: order.order_items.map((item) => detailItem(item, billed)),
        item_count: itemCount(order.order_items),
        total_weight_kg: totalWeightKg(order.order_items),
        can_cancel: flags.can_cancel,
        can_reschedule: flags.can_reschedule,
        bill: billContract(order.bill),
        total_amount: order.bill ? moneyStr(order.bill.final_amount) : moneyStr(order.total_amount),
        totalAmount: order.bill ? moneyStr(order.bill.final_amount) : moneyStr(order.total_amount),
        ...flagsFor(order, order.bill),
    };
}

async function listOrders({ customerId, bucket, status, page = 1, limit = 20 }) {
    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.min(100, Math.max(1, Number(limit) || 20));
    const where = {
        customer_id: customerId,
        order_status: statusFilter({ bucket, status }),
    };
    const [rows, total] = await Promise.all([
        prisma.order.findMany({
            where,
            include: {
                bill: true,
                pickup_address: true,
                order_items: { include: ORDER_ITEM_INCLUDE },
            },
            orderBy: { created_at: 'desc' },
            skip: (safePage - 1) * safeLimit,
            take: safeLimit,
        }),
        prisma.order.count({ where }),
    ]);
    return {
        orders: rows.map(summaryRow),
        pagination: { page: safePage, limit: safeLimit, total },
    };
}

async function getOrderDetail({ customerId, orderId }) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
        include: {
            bill: true,
            pickup_address: true,
            delivery_address: true,
            order_items: { include: ORDER_ITEM_INCLUDE },
        },
    });
    if (!order) throw new NotFoundError('Order');
    const billed = Boolean(order.bill);
    const flags = contractFlags(order);
    return {
        order_id: order.order_id,
        orderId: order.order_id,
        order_status: order.order_status,
        orderStatus: order.order_status,
        is_express: order.is_express,
        card_type: cardType(order.order_status),
        title: orderTitle(order.order_items),
        created_at: order.created_at,
        pickup_mode: order.pickup_mode,
        delivery_mode: order.delivery_mode,
        pickup_time_from: order.pickup_time_from,
        pickup_time_to: order.pickup_time_to,
        delivery_time_from: order.delivery_time_from,
        delivery_time_to: order.delivery_time_to,
        special_instructions: order.special_instructions,
        can_cancel: flags.can_cancel,
        can_reschedule: flags.can_reschedule,
        can_change_address: flags.can_change_address,
        item_count: itemCount(order.order_items),
        total_weight_kg: totalWeightKg(order.order_items),
        pickup_address: addressSummary(order.pickup_address),
        delivery_address: addressSummary(order.delivery_address),
        services: order.order_items.map((item) => ({
            service_id: item.service_id,
            service_name: item.service?.service_name || null,
            pricing_type: item.pricing_type,
        })),
        items: order.order_items.map((item) => detailItem(item, billed)),
        bill: billContract(order.bill),
    };
}

function trackingPoint(address, lat, lng) {
    return {
        address: address || null,
        latitude: lat == null ? null : Number(lat),
        longitude: lng == null ? null : Number(lng),
    };
}

function trackingStaff(staff) {
    if (!staff) return null;
    return {
        staffId: staff.staff_id,
        fullName: staff.full_name,
        latitude: staff.current_latitude == null ? null : Number(staff.current_latitude),
        longitude: staff.current_longitude == null ? null : Number(staff.current_longitude),
    };
}

function trackingLeg(delivery) {
    if (!delivery) return null;
    return {
        deliveryId: delivery.delivery_id,
        deliveryType: delivery.delivery_type,
        deliveryStatus: delivery.delivery_status,
        staffId: delivery.staff_id,
        staff: trackingStaff(delivery.staff),
    };
}

async function getTracking({ customerId, orderId }) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
        include: {
            deliveries: { include: { staff: true } },
            pickup_address: true,
            delivery_address: true,
        },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status === ORDER_STATUS.CANCELLED) {
        const err = new ConflictError('This order was cancelled', 'ORDER_CANCELLED');
        throw err;
    }
    const laundry = await prisma.laundryConfig.findFirst({ where: { is_active: true } });
    const pickupLeg = order.deliveries.find((row) => row.delivery_type === 'pickup') || null;
    const dropLeg = order.deliveries.find((row) => row.delivery_type === 'drop') || null;
    const active = [ORDER_STATUS.OUT_FOR_DELIVERY, ORDER_STATUS.DELIVERED, ORDER_STATUS.SERVICES_COMPLETED].includes(order.order_status)
        ? dropLeg
        : pickupLeg;
    const refresh = await configService.getInt('DIRECTIONS_REFRESH_SECONDS');
    return {
        orderId: order.order_id,
        orderStatus: order.order_status,
        orderType: 'both',
        trackingAvailable: order.order_status !== ORDER_STATUS.PLACED,
        directionsRefreshSeconds: refresh,
        shop: {
            name: laundry?.business_name || 'Laundry',
            ...trackingPoint(laundry?.address, laundry?.latitude, laundry?.longitude),
        },
        pickup: trackingPoint(
            order.pickup_address?.full_address,
            order.pickup_address?.latitude,
            order.pickup_address?.longitude
        ),
        delivery: trackingPoint(
            order.delivery_address?.full_address,
            order.delivery_address?.latitude,
            order.delivery_address?.longitude
        ),
        deliveries: {
            pickup: trackingLeg(pickupLeg),
            drop: trackingLeg(dropLeg),
        },
        captain: captainBlock(active && active.staff_id ? active : null),
    };
}

async function customerCatalog() {
    const categories = await prisma.serviceCategory.findMany({
        where: { is_active: true },
        orderBy: [{ display_order: 'asc' }, { category_name: 'asc' }],
        include: {
            services: {
                where: { is_active: true },
                orderBy: [{ display_order: 'asc' }, { service_name: 'asc' }],
                include: {
                    clothes_items: {
                        where: { is_active: true },
                        orderBy: [{ display_order: 'asc' }, { item_name: 'asc' }],
                    },
                },
            },
        },
    });
    return {
        categories: categories.map((category) => ({
            category_id: category.category_id,
            category_name: category.category_name,
            description: category.description,
            icon_url: category.icon_url,
            foreground_color: category.foreground_color,
            background_color: category.background_color,
            display_order: category.display_order,
            services: category.services.map((service) => ({
                service_id: service.service_id,
                service_name: service.service_name,
                description: service.description,
                icon_url: service.icon_url,
                display_order: service.display_order,
                per_kg_price: moneyStr(service.per_kg_price),
                includes: service.includes || [],
                excludes: service.excludes || [],
                clothes_items: service.clothes_items.map((cloth) => ({
                    cloth_id: cloth.cloth_id,
                    item_name: cloth.item_name,
                    per_unit_price: moneyStr(cloth.per_unit_price),
                    icon_url: cloth.icon_url,
                    display_order: cloth.display_order,
                })),
            })),
        })),
    };
}

async function pricingCatalogue() {
    const categories = await prisma.serviceCategory.findMany({
        where: { is_active: true },
        orderBy: [{ display_order: 'asc' }, { category_name: 'asc' }],
        include: {
            services: {
                where: { is_active: true },
                orderBy: [{ display_order: 'asc' }, { service_name: 'asc' }],
                include: {
                    clothes_items: {
                        where: { is_active: true },
                        orderBy: [{ display_order: 'asc' }, { item_name: 'asc' }],
                    },
                },
            },
        },
    });
    const result = [];
    for (const category of categories) {
        const services = [];
        for (const service of category.services) {
            const inspected = await inspectService(service.service_id);
            services.push({
                serviceId: service.service_id,
                serviceName: service.service_name,
                description: service.description,
                perKgPrice: service.per_kg_price == null ? null : String(service.per_kg_price),
                includes: service.includes || [],
                excludes: service.excludes || [],
                bookable: inspected.bookable && (inspected.perKgAvailable || inspected.perUnitAvailable),
                perKgAvailable: inspected.perKgAvailable,
                perUnitAvailable: inspected.perUnitAvailable,
                unavailableReason: inspected.reasons,
                clothes: service.clothes_items.map((cloth) => ({
                    clothId: cloth.cloth_id,
                    itemName: cloth.item_name,
                    perUnitPrice: String(cloth.per_unit_price),
                })),
            });
        }
        result.push({
            categoryId: category.category_id,
            categoryName: category.category_name,
            services,
        });
    }
    return result;
}

module.exports = {
    listOrders,
    getOrderDetail,
    getTracking,
    pricingCatalogue,
    customerCatalog,
};
