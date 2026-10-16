/**
 * Order-flow v2 status machine.
 * Source: docs/order-flow-v2/diagrams/04-state-machines.md section 5.1
 *
 * New code must call assertTransition(from, to) before writing order_status.
 * The Prisma enum contains only these eleven values.
 */

const { ConflictError } = require('../utils/errors');

const ORDER_STATUS = {
    PLACED: 'placed',
    PICKUP_ASSIGNED: 'pickup_assigned',
    PICKED_UP: 'picked_up',
    SUBMITTED_TO_CM: 'submitted_to_cm',
    RECEIVED_BY_COLLECTION: 'received_by_collection',
    SUBMITTED_TO_SERVICES: 'submitted_to_services',
    SERVICES_IN_PROGRESS: 'services_in_progress',
    SERVICES_COMPLETED: 'services_completed',
    OUT_FOR_DELIVERY: 'out_for_delivery',
    DELIVERED: 'delivered',
    CANCELLED: 'cancelled',
};

const LIVE_STATUSES = Object.values(ORDER_STATUS);

/** Allowed next statuses for each live status (diagram 5.1). */
const TRANSITIONS = {
    [ORDER_STATUS.PLACED]: [
        ORDER_STATUS.CANCELLED,
        ORDER_STATUS.PLACED, // reschedule: status stays placed
        ORDER_STATUS.PICKUP_ASSIGNED,
    ],
    [ORDER_STATUS.PICKUP_ASSIGNED]: [ORDER_STATUS.PICKED_UP],
    [ORDER_STATUS.PICKED_UP]: [ORDER_STATUS.SUBMITTED_TO_CM],
    [ORDER_STATUS.SUBMITTED_TO_CM]: [ORDER_STATUS.RECEIVED_BY_COLLECTION],
    [ORDER_STATUS.RECEIVED_BY_COLLECTION]: [ORDER_STATUS.SUBMITTED_TO_SERVICES],
    [ORDER_STATUS.SUBMITTED_TO_SERVICES]: [ORDER_STATUS.SERVICES_IN_PROGRESS],
    [ORDER_STATUS.SERVICES_IN_PROGRESS]: [
        ORDER_STATUS.SERVICES_IN_PROGRESS,
        ORDER_STATUS.SERVICES_COMPLETED,
    ],
    [ORDER_STATUS.SERVICES_COMPLETED]: [ORDER_STATUS.OUT_FOR_DELIVERY],
    [ORDER_STATUS.OUT_FOR_DELIVERY]: [ORDER_STATUS.DELIVERED],
    [ORDER_STATUS.DELIVERED]: [],
    [ORDER_STATUS.CANCELLED]: [],
};

const DELIVERY_STATUS = {
    UNASSIGNED: 'unassigned',
    ASSIGNED: 'assigned',
    IN_PROGRESS: 'in_progress',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled',
};

function isAllowedTransition(from, to) {
    const allowed = TRANSITIONS[from];
    return Array.isArray(allowed) && allowed.includes(to);
}

/**
 * @param {string} from
 * @param {string} to
 * @throws {ConflictError} code INVALID_STATUS_TRANSITION
 */
function assertTransition(from, to) {
    if (!isAllowedTransition(from, to)) {
        throw new ConflictError(
            `Invalid status transition: ${from} -> ${to}`,
            'INVALID_STATUS_TRANSITION'
        );
    }
}

module.exports = {
    ORDER_STATUS,
    LIVE_STATUSES,
    TRANSITIONS,
    DELIVERY_STATUS,
    isAllowedTransition,
    assertTransition,
};
