import app from './app.js'
import { logger } from './utils/logger.js'
import { prisma } from './config/database.js'

const PORT = process.env.PORT || 5000

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error)
    process.exit(1)
})

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', promise, 'reason:', reason)
    process.exit(1)
})

// Graceful shutdown
const gracefulShutdown = async (signal) => {
    logger.info(`${signal} received. Starting graceful shutdown...`)

    server.close(async () => {
        logger.info('HTTP server closed')

        try {
            await prisma.$disconnect()
            logger.info('Database connection closed')
            process.exit(0)
        } catch (error) {
            logger.error('Error during shutdown:', error)
            process.exit(1)
        }
    })

    // Force shutdown after 10 seconds
    setTimeout(() => {
        logger.error('Forced shutdown after timeout')
        process.exit(1)
    }, 10000)
}

// Start server
const server = app.listen(PORT, () => {
    logger.info(`🚀 Server running in ${process.env.NODE_ENV} mode on port ${PORT}`)
    logger.info(`📊 API: http://localhost:${PORT}/api/v1`)
    logger.info(`🏥 Health: http://localhost:${PORT}/health`)
})

// Listen for termination signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('SIGINT', () => gracefulShutdown('SIGINT'))

