// Test Prisma connection
const path = require('path');
const backendPath = path.join(__dirname, '../backend');
process.chdir(backendPath);

require('dotenv').config({ path: path.join(backendPath, '.env') });
const { PrismaClient } = require(path.join(backendPath, 'node_modules/@prisma/client'));

const prisma = new PrismaClient({
    log: ['error', 'warn'],
});

async function test() {
    try {
        console.log('DATABASE_URL:', process.env.DATABASE_URL ? '✅ Set' : '❌ Not set');
        if (process.env.DATABASE_URL) {
            // Mask password in output
            const masked = process.env.DATABASE_URL.replace(/:([^:@]+)@/, ':****@');
            console.log('Connection string:', masked);
        }
        
        console.log('\nAttempting to connect...');
        await prisma.$connect();
        console.log('✅ Database connected successfully!');
        
        // Test a simple query
        const result = await prisma.$queryRaw`SELECT current_user, current_database()`;
        console.log('✅ Query test passed:', result[0]);
        
    } catch (error) {
        console.error('❌ Connection failed:');
        console.error('Error code:', error.code);
        console.error('Error message:', error.message);
        if (error.meta) {
            console.error('Meta:', error.meta);
        }
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

test();

