const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');

// Allow overriding the Prisma connection string with a Supabase-specific URL.
// This keeps local DATABASE_URL values intact while enabling Supabase via env only.
if (process.env.SUPABASE_DATABASE_URL) {
    process.env.DATABASE_URL = process.env.SUPABASE_DATABASE_URL;
    logger.info('Using Supabase connection string from SUPABASE_DATABASE_URL');
}

const prismaClientOptions = {
    log: [
        { level: 'query', emit: 'event' },
        { level: 'error', emit: 'stdout' },
        { level: 'warn', emit: 'stdout' },
    ],
    datasources: {
        db: {
            url: process.env.DATABASE_URL,
        },
    },
};

const prisma = new PrismaClient(prismaClientOptions);

// Connection Pooling:
// Prisma automatically handles connection pooling internally.
// For Supabase, connection pooling is handled by Supabase's PgBouncer.
// No additional connection pool parameters are needed in the DATABASE_URL.
// Prisma's default connection pool settings are optimized for most use cases.

// Log queries in development
if (process.env.NODE_ENV === 'development') {
    prisma.$on('query', (e) => {
        logger.debug(`Query: ${e.query}`);
        logger.debug(`Duration: ${e.duration}ms`);
    });
}

// Test database connection (non-blocking)
// Don't exit on failure - let the server start and handle connection errors gracefully
setTimeout(() => {
    prisma
        .$connect()
        .then(() => {
            logger.info('✅ Database connected successfully');
        })
        .catch((error) => {
            console.error('❌ Database connection failed:', error);
            logger.error('❌ Database connection failed:', error);
            logger.error('Server will continue to start, but database operations may fail');
            // Don't exit - let the server start and show the error
            // The first database operation will fail with a clear error message
        });
}, 100); // Delay connection test slightly to ensure logger is ready

module.exports = prisma;

