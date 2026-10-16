/**
 * Test-database helpers. Never operate on anything except laundry_test.
 */
const { execSync } = require('child_process');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const BACKEND_ROOT = path.join(__dirname, '..', '..');

function getTestDatabaseUrl() {
    return (process.env.DATABASE_URL || '').trim();
}

function assertTestDatabase() {
    const url = getTestDatabaseUrl();
    if (!url.includes('laundry_test')) {
        throw new Error(
            `Refusing to touch the database: DATABASE_URL must contain "laundry_test". Got: ${url || '(empty)'}`
        );
    }
}

function adminUrlFromTestUrl(testUrl) {
    return testUrl.replace('/laundry_test', '/laundry_db').replace('/laundry_test?', '/laundry_db?');
}

async function ensureTestDatabase() {
    assertTestDatabase();
    const testUrl = getTestDatabaseUrl();
    const adminUrl = adminUrlFromTestUrl(testUrl);
    const admin = new PrismaClient({ datasources: { db: { url: adminUrl } } });
    try {
        const rows = await admin.$queryRaw`SELECT 1 AS ok FROM pg_database WHERE datname = 'laundry_test'`;
        if (!rows || rows.length === 0) {
            await admin.$executeRawUnsafe('CREATE DATABASE laundry_test');
        }
    } finally {
        await admin.$disconnect();
    }
}

function migrateTestDatabase() {
    assertTestDatabase();
    execSync('npx prisma migrate deploy', {
        cwd: BACKEND_ROOT,
        env: {
            ...process.env,
            DATABASE_URL: getTestDatabaseUrl(),
            DIRECT_URL: process.env.DIRECT_URL || getTestDatabaseUrl(),
        },
        stdio: 'inherit',
    });
}

function seedTestDatabase() {
    assertTestDatabase();
    execSync('node prisma/seed.js', {
        cwd: BACKEND_ROOT,
        env: {
            ...process.env,
            DATABASE_URL: getTestDatabaseUrl(),
            DIRECT_URL: process.env.DIRECT_URL || getTestDatabaseUrl(),
        },
        stdio: 'inherit',
    });
}

/**
 * Reset laundry_test (migrate deploy + seed). Safe: asserts the DB name first.
 */
async function resetTestDb() {
    await ensureTestDatabase();
    migrateTestDatabase();
    seedTestDatabase();
}

module.exports = {
    assertTestDatabase,
    ensureTestDatabase,
    migrateTestDatabase,
    seedTestDatabase,
    resetTestDb,
};
