let app;
let logger;
let prisma;
let startCleanupJob;
let startDailyMetricsJob;
let startPickupAssignmentWorker;
let stopPickupAssignmentWorker;
let startPickupAssignmentCatchupJob;
let stopPickupAssignmentCatchupJob;
let closeRedisConnection;

try {
    app = require('./app');
    logger = require('./utils/logger');
    // Ensure startup logs appear on console when log filter is active
    if (process.env.LOG_COMPONENTS || process.env.LOG_ONLY_PICKUP_ASSIGNMENT === 'true') {
        console.log('[server] App and logger loaded (console filtered; see logs/combined.log for full output)');
    }
    prisma = require('./config/database');
    const portalAuth = require('./services/portal-auth.service');
    const dailyMetricsJob = require('./jobs/daily-metrics.job');
    const pickupCatchupJob = require('./services/assignment/assignment-catchup.job');
    const pickupWorker = require('./services/assignment/assignment.worker');
    const redis = require('./config/redis');
    startCleanupJob = portalAuth.startCleanupJob;
    startDailyMetricsJob = dailyMetricsJob.startDailyMetricsJob;
    startPickupAssignmentCatchupJob = pickupCatchupJob.startAssignmentCatchupJob;
    stopPickupAssignmentCatchupJob = pickupCatchupJob.stopAssignmentCatchupJob;
    startPickupAssignmentWorker = pickupWorker.startAssignmentWorker;
    stopPickupAssignmentWorker = pickupWorker.stopAssignmentWorker;
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
    
    await stopPickupAssignmentWorker();
    stopPickupAssignmentCatchupJob();

    server.close(async () => {
        logger.info('✅ HTTP server closed');

        try {
            if (closeRedisConnection) {
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
        
        try {
            startPickupAssignmentWorker();
            startPickupAssignmentCatchupJob();
            logger.info('Assignment worker and catch-up job started');
        } catch (error) {
            logger.error('Failed to start assignment worker', { error: error.message });
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

