const { Queue } = require('bullmq');
const { getRedisConnection } = require('../../config/redis');
const logger = require('../../utils/logger');

let queue;

function getQueue() {
    if (!queue) {
        queue = new Queue('delivery-assignment', {
            connection: getRedisConnection(),
            defaultJobOptions: {
                attempts: 3,
                removeOnComplete: { age: 12 * 3600, count: 500 },
                removeOnFail: { age: 3 * 24 * 3600 },
            },
        });
    }
    return queue;
}

async function scheduleSearchJobs({ requestId, sliceCount, timeoutMs, startedAt }) {
    const q = getQueue();
    const sliceMs = timeoutMs / sliceCount;
    const start = startedAt instanceof Date ? startedAt.getTime() : Date.now();
    for (let i = 2; i <= sliceCount; i += 1) {
        const delay = Math.max(0, start + (i - 1) * sliceMs - Date.now());
        await q.add(
            'slice',
            { requestId, sliceIndex: i },
            { jobId: `assign:${requestId}:slice:${i}`, delay }
        );
    }
    const timeoutDelay = Math.max(0, start + timeoutMs - Date.now());
    await q.add(
        'timeout',
        { requestId },
        { jobId: `assign:${requestId}:timeout`, delay: timeoutDelay }
    );
    logger.info('Scheduled assignment slice jobs', { requestId, sliceCount });
}

async function scheduleDelayedStart({ orderId, deliveryType, runAt }) {
    const q = getQueue();
    const when = runAt instanceof Date ? runAt.getTime() : new Date(runAt).getTime();
    const delay = Math.max(0, when - Date.now());
    const jobId = `assign-start:${orderId}:${deliveryType}`;
    const existing = await q.getJob(jobId);
    if (existing) await existing.remove();
    await q.add('start', { orderId, deliveryType }, { jobId, delay });
}

async function removeSearchJobs(requestId) {
    const q = getQueue();
    const jobs = await q.getJobs(['delayed', 'waiting']);
    for (const job of jobs) {
        if (job && String(job.id || '').startsWith(`assign:${requestId}:`)) {
            await job.remove();
        }
    }
}

module.exports = {
    getQueue,
    scheduleSearchJobs,
    scheduleDelayedStart,
    removeSearchJobs,
};
