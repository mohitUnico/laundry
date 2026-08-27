// Jest setup — CommonJS so Jest loads without ESM transform
const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

const envTestPath = path.join(__dirname, '..', '.env.test');
if (fs.existsSync(envTestPath)) {
    dotenv.config({ path: envTestPath });
}

jest.setTimeout(10000);

afterAll(async () => {
    try {
        const prisma = require('../src/config/database');
        await prisma.$disconnect();
    } catch {
        // ignore
    }
});
