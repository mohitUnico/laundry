const ORDER_STATUS = {
    PICKUP: 'pickup',
    IN_PROCESS: 'in_process',
    READY: 'ready',
    OUT_FOR_DELIVERY: 'out_for_delivery',
    DELIVERED: 'delivered',
};

const PAYMENT_STATUS = {
    PENDING: 'pending',
    COMPLETED: 'completed',
    FAILED: 'failed',
    REFUNDED: 'refunded',
};

const PAYMENT_METHOD = {
    CARD: 'card',
    COD: 'cod',
    UPI: 'upi',
    WALLET: 'wallet',
};

const PRICING_MODEL = {
    PER_UNIT_PIECE: 'per-unit-piece',
    PER_KG: 'per-kg',
};

const DELIVERY_STATUS = {
    SCHEDULED: 'scheduled',
    ON_THE_WAY: 'on_the_way',
    PICKED_UP: 'picked_up',
    DROPPED: 'dropped',
};

const VERIFICATION_STATUS = {
    PENDING: 'pending',
    APPROVED: 'approved',
    REJECTED: 'rejected',
};

const USER_ROLES = {
    SUPER_ADMIN: 'super_admin',
    ADMIN: 'admin',
    MANAGER: 'manager',
    STAFF: 'staff',
};

const ADDRESS_LABEL = {
    HOME: 'home',
    WORK: 'work',
    FRIEND: 'friend',
    OTHER: 'other',
};

module.exports = {
    ORDER_STATUS,
    PAYMENT_STATUS,
    PAYMENT_METHOD,
    PRICING_MODEL,
    DELIVERY_STATUS,
    VERIFICATION_STATUS,
    USER_ROLES,
    ADDRESS_LABEL,
};

