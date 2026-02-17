const { Queue } = require('bullmq');
const { getRedisConnection } = require('../config/redis');
const logger = require('../utils/logger');

/**
 * Pickup assignment queue. Optimized for Redis Cloud (no persistence):
 * - Catch-up job re-queues eligible orders every 5 min as the safety net.
 * - Aggressive cleanup to stay within free tier memory (~30MB).
 */
const pickupAssignmentQueue = new Queue('pickup-assignment', {
    connection: getRedisConnection(),
    defaultJobOptions: {
        attempts: 3,
        backoff: {
            type: 'exponential',
            delay: 2000, // 2s, 4s, 8s
        },
        // Redis Cloud free tier: no persistence; keep less history to save memory
        removeOnComplete: {
            age: 12 * 3600, // 12 hours
            count: 500,
        },
        removeOnFail: {
            age: 3 * 24 * 3600, // 3 days
        },
    },
});

/**
 * Schedule pickup assignment job for an order
 * @param {string} orderId - Order ID
 * @param {Date|string} pickupTimeFrom - Pickup time (Date object or ISO string)
 * @param {boolean} [isRetry=false] - Whether this is a retry attempt
 * @returns {Promise<string>} Job ID
 */
async function schedulePickupAssignment(orderId, pickupTimeFrom, isRetry = false) {
    try {
        const pickupTime = typeof pickupTimeFrom === 'string' 
            ? new Date(pickupTimeFrom) 
            : pickupTimeFrom;

        if (!pickupTime || isNaN(pickupTime.getTime())) {
            throw new Error(`Invalid pickup time: ${pickupTimeFrom}`);
        }

        const now = new Date();
        const runAt = pickupTime.getTime();
        const delay = Math.max(0, runAt - now.getTime());

        // Use orderId as jobId to ensure one job per order
        // This allows us to remove/replace jobs when pickup time changes
        const jobId = `pickup-assignment-${orderId}`;

        // Remove existing job for this order (if pickup time was changed)
        const existingJob = await pickupAssignmentQueue.getJob(jobId);
        if (existingJob) {
            await existingJob.remove();
            logger.info('Removed existing pickup assignment job', {
                component: 'pickup-assignment-queue',
                orderId,
                jobId,
            });
        }

        // Add new job
        const job = await pickupAssignmentQueue.add(
            'process-pickup-assignment',
            {
                orderId,
                deliveryType: 'pickup',
                isRetry, // Mark as retry if this is a retry attempt
            },
            {
                jobId,
                delay, // Delay in milliseconds
            }
        );

        logger.info('Scheduled pickup assignment job', {
            component: 'pickup-assignment-queue',
            orderId,
            jobId: job.id,
            runAt: pickupTime.toISOString(),
            delayMs: delay,
        });

        return job.id;
    } catch (error) {
        logger.error('Failed to schedule pickup assignment job', {
            component: 'pickup-assignment-queue',
            orderId,
            error: error.message,
            stack: error.stack,
        });
        throw error;
    }
}

/**
 * Remove scheduled pickup assignment job for an order
 * @param {string} orderId - Order ID
 */
async function cancelPickupAssignment(orderId) {
    try {
        const jobId = `pickup-assignment-${orderId}`;
        const job = await pickupAssignmentQueue.getJob(jobId);
        
        if (job) {
            await job.remove();
            logger.info('Cancelled pickup assignment job', {
                component: 'pickup-assignment-queue',
                orderId,
                jobId,
            });
        }
    } catch (error) {
        logger.error('Failed to cancel pickup assignment job', {
            component: 'pickup-assignment-queue',
            orderId,
            error: error.message,
        });
    }
}

/**
 * Get queue statistics
 * @returns {Promise<object>} Queue stats
 */
async function getQueueStats() {
    try {
        const [waiting, active, completed, failed, delayed] = await Promise.all([
            pickupAssignmentQueue.getWaitingCount(),
            pickupAssignmentQueue.getActiveCount(),
            pickupAssignmentQueue.getCompletedCount(),
            pickupAssignmentQueue.getFailedCount(),
            pickupAssignmentQueue.getDelayedCount(),
        ]);

        return {
            waiting,
            active,
            completed,
            failed,
            delayed,
        };
    } catch (error) {
        logger.error('Failed to get queue stats', {
            component: 'pickup-assignment-queue',
            error: error.message,
        });
        throw error;
    }
}

module.exports = {
    pickupAssignmentQueue,
    schedulePickupAssignment,
    cancelPickupAssignment,
    getQueueStats,
};
