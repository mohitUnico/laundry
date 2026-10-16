// Jest setup — CommonJS so Jest loads without ESM transform
jest.setTimeout(10000);

afterAll(async () => {
    try {
        const prisma = require('../src/config/database');
        await prisma.$disconnect();
    } catch {
        // ignore
    }
});
