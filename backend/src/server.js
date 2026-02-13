let app;
let logger;
let prisma;
let startCleanupJob;
let startDailyMetricsJob;
let startPickupAssignmentJob;
let stopPickupAssignmentJob;
let startPickupAssignmentWorker;
let stopPickupAssignmentWorker;
let startPickupAssignmentCatchupJob;
let stopPickupAssignmentCatchupJob;
let closeRedisConnection;

try {
    app = require('./app');
    logger = require('./utils/logger');
    prisma = require('./config/database');
    const portalAuth = require('./services/portal-auth.service');
    const dailyMetricsJob = require('./jobs/daily-metrics.job');
    const pickupJob = require('./jobs/pickup-assignment.job');
    const pickupCatchupJob = require('./jobs/pickup-assignment-catchup.job');
    const pickupWorker = require('./workers/pickup-assignment.worker');
    const redis = require('./config/redis');
    startCleanupJob = portalAuth.startCleanupJob;
    startDailyMetricsJob = dailyMetricsJob.startDailyMetricsJob;
    startPickupAssignmentJob = pickupJob.startPickupAssignmentJob;
    stopPickupAssignmentJob = pickupJob.stopPickupAssignmentJob;
    startPickupAssignmentCatchupJob = pickupCatchupJob.startPickupAssignmentCatchupJob;
    stopPickupAssignmentCatchupJob = pickupCatchupJob.stopPickupAssignmentCatchupJob;
    startPickupAssignmentWorker = pickupWorker.startPickupAssignmentWorker;
    stopPickupAssignmentWorker = pickupWorker.stopPickupAssignmentWorker;
    closeRedisConnection = redis.closeRedisConnection;
} catch (err) {
    console.error('❌ Startup failed (require/load):', err);
    process.exit(1);
}

const PORT = process.env.PORT || 5000;

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('❌ Uncaught Exception:', error);
    if (logger && typeof logger.error === 'function') {
        logger.error('❌ Uncaught Exception:', error);
    }
    process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
    if (logger && typeof logger.error === 'function') {
        logger.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
    }
    process.exit(1);
});

// Graceful shutdown
const gracefulShutdown = async (signal) => {
    logger.info(`${signal} received. Starting graceful shutdown...`);
    
    // Stop pickup assignment job/worker based on mode
    const useQueueAssignment = process.env.PICKUP_ASSIGNMENT_USE_QUEUE === 'true';
    if (useQueueAssignment) {
        await stopPickupAssignmentWorker();
        stopPickupAssignmentCatchupJob();
    } else {
        stopPickupAssignmentJob();
    }

    server.close(async () => {
        logger.info('✅ HTTP server closed');

        try {
            // Close Redis connection if queue mode is enabled
            if (useQueueAssignment && closeRedisConnection) {
                await closeRedisConnection();
            }
            
            await prisma.$disconnect();
            logger.info('✅ Database connection closed');
            process.exit(0);
        } catch (error) {
            logger.error('❌ Error during shutdown:', error);
            process.exit(1);
        }
    });

    // Force shutdown after 10 seconds
    setTimeout(() => {
        logger.error('❌ Forced shutdown after timeout');
        process.exit(1);
    }, 10000);
};

// Start server
const server = app.listen(PORT, () => {
    try {
        logger.info(`🚀 Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
        logger.info(`📊 API: http://localhost:${PORT}/api/v1`);
        logger.info(`🏥 Health: http://localhost:${PORT}/health`);
        startCleanupJob();
        // Daily metrics job: set DAILY_METRICS_JOB_ENABLED=false to disable; set DAILY_METRICS_LOGS_ENABLED=false to disable only logs
        if (process.env.DAILY_METRICS_JOB_ENABLED !== 'false') {
            startDailyMetricsJob();
        }
        
        // Pickup assignment: choose between queue-based, webhook-based, or polling-based
        const useQueueAssignment = process.env.PICKUP_ASSIGNMENT_USE_QUEUE === 'true';
        const useWebhookAssignment = process.env.USE_WEBHOOK_PICKUP_ASSIGNMENT === 'true';
        
        if (useQueueAssignment) {
            // Queue-based assignment (BullMQ + Redis)
            try {
                startPickupAssignmentWorker();
                logger.info('✅ Pickup assignment worker started (queue-based mode)');
                
                // Start catch-up job as safety net (handles Redis data loss)
                startPickupAssignmentCatchupJob();
                logger.info('✅ Pickup assignment catch-up job started (safety net)');
            } catch (error) {
                logger.error('❌ Failed to start pickup assignment worker:', error);
                // Don't exit - app can still run without worker (jobs will queue but not process)
            }
        } else if (useWebhookAssignment) {
            // Webhook-based assignment (pg_cron + database triggers)
            logger.info('🔗 Pickup assignment webhook mode enabled - polling job disabled');
        } else {
            // Polling-based assignment (in-process setInterval)
            logger.info('📋 Starting pickup assignment polling job (polling mode)');
            startPickupAssignmentJob();
        }
    } catch (err) {
        logger.error('❌ Error during server startup (in listen callback):', err);
        process.exit(1);
    }
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        logger.error(`Port ${PORT} is already in use. Stop the process using it or set PORT to another value (e.g. in .env).`);
    } else {
        logger.error('❌ Server error:', err);
    }
    process.exit(1);
});

// Listen for termination signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

