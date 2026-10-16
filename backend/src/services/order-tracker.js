const { ORDER_STATUS } = require('../constants/order-flow');

const STEPS = [
    { step: 1, label: 'Out for pickup' },
    { step: 2, label: 'Pickup done' },
    { step: 3, label: 'In process' },
    { step: 4, label: 'Ready' },
    { step: 5, label: 'Out for delivery' },
    { step: 6, label: 'Delivered' },
];

const STATUS_STEP = {
    [ORDER_STATUS.PLACED]: 1,
    [ORDER_STATUS.PICKUP_ASSIGNED]: 1,
    [ORDER_STATUS.PICKED_UP]: 2,
    [ORDER_STATUS.SUBMITTED_TO_CM]: 3,
    [ORDER_STATUS.RECEIVED_BY_COLLECTION]: 3,
    [ORDER_STATUS.SUBMITTED_TO_SERVICES]: 3,
    [ORDER_STATUS.SERVICES_IN_PROGRESS]: 3,
    [ORDER_STATUS.SERVICES_COMPLETED]: 4,
    [ORDER_STATUS.OUT_FOR_DELIVERY]: 5,
    [ORDER_STATUS.DELIVERED]: 6,
};

const PAYABLE = new Set([
    ORDER_STATUS.PICKED_UP,
    ORDER_STATUS.SUBMITTED_TO_CM,
    ORDER_STATUS.RECEIVED_BY_COLLECTION,
    ORDER_STATUS.SUBMITTED_TO_SERVICES,
    ORDER_STATUS.SERVICES_IN_PROGRESS,
    ORDER_STATUS.SERVICES_COMPLETED,
    ORDER_STATUS.OUT_FOR_DELIVERY,
]);

function flagsFor(order, bill) {
    const status = order.order_status;
    return {
        canCancel: status === ORDER_STATUS.PLACED,
        canReschedule: status === ORDER_STATUS.PLACED && !order.is_express,
        canPay: Boolean(bill && bill.payment_status === 'pending' && PAYABLE.has(status)),
        isExpress: Boolean(order.is_express),
        pickupMode: order.pickup_mode,
        deliveryMode: order.delivery_mode,
    };
}

function trackerFor(order, assignState) {
    if (order.order_status === ORDER_STATUS.CANCELLED) {
        return {
            tracker: null,
            cancelled: { reason: order.cancel_reason || null, at: order.cancelled_at || null },
        };
    }
    const current = STATUS_STEP[order.order_status] || 1;
    const substatus =
        order.order_status === ORDER_STATUS.PLACED
            ? assignState?.state === 'searching'
                ? 'Finding a partner'
                : 'Finding a partner'
            : null;
    return {
        tracker: {
            currentStep: current,
            substatus,
            steps: STEPS.map((step) => ({
                ...step,
                state: step.step < current ? 'done' : step.step === current ? 'current' : 'upcoming',
            })),
        },
        cancelled: null,
    };
}

module.exports = {
    STEPS,
    STATUS_STEP,
    flagsFor,
    trackerFor,
};
