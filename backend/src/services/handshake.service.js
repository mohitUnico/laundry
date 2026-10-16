const prisma = require('../config/database');
const { assertTransition, ORDER_STATUS, DELIVERY_STATUS } = require('../constants/order-flow');
const { ConflictError, ForbiddenError, NotFoundError } = require('../utils/errors');
const { emitOrderEvent } = require('./notification-events');
const engine = require('./assignment/assignment-engine.service');

async function submitToCollectionManager({ staffId, orderId }) {
    const delivery = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: 'pickup', staff_id: staffId },
        include: { order: true },
    });
    if (!delivery || !delivery.order) {
        throw new ForbiddenError('Only the assigned pickup partner can submit this order');
    }
    if (delivery.order.order_status === ORDER_STATUS.SUBMITTED_TO_CM) {
        return {
            orderId,
            orderStatus: ORDER_STATUS.SUBMITTED_TO_CM,
            primaryAction: { key: 'WAITING_FOR_CM', enabled: false },
            idempotent: true,
        };
    }
    assertTransition(delivery.order.order_status, ORDER_STATUS.SUBMITTED_TO_CM);
    const updated = await prisma.order.updateMany({
        where: { order_id: orderId, order_status: ORDER_STATUS.PICKED_UP },
        data: { order_status: ORDER_STATUS.SUBMITTED_TO_CM },
    });
    if (updated.count === 0) {
        const current = await prisma.order.findUnique({ where: { order_id: orderId } });
        if (current?.order_status === ORDER_STATUS.SUBMITTED_TO_CM) {
            return {
                orderId,
                orderStatus: ORDER_STATUS.SUBMITTED_TO_CM,
                primaryAction: { key: 'WAITING_FOR_CM', enabled: false },
                idempotent: true,
            };
        }
        throw new ConflictError('Submit to the collection manager is only allowed after pickup is confirmed', 'SUBMIT_NOT_ALLOWED');
    }
    emitOrderEvent('submitted_to_cm', { orderId }).catch(() => {});
    return {
        orderId,
        orderStatus: ORDER_STATUS.SUBMITTED_TO_CM,
        deliveryStatus: delivery.delivery_status,
        primaryAction: { key: 'WAITING_FOR_CM', enabled: false },
    };
}

async function markReceived({ staffId, orderId }) {
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        include: { deliveries: { where: { delivery_type: 'pickup' } } },
    });
    if (!order) throw new NotFoundError('Order');
    if (order.order_status === ORDER_STATUS.RECEIVED_BY_COLLECTION) {
        return { orderId, orderStatus: order.order_status, idempotent: true };
    }
    if (order.order_status !== ORDER_STATUS.SUBMITTED_TO_CM) {
        throw new ConflictError(
            'The collection manager can mark an order received only after the partner submits it',
            'RECEIVE_NOT_ALLOWED'
        );
    }
    assertTransition(order.order_status, ORDER_STATUS.RECEIVED_BY_COLLECTION);
    const now = new Date();
    await prisma.$transaction(async (tx) => {
        const moved = await tx.order.updateMany({
            where: { order_id: orderId, order_status: ORDER_STATUS.SUBMITTED_TO_CM },
            data: {
                order_status: ORDER_STATUS.RECEIVED_BY_COLLECTION,
                received_by_collection_manager_id: staffId,
                received_at: now,
            },
        });
        if (moved.count === 0) {
            throw new ConflictError('Order was already received', 'RECEIVE_NOT_ALLOWED');
        }
        const pickup = order.deliveries[0];
        if (pickup) {
            await tx.delivery.update({
                where: { delivery_id: pickup.delivery_id },
                data: { delivery_status: DELIVERY_STATUS.COMPLETED, completed_at: now },
            });
            await tx.pickupForDelivery.updateMany({
                where: { delivery_id: pickup.delivery_id },
                data: { pickup_status: 'completed' },
            });
        }
    });
    emitOrderEvent('received_at_plant', { orderId }).catch(() => {});
    return { orderId, orderStatus: ORDER_STATUS.RECEIVED_BY_COLLECTION };
}

function phaseFor(order) {
    return order.order_status;
}

async function listIncoming({ page = 1, limit = 20 } = {}) {
    const skip = (Number(page) - 1) * Number(limit);
    const where = {
        order_status: {
            in: [
                ORDER_STATUS.PLACED,
                ORDER_STATUS.PICKUP_ASSIGNED,
                ORDER_STATUS.PICKED_UP,
                ORDER_STATUS.SUBMITTED_TO_CM,
                ORDER_STATUS.RECEIVED_BY_COLLECTION,
            ],
        },
    };
    const [rows, total] = await Promise.all([
        prisma.order.findMany({
            where,
            include: {
                bill: true,
                deliveries: {
                    where: { delivery_type: 'pickup' },
                    include: { staff: true },
                },
            },
            orderBy: [{ is_express: 'desc' }, { created_at: 'asc' }],
            skip,
            take: Number(limit),
        }),
        prisma.order.count({ where }),
    ]);
    const data = [];
    for (const order of rows) {
        const partner = order.deliveries[0]?.staff;
        const assign = await engine.getAssignState(order.order_id, 'pickup');
        data.push({
            orderId: order.order_id,
            phase: phaseFor(order),
            orderStatus: order.order_status,
            isExpress: order.is_express,
            pickupMode: order.pickup_mode,
            pickupTimeFrom: order.pickup_time_from,
            pickupTimeTo: order.pickup_time_to,
            canMarkReceived: order.order_status === ORDER_STATUS.SUBMITTED_TO_CM,
            partner: partner
                ? { staffId: partner.staff_id, name: partner.full_name, phone: partner.phone }
                : null,
            assign: { state: assign.state, endsAt: assign.endsAt || null },
            billTotal: order.bill ? String(order.bill.final_amount) : null,
            createdAt: order.created_at,
        });
    }
    return {
        orders: data,
        pagination: { page: Number(page), limit: Number(limit), total },
    };
}

module.exports = {
    submitToCollectionManager,
    markReceived,
    listIncoming,
};
