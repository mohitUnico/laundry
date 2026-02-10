let app;
let logger;
let prisma;
let startCleanupJob;
let startDailyMetricsJob;
let startPickupAssignmentJob;
let stopPickupAssignmentJob;

try {
    app = require('./app');
    logger = require('./utils/logger');
    prisma = require('./config/database');
    const portalAuth = require('./services/portal-auth.service');
    const dailyMetricsJob = require('./jobs/daily-metrics.job');
    const pickupJob = require('./jobs/pickup-assignment.job');
    startCleanupJob = portalAuth.startCleanupJob;
    startDailyMetricsJob = dailyMetricsJob.startDailyMetricsJob;
    startPickupAssignmentJob = pickupJob.startPickupAssignmentJob;
    stopPickupAssignmentJob = pickupJob.stopPickupAssignmentJob;
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
    stopPickupAssignmentJob();

    server.close(async () => {
        logger.info('✅ HTTP server closed');

        try {
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
        // Only start polling job if webhook-based assignment is disabled
        const useWebhookAssignment = process.env.USE_WEBHOOK_PICKUP_ASSIGNMENT === 'true';
        if (!useWebhookAssignment) {
            logger.info('📋 Starting pickup assignment polling job (webhook mode disabled)');
            startPickupAssignmentJob();
        } else {
            logger.info('🔗 Pickup assignment webhook mode enabled - polling job disabled');
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

