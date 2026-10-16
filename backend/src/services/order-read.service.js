const prisma = require('../config/database');
const configService = require('./config.service');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { ORDER_STATUS } = require('../constants/order-flow');
const { flagsFor, trackerFor } = require('./order-tracker');
const { inspectService } = require('./catalogue-rules');
const engine = require('./assignment/assignment-engine.service');

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

function lineView(item, includeMoney) {
    const base = {
        orderItemId: item.item_id,
        serviceId: item.service_id,
        serviceName: item.service?.service_name || null,
        pricingType: item.pricing_type,
        photoUrl: item.photo_url,
    };
    if (item.pricing_type === 'per_kg') {
        return {
            ...base,
            weightKg: item.weight_kg == null ? null : String(item.weight_kg),
            unitPrice: includeMoney && item.unit_price != null ? String(item.unit_price) : null,
            subtotal: includeMoney ? String(item.subtotal) : null,
        };
    }
    return {
        ...base,
        selections: (item.item_selections || []).map((row) => ({
            clothId: row.cloth_id,
            name: row.cloth_item?.item_name || null,
            quantity: row.quantity,
            unitPrice: includeMoney && row.unit_price != null ? String(row.unit_price) : null,
        })),
        subtotal: includeMoney ? String(item.subtotal) : null,
    };
}

async function listOrders({ customerId, bucket = 'active', page = 1, limit = 20 }) {
    if (!['active', 'history'].includes(bucket)) throw new ValidationError('bucket must be active or history');
    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.min(100, Math.max(1, Number(limit) || 20));
    const where = {
        customer_id: customerId,
        order_status: bucket === 'history' ? { in: HISTORY } : { notIn: ACTIVE_EXCLUDED },
    };
    const [rows, total] = await Promise.all([
        prisma.order.findMany({
            where,
            include: { bill: true },
            orderBy: { created_at: 'desc' },
            skip: (safePage - 1) * safeLimit,
            take: safeLimit,
        }),
        prisma.order.count({ where }),
    ]);
    return {
        orders: rows.map((order) => ({
            order_id: order.order_id,
            orderId: order.order_id,
            orderStatus: order.order_status,
            createdAt: order.created_at,
            totalAmount: order.bill ? String(order.bill.final_amount) : String(order.total_amount),
            ...flagsFor(order, order.bill),
        })),
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
            order_items: { include: { service: true, item_selections: { include: { cloth_item: true } } } },
            deliveries: { include: { staff: true } },
        },
    });
    if (!order) throw new NotFoundError('Order');
    const assign = await engine.getAssignState(order.order_id, order.order_status === ORDER_STATUS.SERVICES_COMPLETED || order.order_status === ORDER_STATUS.OUT_FOR_DELIVERY ? 'drop' : 'pickup');
    const includeMoney = Boolean(order.items_confirmed_at);
    const activeLeg =
        order.deliveries.find((row) => row.delivery_type === 'drop' && row.staff_id) ||
        order.deliveries.find((row) => row.delivery_type === 'pickup' && row.staff_id) ||
        null;
    return {
        orderId: order.order_id,
        orderStatus: order.order_status,
        schedule: {
            isExpress: order.is_express,
            pickupMode: order.pickup_mode,
            deliveryMode: order.delivery_mode,
            pickupTimeFrom: order.pickup_time_from,
            pickupTimeTo: order.pickup_time_to,
            deliveryTimeFrom: order.delivery_time_from,
            deliveryTimeTo: order.delivery_time_to,
        },
        pickupAddress: order.pickup_address,
        deliveryAddress: order.delivery_address,
        lines: order.order_items.map((item) => lineView(item, includeMoney)),
        bill: order.bill
            ? {
                  subtotal: String(order.bill.subtotal),
                  deliveryFee: String(order.bill.delivery_fee),
                  expressFee: String(order.bill.express_fee),
                  discount: String(order.bill.discount),
                  finalAmount: String(order.bill.final_amount),
                  paymentStatus: order.bill.payment_status,
                  paymentMethod: order.bill.payment_method,
                  couponCode: order.bill.coupon_code,
              }
            : null,
        captain: captainBlock(activeLeg),
        ...trackerFor(order, assign),
        ...flagsFor(order, order.bill),
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
};
