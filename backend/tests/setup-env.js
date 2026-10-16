/**
 * Runs before any test file is imported (jest setupFiles).
 * Isolates tests onto laundry_test + Redis db 1.
 */
const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

const envTestPath = path.join(__dirname, '..', '.env.test');
if (fs.existsSync(envTestPath)) {
    dotenv.config({ path: envTestPath, override: true });
}

process.env.NODE_ENV = 'test';

if (!process.env.JWT_SECRET) {
    process.env.JWT_SECRET = 'test-secret-do-not-use-in-prod';
}
if (!process.env.JWT_EXPIRY) {
    process.env.JWT_EXPIRY = '7d';
}
if (!process.env.DATABASE_URL) {
    process.env.DATABASE_URL =
        'postgresql://laundry_user:laundry_pass@localhost:55432/laundry_test?schema=public';
}
if (!process.env.DIRECT_URL) {
    process.env.DIRECT_URL =
        'postgresql://laundry_user:laundry_pass@localhost:55432/laundry_test';
}
if (!process.env.REDIS_URL) {
    process.env.REDIS_URL = 'redis://localhost:6379/1';
}
