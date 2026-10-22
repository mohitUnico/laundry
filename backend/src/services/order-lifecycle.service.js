const prisma = require('../config/database');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');
const { validateSchedule } = require('./schedule-rules');
const engine = require('./assignment/assignment-engine.service');
const { onOrderPlaced } = require('./assignment/assignment-trigger');
const { DELIVERY_STATUS } = require('../constants/order-flow');

async function cancelOrder(customerId, orderId, reason) {
    const trimmed = typeof reason === 'string' ? reason.trim() : '';
    if (trimmed.length < 3 || trimmed.length > 500) {
        throw new ValidationError('reason is required (3 to 500 characters)');
    }

    const when = new Date();
    const updated = await prisma.order.updateMany({
        where: { order_id: orderId, customer_id: customerId, order_status: 'placed' },
        data: {
            order_status: 'cancelled',
            cancel_reason: trimmed,
            cancelled_at: when,
        },
    });
    if (updated.count === 0) {
        const exists = await prisma.order.findFirst({
            where: { order_id: orderId, customer_id: customerId },
            select: { order_id: true },
        });
        if (!exists) throw new NotFoundError('Order');
        throw new ConflictError('Order can only be cancelled while it is placed', 'CANCEL_NOT_ALLOWED');
    }

    await prisma.delivery.updateMany({
        where: { order_id: orderId },
        data: { delivery_status: DELIVERY_STATUS.CANCELLED },
    });
    await engine.stopSearch(orderId, 'pickup', 'cancelled', { now: when });
    require('./notification-events').emitOrderEvent('cancelled', { orderId }).catch(() => {});

    return { order_id: orderId, order_status: 'cancelled', cancel_reason: trimmed, cancelled_at: when };
}

const SCHEDULE_KEYS = [
    'pickup_mode',
    'delivery_mode',
    'pickup_time_from',
    'pickup_time_to',
    'delivery_time_from',
    'delivery_time_to',
];

function hasKey(body, key) {
    return Object.prototype.hasOwnProperty.call(body, key) && body[key] !== undefined;
}

async function ownedAddress(customerId, addressId) {
    const address = await prisma.customerAddress.findFirst({
        where: { address_id: addressId, customer_id: customerId },
    });
    if (!address) throw new ValidationError('Invalid pickup or delivery address');
    return address;
}

async function applyAddressChange(orderId, { pickupAddress, deliveryAddress }) {
    if (pickupAddress) {
        const leg = await prisma.delivery.findFirst({
            where: { order_id: orderId, delivery_type: 'pickup' },
            select: { delivery_id: true },
        });
        if (leg) {
            await prisma.pickupForDelivery.updateMany({
                where: { delivery_id: leg.delivery_id },
                data: {
                    pickup_address: pickupAddress.full_address,
                    pickup_lat: pickupAddress.latitude,
                    pickup_lng: pickupAddress.longitude,
                },
            });
        }
    }
    if (deliveryAddress) {
        const leg = await prisma.delivery.findFirst({
            where: { order_id: orderId, delivery_type: 'drop' },
            select: { delivery_id: true },
        });
        if (leg) {
            await prisma.dropForDelivery.updateMany({
                where: { delivery_id: leg.delivery_id },
                data: {
                    drop_address: deliveryAddress.full_address,
                    drop_lat: deliveryAddress.latitude,
                    drop_lng: deliveryAddress.longitude,
                },
            });
        }
    }
}

async function rescheduleOrder(customerId, orderId, body) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
    });
    if (!order) throw new NotFoundError('Order');

    const scheduleChange = SCHEDULE_KEYS.some((key) => hasKey(body, key)) || (!hasKey(body, 'pickup_address_id') && !hasKey(body, 'delivery_address_id'));
    const addressChange = hasKey(body, 'pickup_address_id') || hasKey(body, 'delivery_address_id');
    if (order.order_status !== 'placed' || (scheduleChange && order.is_express)) {
        throw new ConflictError('Order cannot be rescheduled', 'RESCHEDULE_NOT_ALLOWED');
    }

    let schedule = null;
    if (scheduleChange) {
        schedule = await validateSchedule({
            is_express: false,
            pickup_mode: body.pickup_mode || order.pickup_mode,
            delivery_mode: body.delivery_mode || order.delivery_mode,
            pickup_time_from: body.pickup_time_from !== undefined ? body.pickup_time_from : order.pickup_time_from,
            pickup_time_to: body.pickup_time_to !== undefined ? body.pickup_time_to : order.pickup_time_to,
            delivery_time_from: body.delivery_time_from !== undefined ? body.delivery_time_from : order.delivery_time_from,
            delivery_time_to: body.delivery_time_to !== undefined ? body.delivery_time_to : order.delivery_time_to,
        });
    }

    const pickupAddress = hasKey(body, 'pickup_address_id') ? await ownedAddress(customerId, body.pickup_address_id) : null;
    const deliveryAddress = hasKey(body, 'delivery_address_id') ? await ownedAddress(customerId, body.delivery_address_id) : null;

    const data = {};
    if (schedule) {
        data.pickup_mode = schedule.pickup_mode;
        data.delivery_mode = schedule.delivery_mode;
        data.pickup_time_from = schedule.pickup_time_from;
        data.pickup_time_to = schedule.pickup_time_to;
        data.delivery_time_from = schedule.delivery_time_from;
        data.delivery_time_to = schedule.delivery_time_to;
    }
    if (pickupAddress) data.pickup_address_id = pickupAddress.address_id;
    if (deliveryAddress) data.delivery_address_id = deliveryAddress.address_id;

    const locked = await prisma.order.updateMany({
        where: {
            order_id: orderId,
            customer_id: customerId,
            order_status: 'placed',
            ...(scheduleChange ? { is_express: false } : {}),
        },
        data,
    });
    if (locked.count === 0) {
        throw new ConflictError('Order cannot be rescheduled', 'RESCHEDULE_NOT_ALLOWED');
    }

    if (addressChange) {
        await applyAddressChange(orderId, { pickupAddress, deliveryAddress });
    }

    if (scheduleChange) {
        await engine.stopSearch(orderId, 'pickup', 'rescheduled');
        require('./notification-events').emitOrderEvent('rescheduled', { orderId }).catch(() => {});
        await onOrderPlaced({
            order_id: orderId,
            is_express: false,
            pickup_mode: schedule.pickup_mode,
            pickup_time_from: schedule.pickup_time_from,
        });
    }

    return {
        order_id: orderId,
        order_status: 'placed',
        ...(schedule || {
            pickup_mode: order.pickup_mode,
            delivery_mode: order.delivery_mode,
            pickup_time_from: order.pickup_time_from,
            pickup_time_to: order.pickup_time_to,
            delivery_time_from: order.delivery_time_from,
            delivery_time_to: order.delivery_time_to,
        }),
    };
}

module.exports = {
    cancelOrder,
    rescheduleOrder,
};
