export const ORDER_STATUS = {
    PICKUP: 'pickup',
    IN_PROCESS: 'in_process',
    READY: 'ready',
    OUT_FOR_DELIVERY: 'out_for_delivery',
    DELIVERED: 'delivered',
} as const

export const PAYMENT_STATUS = {
    PENDING: 'pending',
    COMPLETED: 'completed',
    FAILED: 'failed',
    REFUNDED: 'refunded',
} as const

export const DELIVERY_STATUS = {
    SCHEDULED: 'scheduled',
    ON_THE_WAY: 'on_the_way',
    PICKED_UP: 'picked_up',
    DROPPED: 'dropped',
} as const

export const PRICING_MODEL = {
    PER_UNIT_PIECE: 'per-unit-piece',
    PER_KG: 'per-kg',
} as const

