const prisma = require('../config/database');
const engine = require('./assignment/assignment-engine.service');
const deliveryOps = require('./delivery-operations.service');
const { ORDER_STATUS } = require('../constants/order-flow');

async function assignView(order, now = new Date()) {
    if (order.delivery_mode === 'scheduled' && order.delivery_time_from && new Date(order.delivery_time_from) > now) {
        const state = await engine.getAssignState(order.order_id, 'drop');
        if (state.state === 'none' || state.state === 'searching') {
            if (state.state !== 'searching' && state.state !== 'assigned' && state.state !== 'enabled') {
                return { state: 'available_from', availableFrom: order.delivery_time_from };
            }
        }
    }
    const state = await engine.getAssignState(order.order_id, 'drop');
    return { state: state.state, endsAt: state.endsAt || null, availableFrom: null };
}

async function readyToDispatch() {
    const orders = await prisma.order.findMany({
        where: { order_status: ORDER_STATUS.SERVICES_COMPLETED },
        orderBy: [{ is_express: 'desc' }, { created_at: 'asc' }],
    });
    const rows = [];
    for (const order of orders) {
        rows.push({
            orderId: order.order_id,
            isExpress: order.is_express,
            deliveryMode: order.delivery_mode,
            deliveryTimeFrom: order.delivery_time_from,
            assign: await assignView(order),
        });
    }
    return rows;
}

async function history({ page = 1, limit = 20 } = {}) {
    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.min(100, Math.max(1, Number(limit) || 20));
    const where = { order_status: { in: [ORDER_STATUS.OUT_FOR_DELIVERY, ORDER_STATUS.DELIVERED] } };
    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where,
            orderBy: { updated_at: 'desc' },
            skip: (safePage - 1) * safeLimit,
            take: safeLimit,
        }),
        prisma.order.count({ where }),
    ]);
    return {
        orders: orders.map((order) => ({
            orderId: order.order_id,
            orderStatus: order.order_status,
            isExpress: order.is_express,
            updatedAt: order.updated_at,
        })),
        pagination: { page: safePage, limit: safeLimit, total },
    };
}

async function assignableStaff(orderId) {
    return engine.listAssignableStaff(orderId, 'drop');
}

async function assignDrop({ orderId, deliveryStaffId, assignedBy }) {
    return deliveryOps.directAssignDelivery({
        orderId,
        deliveryType: 'drop',
        deliveryStaffId,
        assignedBy,
    });
}

module.exports = {
    readyToDispatch,
    history,
    assignableStaff,
    assignDrop,
};
