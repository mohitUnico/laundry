const { Worker } = require('bullmq');
const { getRedisWorkerConnection } = require('../config/redis');
const deliveryOperationsService = require('../services/delivery-operations.service');
const { getPickupAssignmentConfig } = require('../config/delivery-assignment.config');
const prisma = require('../config/database');
const logger = require('../utils/logger');

let worker = null;

/**
 * Process pickup assignment job
 * @param {object} job - BullMQ job object
 */
async function processPickupAssignment(job) {
    const { orderId, deliveryType = 'pickup' } = job.data;

    logger.info('Processing pickup assignment job', {
        component: 'pickup-assignment-worker',
        orderId,
        jobId: job.id,
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

        // Create assignment request (same logic as current polling job)
        const config = getPickupAssignmentConfig();
        const result = await deliveryOperationsService.createAssignmentRequest({
            orderId,
            deliveryType,
            sendToAll: config.sendToAll,
            limit: config.maxStaffLimit,
            expiresInSeconds: config.expirySeconds,
        });

        logger.info('Pickup assignment request created via queue', {
            component: 'pickup-assignment-worker',
            orderId,
            requestId: result.request?.request_id,
            recipientCount: result.recipients?.length || 0,
        });

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
