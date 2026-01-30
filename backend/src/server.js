const app = require('./app');
const logger = require('./utils/logger');
const prisma = require('./config/database');
const { startCleanupJob } = require('./services/portal-auth.service');
const { startDailyMetricsJob } = require('./jobs/daily-metrics.job');
const { startPickupAssignmentJob } = require('./jobs/pickup-assignment.job');

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
    logger.info(`🚀 Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
    logger.info(`📊 API: http://localhost:${PORT}/api/v1`);
    logger.info(`🏥 Health: http://localhost:${PORT}/health`);
    startCleanupJob();
    startDailyMetricsJob();
    
    // Only start polling job if webhook-based assignment is disabled
    // When using database triggers/webhooks, the polling job is not needed
    const useWebhookAssignment = process.env.USE_WEBHOOK_PICKUP_ASSIGNMENT === 'true';
    if (!useWebhookAssignment) {
        logger.info('📋 Starting pickup assignment polling job (webhook mode disabled)');
        startPickupAssignmentJob();
    } else {
        logger.info('🔗 Pickup assignment webhook mode enabled - polling job disabled');
        logger.info('   Ensure database triggers and pg_cron are configured');
    }
});

// Listen for termination signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

