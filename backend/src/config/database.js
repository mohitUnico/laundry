// Load .env before reading DATABASE_URL (safe if app already required env — no-op duplicate load)
require('./env');

const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');

/**
 * Last-resort read when process.env.DATABASE_URL is missing (Docker/Windows/BOM/dotenv edge cases).
 */
function readDatabaseUrlFromEnvFile() {
    const envPath = path.join(process.cwd(), '.env');
    if (!fs.existsSync(envPath)) {
        return '';
    }
    try {
        let content = fs.readFileSync(envPath, 'utf8');
        content = content.replace(/^\uFEFF/, '');
        const match = content.match(/^\s*DATABASE_URL\s*=\s*(.+)$/m);
        if (!match) {
            return '';
        }
        let v = match[1].trim();
        if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
            v = v.slice(1, -1);
        }
        return v.trim();
    } catch {
        return '';
    }
}

let databaseUrl = (process.env.DATABASE_URL || '').trim();
if (!databaseUrl) {
    databaseUrl = readDatabaseUrlFromEnvFile();
    if (databaseUrl) {
        process.env.DATABASE_URL = databaseUrl;
        logger.info('DATABASE_URL loaded from .env file (process.env was empty)');
    }
}
if (!databaseUrl) {
    throw new Error(
        'DATABASE_URL is not set or is empty. Set DATABASE_URL in backend/.env. ' +
            'In Docker, ensure docker-compose passes env_file: ./backend/.env and the variable is present.'
    );
}

const prismaClientOptions = {
    log: [
        { level: 'query', emit: 'event' },
        { level: 'error', emit: 'stdout' },
        { level: 'warn', emit: 'stdout' },
    ],
    datasources: {
        db: {
            url: databaseUrl,
        },
    },
};

const prisma = new PrismaClient(prismaClientOptions);

/** True when Jest/npm test runs (dotenv may reset NODE_ENV from .env) */
function isTestRun() {
    return (
        process.env.NODE_ENV === 'test' ||
        process.env.npm_lifecycle_event === 'test' ||
        typeof process.env.JEST_WORKER_ID !== 'undefined' ||
        process.argv.some((a) => /jest(?:\.cmd)?$/i.test(a) || a === 'jest')
    );
}

// Connection Pooling:
// Prisma handles connection pooling internally for local PostgreSQL.

// Log queries in development
if (process.env.NODE_ENV === 'development') {
    prisma.$on('query', (e) => {
        logger.debug(`Query: ${e.query}`);
        logger.debug(`Duration: ${e.duration}ms`);
    });
}

// Test database connection (non-blocking)
// Don't exit on failure - let the server start and handle connection errors gracefully
// Skip in Jest: avoids noisy logs, failed connects, and open handles when only smoke-testing HTTP
if (!isTestRun()) {
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
}

module.exports = prisma;

