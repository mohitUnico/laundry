// Sample Order Service
// This is a template - implement full logic as needed

const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { ORDER_STATUS } = require('../constants');

exports.createOrder = async (customerId, orderData) => {
    // Validate order data
    if (!orderData.mart_id || !orderData.pickup_address_id) {
        throw new ValidationError('Missing required fields');
    }

    // Use Prisma transaction for atomic operations
    return await prisma.$transaction(async (tx) => {
        // Create order
        const order = await tx.order.create({
            data: {
                customer_id: customerId,
                mart_id: orderData.mart_id,
                order_status: ORDER_STATUS.PICKUP,
                pricing_model: orderData.pricing_model,
                total_amount: orderData.total_amount,
                pickup_address_id: orderData.pickup_address_id,
                delivery_address_id: orderData.delivery_address_id,
                pickup_date: new Date(orderData.pickup_date),
                delivery_date: new Date(orderData.delivery_date),
                special_instructions: orderData.special_instructions,
            },
            include: {
                customer: {
                    select: { full_name: true, email: true, phone: true },
                },
                mart: {
                    select: { mart_name: true, contact_phone: true },
                },
            },
        });

        // Create order items (per-piece)
        if (orderData.items && orderData.items.length > 0) {
            await tx.orderItem.createMany({
                data: orderData.items.map((item) => ({
                    order_id: order.order_id,
                    clothes_id: item.clothes_id,
                    quantity: item.quantity,
                    unit_price: item.unit_price,
                    subtotal: item.quantity * item.unit_price,
                })),
            });
        }

        // Create order items (per-kg)
        if (orderData.items_kg && orderData.items_kg.length > 0) {
            await tx.orderItemKg.createMany({
                data: orderData.items_kg.map((item) => ({
                    order_id: order.order_id,
                    item_name: item.item_name,
                    weight_kg: item.weight_kg,
                    price_per_kg: item.price_per_kg,
                    subtotal: item.weight_kg * item.price_per_kg,
                })),
            });
        }

        // Create bill
        await tx.bill.create({
            data: {
                order_id: order.order_id,
                subtotal: orderData.subtotal,
                delivery_fee: orderData.delivery_fee,
                tax_amount: orderData.tax_amount,
                discount: orderData.discount || 0,
                final_amount: orderData.total_amount,
                payment_method: orderData.payment_method,
                payment_status: 'pending',
            },
        });

        return order;
    });
};

exports.getOrders = async (customerId, filters) => {
    const { page, limit, status } = filters;

    const where = {
        customer_id: customerId,
        ...(status && { order_status: status }),
    };

    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where,
            include: {
                mart: {
                    select: { mart_name: true, contact_phone: true },
                },
                bill: true,
            },
            orderBy: { created_at: 'desc' },
            skip: (page - 1) * limit,
            take: limit,
        }),
        prisma.order.count({ where }),
    ]);

    return {
        orders,
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
    };
};

exports.getOrderById = async (orderId) => {
    return await prisma.order.findUnique({
        where: { order_id: orderId },
        include: {
            customer: {
                select: { full_name: true, email: true, phone: true },
            },
            mart: {
                select: { mart_name: true, contact_phone: true, address: true },
            },
            pickup_address: true,
            delivery_address: true,
            order_items: {
                include: {
                    clothes: true,
                },
            },
            order_items_kg: true,
            bill: true,
            delivery: {
                include: {
                    staff: {
                        select: { full_name: true, phone: true, vehicle_type: true },
                    },
                    pickup: true,
                    drop: true,
                },
            },
        },
    });
};

exports.updateOrderStatus = async (orderId, newStatus) => {
    // Validate status transition
    const validStatuses = Object.values(ORDER_STATUS);
    if (!validStatuses.includes(newStatus)) {
        throw new ValidationError('Invalid order status');
    }

    return await prisma.order.update({
        where: { order_id: orderId },
        data: { order_status: newStatus },
    });
};

exports.cancelOrder = async (orderId) => {
    // Check if order can be cancelled
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
    });

    if (!order) {
        throw new NotFoundError('Order');
    }

    if (order.order_status === ORDER_STATUS.DELIVERED) {
        throw new ValidationError('Cannot cancel delivered order');
    }

    // Delete order (cascade deletes related records)
    await prisma.order.delete({
        where: { order_id: orderId },
    });
};

module.exports = exports;
