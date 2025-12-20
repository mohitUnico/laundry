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
};

const prisma = new PrismaClient(prismaClientOptions);

// Log queries in development
if (process.env.NODE_ENV === 'development') {
    prisma.$on('query', (e) => {
        logger.debug(`Query: ${e.query}`);
        logger.debug(`Duration: ${e.duration}ms`);
    });
}

// Test database connection
prisma
    .$connect()
    .then(() => {
        logger.info('✅ Database connected successfully');
    })
    .catch((error) => {
        logger.error('❌ Database connection failed:', error);
        process.exit(1);
    });

module.exports = prisma;

