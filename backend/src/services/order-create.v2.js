const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { isServiceBookable, assertBookable } = require('./catalogue-rules');
const { validateSchedule } = require('./schedule-rules');
const assignmentTrigger = require('./assignment/assignment-trigger');
const { ORDER_STATUS, DELIVERY_STATUS } = require('../constants/order-flow');

async function createDeliveryLegs(tx, { order, pickupAddress, deliveryAddress, laundry, schedule }) {
    const Decimal = Prisma.Decimal;

    const createLeg = async ({ deliveryType, pickup, drop, from, to }) => {
        const delivery = await tx.delivery.create({
            data: {
                order_id: order.order_id,
                staff_id: null,
                delivery_type: deliveryType,
                delivery_status: DELIVERY_STATUS.UNASSIGNED,
                delivery_fee: new Decimal(0),
            },
            select: { delivery_id: true },
        });

        await tx.pickupForDelivery.create({
            data: {
                delivery_id: delivery.delivery_id,
                pickup_address: pickup.address,
                pickup_lat: pickup.latitude,
                pickup_lng: pickup.longitude,
                pickup_status: DELIVERY_STATUS.UNASSIGNED,
                preferred_pickup_from: from,
                preferred_pickup_to: to,
            },
        });

        await tx.dropForDelivery.create({
            data: {
                delivery_id: delivery.delivery_id,
                drop_address: drop.address,
                drop_lat: drop.latitude,
                drop_lng: drop.longitude,
                drop_status: DELIVERY_STATUS.UNASSIGNED,
                preferred_drop_from: from,
                preferred_drop_to: to,
            },
        });
    };

    await createLeg({
        deliveryType: 'pickup',
        pickup: {
            address: pickupAddress.full_address,
            latitude: pickupAddress.latitude,
            longitude: pickupAddress.longitude,
        },
        drop: {
            address: laundry.address,
            latitude: laundry.latitude,
            longitude: laundry.longitude,
        },
        from: schedule.pickup_time_from,
        to: schedule.pickup_time_to,
    });

    await createLeg({
        deliveryType: 'drop',
        pickup: {
            address: laundry.address,
            latitude: laundry.latitude,
            longitude: laundry.longitude,
        },
        drop: {
            address: deliveryAddress.full_address,
            latitude: deliveryAddress.latitude,
            longitude: deliveryAddress.longitude,
        },
        from: schedule.delivery_time_from,
        to: schedule.delivery_time_to,
    });
}

exports.createOrder = async (customerId, payload) => {
    const schedule = await validateSchedule(payload);

    const result = await prisma.$transaction(
        async (tx) => {
            const customer = await tx.customer.findUnique({
                where: { customer_id: customerId },
                select: { customer_id: true },
            });
            if (!customer) throw new NotFoundError('Customer');

            const uniqueAddressIds = Array.from(
                new Set([payload.pickup_address_id, payload.delivery_address_id])
            );
            const addressRecords = await tx.customerAddress.findMany({
                where: { customer_id: customerId, address_id: { in: uniqueAddressIds } },
            });
            if (addressRecords.length !== uniqueAddressIds.length) {
                throw new ValidationError('Invalid pickup or delivery address');
            }

            const cart = await tx.cart.findFirst({
                where: {
                    cart_id: payload.cart_id,
                    customer_id: customerId,
                    is_active: true,
                },
                include: {
                    cart_items: {
                        include: {
                            service: { include: { category: true } },
                        },
                    },
                },
            });
            if (!cart) {
                throw new NotFoundError('Active cart');
            }
            if (!cart.cart_items.length) {
                throw new ValidationError('Cart is empty. Add items to cart before creating an order');
            }

            for (const line of cart.cart_items) {
                const check = await isServiceBookable(line.service_id, line.pricing_type, { tx });
                assertBookable(check, line.service_id);
            }

            const laundry = await tx.laundryConfig.findFirst({
                where: { is_active: true },
                orderBy: { created_at: 'desc' },
            });
            if (!laundry) throw new NotFoundError('LaundryConfig');

            const pickupAddress = addressRecords.find((a) => a.address_id === payload.pickup_address_id);
            const deliveryAddress = addressRecords.find((a) => a.address_id === payload.delivery_address_id);

            const order = await tx.order.create({
                data: {
                    customer_id: customerId,
                    cart_id: cart.cart_id,
                    order_status: ORDER_STATUS.PLACED,
                    is_express: schedule.is_express,
                    pickup_mode: schedule.pickup_mode,
                    delivery_mode: schedule.delivery_mode,
                    total_amount: 0,
                    pickup_address_id: payload.pickup_address_id,
                    delivery_address_id: payload.delivery_address_id,
                    pickup_time_from: schedule.pickup_time_from,
                    pickup_time_to: schedule.pickup_time_to,
                    delivery_time_from: schedule.delivery_time_from,
                    delivery_time_to: schedule.delivery_time_to,
                    special_instructions: payload.special_instructions || null,
                    items_confirmed_at: null,
                },
            });

            for (const line of cart.cart_items) {
                await tx.orderItem.create({
                    data: {
                        order_id: order.order_id,
                        service_id: line.service_id,
                        pricing_type: line.pricing_type,
                        clothes_id: null,
                        quantity: null,
                        weight_kg: null,
                        unit_price: null,
                        subtotal: 0,
                        item_status: 'pending',
                    },
                });
            }

            await createDeliveryLegs(tx, {
                order,
                pickupAddress,
                deliveryAddress,
                laundry,
                schedule,
            });

            await tx.cart.delete({ where: { cart_id: cart.cart_id } });

            const items = await tx.orderItem.findMany({
                where: { order_id: order.order_id },
                include: { service: { select: { service_id: true, service_name: true } } },
            });

            return {
                order_id: order.order_id,
                order_status: order.order_status,
                is_express: order.is_express,
                pickup_mode: order.pickup_mode,
                delivery_mode: order.delivery_mode,
                pickup_time_from: order.pickup_time_from,
                pickup_time_to: order.pickup_time_to,
                delivery_time_from: order.delivery_time_from,
                delivery_time_to: order.delivery_time_to,
                total_amount: '0.00',
                special_instructions: order.special_instructions,
                bill: null,
                can_cancel: true,
                can_reschedule: !order.is_express,
                items: items.map((it) => ({
                    item_id: it.item_id,
                    service_id: it.service_id,
                    service_name: it.service.service_name,
                    pricing_type: it.pricing_type,
                })),
            };
        },
        { maxWait: 10000, timeout: 60000 }
    );

    await assignmentTrigger.onOrderPlaced(result);
    return result;
};
