const { Redis } = require('ioredis');
const logger = require('../utils/logger');

let redisClient = null;

/**
 * Get or create Redis connection for BullMQ.
 * Configured for Redis Cloud (no persistence): reconnects and retries on failure.
 * @returns {Redis} Redis client instance
 */
function getRedisConnection() {
    if (redisClient) {
        return redisClient;
    }

    const redisUrl = process.env.REDIS_URL;
    
    if (!redisUrl) {
        throw new Error('REDIS_URL environment variable is required (e.g. Redis Cloud connection string)');
    }

    // Redis Cloud (no persistence): retry and reconnect on connection loss
    const connectionOptions = {
        maxRetriesPerRequest: 3,
        retryStrategy: (times) => {
            const delay = Math.min(times * 100, 5000);
            logger.info('Redis retry', { component: 'redis', attempt: times, delayMs: delay });
            return delay;
        },
        reconnectOnError: (err) => {
            const targetError = 'READONLY';
            if (err.message.includes(targetError)) {
                return true;
            }
            return false;
        },
        enableReadyCheck: true,
        enableOfflineQueue: true,
        connectTimeout: 10000,
        lazyConnect: false,
    };

    redisClient = new Redis(redisUrl, connectionOptions);

    redisClient.on('connect', () => {
        logger.info('Redis connected', { component: 'redis' });
    });

    redisClient.on('ready', () => {
        logger.info('Redis ready', { component: 'redis' });
    });

    redisClient.on('error', (err) => {
        logger.error('Redis connection error', { 
            component: 'redis', 
            error: err.message,
            stack: err.stack,
        });
    });

    redisClient.on('close', () => {
        logger.warn('Redis connection closed', { component: 'redis' });
    });

    redisClient.on('reconnecting', () => {
        logger.info('Redis reconnecting', { component: 'redis' });
    });

    return redisClient;
}

/**
 * Close Redis connection gracefully
 */
async function closeRedisConnection() {
    if (redisClient) {
        try {
            await redisClient.quit();
            redisClient = null;
            logger.info('Redis connection closed gracefully', { component: 'redis' });
        } catch (error) {
            logger.error('Error closing Redis connection', {
                component: 'redis',
                error: error.message,
            });
            redisClient = null;
        }
    }
}

module.exports = {
    getRedisConnection,
    closeRedisConnection,
};
