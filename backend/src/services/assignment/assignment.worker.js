const { Worker } = require('bullmq');
const { getRedisConnection } = require('../../config/redis');
const logger = require('../../utils/logger');
const engine = require('./assignment-engine.service');

let worker;

function startAssignmentWorker() {
    if (worker) return worker;
    worker = new Worker(
        'delivery-assignment',
        async (job) => {
            if (job.name === 'start') {
                await engine.startSearch({
                    orderId: job.data.orderId,
                    deliveryType: job.data.deliveryType,
                });
                return;
            }
            if (job.name === 'slice') {
                await engine.advanceSlice(job.data.requestId, { sliceIndex: job.data.sliceIndex });
                return;
            }
            if (job.name === 'timeout') {
                await engine.finishTimeout(job.data.requestId);
            }
        },
        { connection: getRedisConnection() }
    );
    worker.on('failed', (job, err) => {
        logger.error('Assignment job failed', { jobId: job?.id, error: err.message });
    });
    return worker;
}

async function stopAssignmentWorker() {
    if (worker) {
        await worker.close();
        worker = null;
    }
}

module.exports = {
    startAssignmentWorker,
    stopAssignmentWorker,
};
