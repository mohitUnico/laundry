const logger = require('../utils/logger');
const prisma = require('../config/database');
const deliveryOperationsService = require('../services/delivery-operations.service');

let jobIntervalHandle = null;

const isJobEnabled = () => {
    if (process.env.NODE_ENV === 'test') return false;
    if (process.env.PICKUP_ASSIGNMENT_JOB_ENABLED === 'false') return false;
    return true;
};

/**
 * Check for orders that have reached their preferred pickup time
 * and create assignment requests for pickup if not already assigned
 */
const checkAndCreatePickupAssignments = async () => {
    try {
        const now = new Date();

        // Find orders that:
        // 1. Have reached their preferred pickup time (pickup_time_from <= now)
        // 2. Are in 'placed' status (not yet assigned for pickup)
        // 3. Have pickup_time_from set (not null)
        // 4. Don't already have an active pickup assignment request
        const ordersReadyForPickup = await prisma.order.findMany({
            where: {
                order_status: 'placed',
                pickup_time_from: {
                    lte: now,
                    not: null,
                },
                // Ensure no active pickup assignment request exists
                deliveryAssignmentRequests: {
                    none: {
                        delivery_type: 'pickup',
                        status: 'pending',
                        expires_at: { gt: now },
                    },
                },
                // Ensure no pickup delivery is already assigned
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
                pickup_time_to: true,
            },
            take: 50, // Process in batches
        });

        if (ordersReadyForPickup.length === 0) {
            return;
        }

        logger.info('Found orders ready for pickup assignment', {
            count: ordersReadyForPickup.length,
            orderIds: ordersReadyForPickup.map((o) => o.order_id),
        });

        // Create assignment requests for each order
        const results = await Promise.allSettled(
            ordersReadyForPickup.map(async (order) => {
                try {
                    const result = await deliveryOperationsService.createAssignmentRequest({
                        orderId: order.order_id,
                        deliveryType: 'pickup',
                        radiusKm: 5, // Default radius
                        limit: 10, // Default limit for nearby staff
                        expiresInSeconds: 120, // Default expiry
                    });

                    logger.info('Pickup assignment request created', {
                        orderId: order.order_id,
                        requestId: result.request?.request_id,
                        recipientCount: result.recipients?.length || 0,
                    });

                    return { orderId: order.order_id, success: true, result };
                } catch (error) {
                    logger.error('Failed to create pickup assignment request', {
                        orderId: order.order_id,
                        error: error?.message || String(error),
                    });
                    return { orderId: order.order_id, success: false, error: error?.message };
                }
            })
        );

        const successful = results.filter((r) => r.status === 'fulfilled' && r.value.success).length;
        const failed = results.length - successful;

        if (successful > 0 || failed > 0) {
            logger.info('Pickup assignment job completed', {
                total: ordersReadyForPickup.length,
                successful,
                failed,
            });
        }
    } catch (error) {
        logger.error('Pickup assignment job failed', {
            error: error?.message || String(error),
            stack: error?.stack,
        });
    }
};

/**
 * Schedule the pickup assignment job to run every minute
 */
const schedule = () => {
    if (jobIntervalHandle) {
        clearInterval(jobIntervalHandle);
    }

    // Run every minute to check for orders ready for pickup
    const intervalMs = 60 * 1000; // 1 minute

    // Run immediately on start, then schedule interval
    checkAndCreatePickupAssignments().catch((error) => {
        logger.error('Initial pickup assignment check failed', {
            error: error?.message || String(error),
        });
    });

    jobIntervalHandle = setInterval(() => {
        checkAndCreatePickupAssignments().catch((error) => {
            logger.error('Pickup assignment check failed', {
                error: error?.message || String(error),
            });
        });
    }, intervalMs);

    logger.info('Pickup assignment job scheduled', {
        intervalMs,
        nextRunInMs: intervalMs,
    });
};

exports.startPickupAssignmentJob = () => {
    if (!isJobEnabled()) {
        logger.info('Pickup assignment job disabled');
        return;
    }

    schedule();
};

exports.stopPickupAssignmentJob = () => {
    if (jobIntervalHandle) {
        clearInterval(jobIntervalHandle);
        jobIntervalHandle = null;
        logger.info('Pickup assignment job stopped');
    }
};
