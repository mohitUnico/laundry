const logger = require('../utils/logger');
const prisma = require('../config/database');
const { schedulePickupAssignment } = require('../queues/pickup-assignment.queue');
const { getPickupAssignmentConfig } = require('../config/delivery-assignment.config');

let jobIntervalHandle = null;

const isJobEnabled = () => {
    if (process.env.NODE_ENV === 'test') return false;
    if (process.env.PICKUP_ASSIGNMENT_CATCHUP_ENABLED === 'false') return false;
    // Only enable if queue-based assignment is enabled
    if (process.env.PICKUP_ASSIGNMENT_USE_QUEUE !== 'true') return false;
    return true;
};

/**
 * Catch-up job: Find orders that should have been assigned but weren't.
 * Safety net for Redis Cloud free tier (no persistence): scheduled jobs
 * are lost on Redis restart, so we re-queue eligible orders every 5 minutes.
 * Also covers worker downtime or missed jobs.
 * 
 * IMPORTANT: Only re-queues orders whose pickup_time_from is in the future (not expired).
 * Expired orders are handled by the retry mechanism (max 2 attempts).
 */
const catchUpMissedPickupAssignments = async () => {
    try {
        const now = new Date();

        // Find orders that:
        // 1. Have pickup_time_from in the FUTURE (not expired) - only re-queue future scheduled jobs
        // 2. Are in 'placed' status
        // 3. Have pickup_time_from set
        // 4. Don't already have an active pickup assignment request
        // 5. Don't have an assigned pickup delivery
        // 6. Haven't exceeded max retry attempts (max 2 expired requests)
        const eligibleOrders = await prisma.order.findMany({
            where: {
                order_status: 'placed',
                pickup_time_from: {
                    gt: now, // Only future orders (not expired)
                    not: null,
                },
                // Only orders that require pickup
                order_type: { in: ['pickup_only', 'both'] },
                // No pending assignment request
                deliveryAssignmentRequests: {
                    none: {
                        delivery_type: 'pickup',
                        status: 'pending',
                        expires_at: { gt: now },
                    },
                },
                // No assigned pickup delivery
                deliveries: {
                    none: {
                        delivery_type: 'pickup',
                        delivery_status: { in: ['assigned', 'en_route', 'reached'] },
                    },
                },
            },
            select: {
                order_id: true,
                pickup_time_from: true,
                order_type: true,
                _count: {
                    select: {
                        deliveryAssignmentRequests: {
                            where: {
                                delivery_type: 'pickup',
                                status: { in: ['pending', 'rejected', 'cancelled'] },
                                expires_at: { lt: now },
                            },
                        },
                    },
                },
            },
            take: getPickupAssignmentConfig().batchSize,
        });

        // Filter out orders that have exceeded max retry attempts (2 attempts)
        const MAX_ATTEMPTS = 2;
        const filteredOrders = eligibleOrders.filter((order) => order._count.deliveryAssignmentRequests < MAX_ATTEMPTS);

        if (filteredOrders.length === 0) {
            return;
        }

        logger.info('Catch-up job: Found orders eligible for pickup assignment (future scheduled only)', {
            component: 'pickup-assignment-catchup',
            count: filteredOrders.length,
            orderIds: filteredOrders.map((o) => o.order_id),
            note: 'Only re-queuing future scheduled jobs (not expired orders)',
        });

        // Re-queue each order (schedulePickupAssignment will handle idempotency)
        let requeued = 0;
        let failed = 0;

        for (const order of filteredOrders) {
            try {
                // Re-queue with delay 0 (run immediately)
                // schedulePickupAssignment will remove any existing job and add a new one
                await schedulePickupAssignment(order.order_id, order.pickup_time_from);
                requeued += 1;
            } catch (error) {
                logger.error('Catch-up job: Failed to re-queue order', {
                    component: 'pickup-assignment-catchup',
                    orderId: order.order_id,
                    error: error.message,
                });
                failed += 1;
            }
        }

        if (requeued > 0 || failed > 0) {
            logger.info('Catch-up job: Completed', {
                component: 'pickup-assignment-catchup',
                total: filteredOrders.length,
                requeued,
                failed,
            });
        }
    } catch (error) {
        logger.error('Catch-up job: Failed', {
            component: 'pickup-assignment-catchup',
            error: error.message,
            stack: error.stack,
        });
    }
};

/**
 * Schedule the catch-up job to run periodically.
 * Default: every 5 minutes (Redis Cloud free tier has no persistence; catch-up is the safety net).
 * Configurable via PICKUP_ASSIGNMENT_CATCHUP_INTERVAL_MS.
 */
const schedule = () => {
    if (jobIntervalHandle) {
        clearInterval(jobIntervalHandle);
    }

    // Default: 5 minutes (300000 ms) for Redis Cloud no-persistence; override via env
    const defaultIntervalMs = 300000;
    const intervalMs = parseInt(
        process.env.PICKUP_ASSIGNMENT_CATCHUP_INTERVAL_MS || String(defaultIntervalMs),
        10
    );

    // Run immediately on start, then schedule interval
    catchUpMissedPickupAssignments().catch((error) => {
        logger.error('Initial catch-up check failed', {
            component: 'pickup-assignment-catchup',
            error: error?.message || String(error),
        });
    });

    jobIntervalHandle = setInterval(() => {
        catchUpMissedPickupAssignments().catch((error) => {
            logger.error('Catch-up check failed', {
                component: 'pickup-assignment-catchup',
                error: error?.message || String(error),
            });
        });
    }, intervalMs);

    logger.info('Pickup assignment catch-up job scheduled', {
        component: 'pickup-assignment-catchup',
        intervalMs,
        intervalMinutes: Math.round(intervalMs / 60000),
    });
};

exports.startPickupAssignmentCatchupJob = () => {
    if (!isJobEnabled()) {
        logger.info('Pickup assignment catch-up job disabled', {
            component: 'pickup-assignment-catchup',
        });
        return;
    }

    schedule();
};

exports.stopPickupAssignmentCatchupJob = () => {
    if (jobIntervalHandle) {
        clearInterval(jobIntervalHandle);
        jobIntervalHandle = null;
        logger.info('Pickup assignment catch-up job stopped', {
            component: 'pickup-assignment-catchup',
        });
    }
};
