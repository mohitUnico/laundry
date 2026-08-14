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

const isDebugLogging = () => process.env.PICKUP_ASSIGNMENT_DEBUG === 'true';

/**
 * Run the same query as the job to find orders eligible for pickup assignment.
 * Used for debugging and by GET /admin/delivery-ops/pickup-assignment-status.
 */
const getEligibleOrdersQuery = () => {
    const now = new Date();
    return prisma.order.findMany({
        where: {
            order_status: 'placed',
            pickup_time_from: {
                lte: now,
                not: null,
            },
            deliveryAssignmentRequests: {
                none: {
                    delivery_type: 'pickup',
                    status: 'pending',
                    expires_at: { gt: now },
                },
            },
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
        take: getPickupAssignmentConfig().batchSize,
    });
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
        const ordersReadyForPickup = await getEligibleOrdersQuery();

        if (isDebugLogging()) {
            logger.info('Pickup assignment job tick', {
                component: 'pickup-assignment-job',
                eligibleCount: ordersReadyForPickup.length,
                orderIds: ordersReadyForPickup.map((o) => o.order_id),
            });
        }

        if (ordersReadyForPickup.length === 0) {
            return;
        }

        logger.info('Found orders ready for pickup assignment', {
            component: 'pickup-assignment-job',
            count: ordersReadyForPickup.length,
            orderIds: ordersReadyForPickup.map((o) => o.order_id),
        });

        // Process orders sequentially to avoid transaction timeouts and DB contention.
        // Each createAssignmentRequest runs a long Prisma transaction; parallel runs exhaust the pool and exceed the default 5s timeout.
        const config = getPickupAssignmentConfig();
        let successful = 0;
        let failed = 0;

        for (const order of ordersReadyForPickup) {
            try {
                const result = await deliveryOperationsService.createAssignmentRequest({
                    orderId: order.order_id,
                    deliveryType: 'pickup',
                    sendToAll: config.sendToAll,
                    limit: config.maxStaffLimit,
                    expiresInSeconds: config.expirySeconds,
                });

                logger.info('Pickup assignment request created', {
                    component: 'pickup-assignment-job',
                    orderId: order.order_id,
                    requestId: result.request?.request_id,
                    recipientCount: result.recipients?.length || 0,
                });
                successful += 1;
            } catch (error) {
                logger.error('Failed to create pickup assignment request', {
                    component: 'pickup-assignment-job',
                    orderId: order.order_id,
                    error: error?.message || String(error),
                });
                failed += 1;
            }
        }

        if (successful > 0 || failed > 0) {
            logger.info('Pickup assignment job completed', {
                component: 'pickup-assignment-job',
                total: ordersReadyForPickup.length,
                successful,
                failed,
            });
        }
    } catch (error) {
        logger.error('Pickup assignment job failed', {
            component: 'pickup-assignment-job',
            error: error?.message || String(error),
            stack: error?.stack,
        });
    }
};

/**
 * Schedule the pickup assignment job to run at the configured interval (default: 2 minutes).
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
            component: 'pickup-assignment-job',
            error: error?.message || String(error),
        });
    });

    jobIntervalHandle = setInterval(() => {
        checkAndCreatePickupAssignments().catch((error) => {
            logger.error('Pickup assignment check failed', {
                component: 'pickup-assignment-job',
                error: error?.message || String(error),
            });
        });
    }, intervalMs);

    logger.info('Pickup assignment job scheduled', {
        component: 'pickup-assignment-job',
        intervalMs,
        nextRunInMs: intervalMs,
        config: {
            sendToAll: config.sendToAll,
            maxStaffLimit: config.maxStaffLimit,
            expirySeconds: config.expirySeconds,
            batchSize: config.batchSize,
        },
        debugHint: 'Set PICKUP_ASSIGNMENT_DEBUG=true to log every run (eligible order count).',
    });
};

exports.startPickupAssignmentJob = () => {
    if (!isJobEnabled()) {
        logger.info('Pickup assignment job disabled', { component: 'pickup-assignment-job' });
        return;
    }

    schedule();
};

exports.stopPickupAssignmentJob = () => {
    if (jobIntervalHandle) {
        clearInterval(jobIntervalHandle);
        jobIntervalHandle = null;
        logger.info('Pickup assignment job stopped', { component: 'pickup-assignment-job' });
    }
};

/**
 * For debugging: return job status and current eligible orders (same query as the job).
 * GET /api/v1/admin/delivery-ops/pickup-assignment-status uses this.
 */
exports.getPickupAssignmentStatus = async () => {
    const config = getPickupAssignmentConfig();
    const eligibleOrders = await getEligibleOrdersQuery();
    return {
        jobEnabled: isJobEnabled(),
        webhookMode: process.env.USE_WEBHOOK_PICKUP_ASSIGNMENT === 'true',
        pollingActive: jobIntervalHandle != null,
        intervalMs: config.jobIntervalMs,
        eligibleOrderCount: eligibleOrders.length,
        eligibleOrderIds: eligibleOrders.map((o) => o.order_id),
        criteria: 'order_status=placed, pickup_time_from <= now, no pending pickup request, no assigned pickup delivery',
    };
};
