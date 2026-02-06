const logger = require('../utils/logger');
const prisma = require('../config/database');
const deliveryOperationsService = require('../services/delivery-operations.service');
const { getPickupAssignmentConfig } = require('../config/delivery-assignment.config');

let jobIntervalHandle = null;

const isJobEnabled = () => {
    if (process.env.NODE_ENV === 'test') return false;
    if (process.env.PICKUP_ASSIGNMENT_JOB_ENABLED === 'false') return false;
    return true;
};

/**
 * Check for orders that have reached their preferred pickup time
 * and create assignment requests for pickup if not already assigned.
 * This is the automatic counterpart to POST /api/v1/admin/delivery-ops/assignment-requests:
 * it finds eligible orders and triggers the same createAssignmentRequest flow, which broadcasts
 * SSE events (and FCM) to all active delivery staff.
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
            take: getPickupAssignmentConfig().batchSize, // Process in batches (configurable)
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
                    // Get configuration from config module (allows easy adjustment via env vars)
                    const config = getPickupAssignmentConfig();

                    const result = await deliveryOperationsService.createAssignmentRequest({
                        orderId: order.order_id,
                        deliveryType: 'pickup',
                        sendToAll: config.sendToAll, // Configurable: send to all or use distance-based filtering
                        limit: config.maxStaffLimit, // Maximum number of staff to notify (configurable)
                        expiresInSeconds: config.expirySeconds, // Request expiry time (configurable)
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

    // Get configurable interval from config module
    const config = getPickupAssignmentConfig();
    const intervalMs = config.jobIntervalMs; // Configurable interval (default: 1 minute)

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
        config: {
            sendToAll: config.sendToAll,
            maxStaffLimit: config.maxStaffLimit,
            expirySeconds: config.expirySeconds,
            batchSize: config.batchSize,
        },
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
