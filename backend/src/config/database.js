import { PrismaClient } from '@prisma/client'
import { logger } from '../utils/logger.js'

const prismaClientOptions = {
    log: [
        { level: 'query', emit: 'event' },
        { level: 'error', emit: 'stdout' },
        { level: 'warn', emit: 'stdout' },
    ],
}

export const prisma = new PrismaClient(prismaClientOptions)

// Log queries in development
if (process.env.NODE_ENV === 'development') {
    prisma.$on('query', (e) => {
        logger.debug(`Query: ${e.query}`)
        logger.debug(`Duration: ${e.duration}ms`)
    })
}

// Test database connection
prisma.$connect()
    .then(() => {
        logger.info('✅ Database connected successfully')
    })
    .catch((error) => {
        logger.error('❌ Database connection failed:', error)
        process.exit(1)
    })

export default prisma

