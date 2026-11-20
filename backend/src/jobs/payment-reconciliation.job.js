const logger = require('../utils/logger');
const checkout = require('../services/payments/checkout.service');

let intervalHandle = null;
let worker = null;
let queue = null;
let running = false;

function enabled() {
    if (process.env.NODE_ENV === 'test') return false;
    return process.env.PAYMENT_RECONCILIATION_ENABLED !== 'false';
}

function intervalMs() {
    const minutes = Number(process.env.PAYMENT_RECONCILIATION_INTERVAL_MINUTES || 5);
    const safe = Number.isFinite(minutes) && minutes > 0 ? minutes : 5;
    return safe * 60 * 1000;
}

async function runOnce() {
    if (running) return;
    running = true;
    try {
        await checkout.reconcilePendingPayments();
    } finally {
        running = false;
    }
}

function startInProcess(reason) {
    if (intervalHandle) return;
    logger.warn('Payment reconciliation is using the in-process scheduler', { reason });
    intervalHandle = setInterval(() => {
        runOnce().catch((error) => {
            logger.error('Payment reconciliation failed', { error: error.message });
        });
    }, intervalMs());
    if (typeof intervalHandle.unref === 'function') intervalHandle.unref();
    runOnce().catch((error) => {
        logger.error('Payment reconciliation failed', { error: error.message });
    });
}

async function startPaymentReconciliationJob() {
    if (!enabled()) {
        if (process.env.PAYMENT_RECONCILIATION_ENABLED === 'false') {
            logger.warn('Payment reconciliation is off because PAYMENT_RECONCILIATION_ENABLED=false');
        }
        return;
    }
    try {
        const { Queue, Worker } = require('bullmq');
        const { getRedisConnection, getRedisWorkerConnection } = require('../config/redis');
        queue = new Queue('payment-reconciliation', { connection: getRedisConnection() });
        await Promise.race([
            (async () => {
                const existing = await queue.getRepeatableJobs();
                for (const job of existing) {
                    await queue.removeRepeatableByKey(job.key);
                }
                await queue.add('reconcile', {}, { repeat: { every: intervalMs() }, removeOnComplete: 20 });
            })(),
            new Promise((_, reject) => {
                setTimeout(() => reject(new Error('Redis did not accept the reconciliation job within 3 seconds')), 3000);
            }),
        ]);
        worker = new Worker('payment-reconciliation', async () => runOnce(), {
            connection: getRedisWorkerConnection(),
        });
        worker.on('failed', (job, error) => {
            logger.error('Payment reconciliation job failed', { error: error.message });
        });
        logger.info('Payment reconciliation queue started', { intervalMs: intervalMs() });
        runOnce().catch((error) => logger.error('Payment reconciliation failed', { error: error.message }));
    } catch (error) {
        startInProcess(error.message);
    }
}

async function stopPaymentReconciliationJob() {
    if (intervalHandle) {
        clearInterval(intervalHandle);
        intervalHandle = null;
    }
    if (worker) {
        await worker.close().catch(() => {});
        worker = null;
    }
    if (queue) {
        await queue.close().catch(() => {});
        queue = null;
    }
}

module.exports = {
    startPaymentReconciliationJob,
    stopPaymentReconciliationJob,
    runPaymentReconciliation: runOnce,
};
