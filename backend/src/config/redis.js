const { Redis } = require('ioredis');
const logger = require('../utils/logger');

let redisClient = null;
let redisWorkerClient = null;

const BASE_OPTIONS = {
    retryStrategy: (times) => {
        const delay = Math.min(times * 100, 5000);
        logger.info('Redis retry', { component: 'redis', attempt: times, delayMs: delay });
        return delay;
    },
    reconnectOnError: (err) => {
        if (err.message.includes('READONLY')) return true;
        return false;
    },
    enableReadyCheck: true,
    enableOfflineQueue: true,
    connectTimeout: 10000,
    lazyConnect: false,
};

function createRedisClient(maxRetriesPerRequest) {
    const redisUrl = process.env.REDIS_URL;
    if (!redisUrl) {
        throw new Error('REDIS_URL environment variable is required (e.g. Redis Cloud connection string)');
    }
    const client = new Redis(redisUrl, { ...BASE_OPTIONS, maxRetriesPerRequest });
    client.on('connect', () => logger.info('Redis connected', { component: 'redis' }));
    client.on('ready', () => logger.info('Redis ready', { component: 'redis' }));
    client.on('error', (err) => logger.error('Redis connection error', { component: 'redis', error: err.message, stack: err.stack }));
    client.on('close', () => logger.warn('Redis connection closed', { component: 'redis' }));
    client.on('reconnecting', () => logger.info('Redis reconnecting', { component: 'redis' }));
    return client;
}

/**
 * Get or create Redis connection for BullMQ Queue (add job, get job, etc.).
 * @returns {Redis} Redis client instance
 */
function getRedisConnection() {
    if (redisClient) return redisClient;
    redisClient = createRedisClient(3);
    return redisClient;
}

/**
 * Get or create Redis connection for BullMQ Worker (blocking commands).
 * Must use maxRetriesPerRequest: null or Worker.run() throws "reading 'client'".
 * @returns {Redis} Redis client instance for worker use only
 */
function getRedisWorkerConnection() {
    if (redisWorkerClient) return redisWorkerClient;
    redisWorkerClient = createRedisClient(null);
    return redisWorkerClient;
}

/**
 * Close Redis connections gracefully
 */
async function closeRedisConnection() {
    const close = async (client, name) => {
        if (!client) return;
        try {
            await client.quit();
            logger.info('Redis connection closed gracefully', { component: 'redis', connection: name });
        } catch (error) {
            logger.error('Error closing Redis connection', { component: 'redis', connection: name, error: error.message });
        }
    };
    await close(redisWorkerClient, 'worker');
    redisWorkerClient = null;
    await close(redisClient, 'queue');
    redisClient = null;
}

module.exports = {
    getRedisConnection,
    getRedisWorkerConnection,
    closeRedisConnection,
};
