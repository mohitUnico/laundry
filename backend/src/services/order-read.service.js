const prisma = require('../config/database');
const configService = require('./config.service');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { ORDER_STATUS } = require('../constants/order-flow');
const { flagsFor } = require('./order-tracker');
const { inspectService } = require('./catalogue-rules');

const HISTORY = [ORDER_STATUS.DELIVERED, ORDER_STATUS.CANCELLED];
const ACTIVE_EXCLUDED = [ORDER_STATUS.DELIVERED, ORDER_STATUS.CANCELLED];

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
        can_reschedule: placed && !order.is_express,
        can_change_address: placed,
    };
}

const ORDER_ITEM_INCLUDE = {
    service: true,
    item_selections: { include: { cloth_item: true } },
};

function statusFilter({ bucket, status }) {
    if (status === 'completed') return ORDER_STATUS.DELIVERED;
    if (status === 'active') return { notIn: ACTIVE_EXCLUDED };
    if (status != null && status !== '') throw new ValidationError('status must be active or completed');
    if (bucket == null || bucket === '' || bucket === 'active') return { notIn: ACTIVE_EXCLUDED };
    if (bucket === 'history') return { in: HISTORY };
    throw new ValidationError('bucket must be active or history');
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
        orders: rows.map((order) => {
            const flags = contractFlags(order);
            return {
                order_id: order.order_id,
                orderId: order.order_id,
                order_status: order.order_status,
                orderStatus: order.order_status,
                is_express: order.is_express,
                created_at: order.created_at,
                createdAt: order.created_at,
                pickup_mode: order.pickup_mode,
                pickup_time_from: order.pickup_time_from,
                pickup_time_to: order.pickup_time_to,
                pickup_address: addressSummary(order.pickup_address),
                services: order.order_items.map((item) => ({
                    service_id: item.service_id,
                    service_name: item.service?.service_name || null,
                    pricing_type: item.pricing_type,
                })),
                item_count: itemCount(order.order_items),
                can_cancel: flags.can_cancel,
                can_reschedule: flags.can_reschedule,
                bill: billContract(order.bill),
                totalAmount: order.bill ? moneyStr(order.bill.final_amount) : moneyStr(order.total_amount),
                ...flagsFor(order, order.bill),
            };
        }),
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

async function getTracking({ customerId, orderId }) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
        include: { deliveries: { include: { staff: true } } },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status === ORDER_STATUS.PLACED || order.order_status === ORDER_STATUS.CANCELLED) {
        return { trackingAvailable: false, orderStatus: order.order_status };
    }
    const legType = [ORDER_STATUS.OUT_FOR_DELIVERY, ORDER_STATUS.DELIVERED, ORDER_STATUS.SERVICES_COMPLETED].includes(order.order_status)
        ? 'drop'
        : 'pickup';
    const leg = order.deliveries.find((row) => row.delivery_type === legType && row.staff_id) || null;
    if (!leg) return { trackingAvailable: false, orderStatus: order.order_status };
    const refresh = await configService.getInt('DIRECTIONS_REFRESH_SECONDS');
    return {
        trackingAvailable: true,
        orderStatus: order.order_status,
        deliveryType: legType,
        directionsRefreshSeconds: refresh,
        eta: null,
        captain: captainBlock(leg),
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
