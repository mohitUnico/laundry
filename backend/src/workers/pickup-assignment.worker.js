const { Worker } = require('bullmq');
const { getRedisWorkerConnection } = require('../config/redis');
const deliveryOperationsService = require('../services/delivery-operations.service');
const { getPickupAssignmentConfig } = require('../config/delivery-assignment.config');
const { schedulePickupAssignment } = require('../queues/pickup-assignment.queue');
const prisma = require('../config/database');
const logger = require('../utils/logger');

let worker = null;

/**
 * Count how many expired assignment requests exist for an order (retry attempts)
 * @param {string} orderId - Order ID
 * @returns {Promise<number>} Number of expired assignment requests
 */
async function getRetryAttemptCount(orderId) {
    const now = new Date();
    const count = await prisma.deliveryAssignmentRequest.count({
        where: {
            order_id: orderId,
            delivery_type: 'pickup',
            status: { in: ['pending', 'rejected', 'cancelled'] },
            expires_at: { lt: now },
        },
    });
    return count;
}

/**
 * Process pickup assignment job
 * @param {object} job - BullMQ job object
 */
async function processPickupAssignment(job) {
    const { orderId, deliveryType = 'pickup', isRetry = false } = job.data;

    logger.info('Processing pickup assignment job', {
        component: 'pickup-assignment-worker',
        orderId,
        jobId: job.id,
        isRetry,
    });

    try {
        // Re-check eligibility before processing
        const order = await prisma.order.findUnique({
            where: { order_id: orderId },
            select: {
                order_id: true,
                order_status: true,
                pickup_time_from: true,
                deliveryAssignmentRequests: {
                    where: {
                        delivery_type: 'pickup',
                        status: 'pending',
                        expires_at: { gt: new Date() },
                    },
                    take: 1,
                },
                deliveries: {
                    where: {
                        delivery_type: 'pickup',
                        delivery_status: { in: ['assigned', 'en_route', 'reached'] },
                    },
                    take: 1,
                },
            },
        });

        // Check if order is still eligible
        if (!order) {
            logger.warn('Order not found, skipping pickup assignment', {
                component: 'pickup-assignment-worker',
                orderId,
            });
            return; // Job completed (not an error - order may have been deleted)
        }

        if (order.order_status !== 'placed') {
            logger.warn('Order not in placed status, skipping pickup assignment', {
                component: 'pickup-assignment-worker',
                orderId,
                orderStatus: order.order_status,
            });
            return; // Job completed (order already processed or cancelled)
        }

        if (order.deliveryAssignmentRequests.length > 0) {
            logger.warn('Order already has pending pickup assignment request', {
                component: 'pickup-assignment-worker',
                orderId,
            });
            return; // Job completed (already has pending request)
        }

        if (order.deliveries.length > 0) {
            logger.warn('Order already has assigned pickup delivery', {
                component: 'pickup-assignment-worker',
                orderId,
            });
            return; // Job completed (already assigned)
        }

        // Check retry attempt count (max 2 attempts total)
        const retryCount = await getRetryAttemptCount(orderId);
        const MAX_ATTEMPTS = 2;

        if (retryCount >= MAX_ATTEMPTS) {
            logger.warn('Maximum pickup assignment attempts reached, stopping retries', {
                component: 'pickup-assignment-worker',
                orderId,
                retryCount,
                maxAttempts: MAX_ATTEMPTS,
            });
            return; // Job completed (max attempts reached)
        }

        // Create assignment request
        const config = getPickupAssignmentConfig();
        const result = await deliveryOperationsService.createAssignmentRequest({
            orderId,
            deliveryType,
            sendToAll: config.sendToAll,
            limit: config.maxStaffLimit,
            expiresInSeconds: config.expirySeconds,
        });

        const attemptNumber = retryCount + 1;
        logger.info('Pickup assignment request created via queue', {
            component: 'pickup-assignment-worker',
            orderId,
            requestId: result.request?.request_id,
            recipientCount: result.recipients?.length || 0,
            attemptNumber,
            maxAttempts: MAX_ATTEMPTS,
        });

        // If this is the first attempt, schedule a retry job 2 minutes after expiry
        if (attemptNumber === 1 && result.request?.expires_at) {
            const expiryTime = new Date(result.request.expires_at);
            const retryTime = new Date(expiryTime.getTime() + 2 * 60 * 1000); // 2 minutes after expiry

            try {
                await schedulePickupAssignment(orderId, retryTime, true); // Mark as retry
                logger.info('Scheduled retry job for pickup assignment', {
                    component: 'pickup-assignment-worker',
                    orderId,
                    retryTime: retryTime.toISOString(),
                    attemptNumber: 2,
                });
            } catch (retryError) {
                logger.error('Failed to schedule retry job', {
                    component: 'pickup-assignment-worker',
                    orderId,
                    error: retryError.message,
                });
                // Don't fail the main job if retry scheduling fails
            }
        }

        return result;
    } catch (error) {
        logger.error('Failed to process pickup assignment job', {
            component: 'pickup-assignment-worker',
            orderId,
            error: error.message,
            stack: error.stack,
        });
        throw error; // Let BullMQ retry
    }
}

/**
 * Start pickup assignment worker
 */
function startPickupAssignmentWorker() {
    if (worker) {
        logger.warn('Pickup assignment worker already started', {
            component: 'pickup-assignment-worker',
        });
        return worker;
    }

    worker = new Worker(
        'pickup-assignment',
        async (job) => {
            return await processPickupAssignment(job);
        },
        {
            connection: getRedisWorkerConnection(),
            concurrency: 1, // Process one job at a time (adjust if needed)
            limiter: {
                max: 10, // Max 10 jobs per second
                duration: 1000,
            },
        }
    );

    worker.on('completed', (job) => {
        logger.info('Pickup assignment job completed', {
            component: 'pickup-assignment-worker',
            orderId: job.data.orderId,
            jobId: job.id,
        });
    });

    worker.on('failed', (job, err) => {
        logger.error('Pickup assignment job failed', {
            component: 'pickup-assignment-worker',
            orderId: job?.data?.orderId,
            jobId: job?.id,
            error: err.message,
            attemptsMade: job?.attemptsMade,
        });
    });

    worker.on('error', (err) => {
        logger.error('Pickup assignment worker error', {
            component: 'pickup-assignment-worker',
            error: err.message,
            stack: err.stack,
        });
    });

    logger.info('Pickup assignment worker started', {
        component: 'pickup-assignment-worker',
        queue: 'pickup-assignment',
    });

    return worker;
}

/**
 * Stop pickup assignment worker
 */
async function stopPickupAssignmentWorker() {
    if (worker) {
        await worker.close();
        worker = null;
        logger.info('Pickup assignment worker stopped', {
            component: 'pickup-assignment-worker',
        });
    }
}

module.exports = {
    startPickupAssignmentWorker,
    stopPickupAssignmentWorker,
};
