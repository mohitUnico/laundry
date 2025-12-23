// Test database connection
const path = require('path');
const backendPath = path.join(__dirname, '../backend');
process.chdir(backendPath);
require('dotenv').config({ path: path.join(backendPath, '.env') });
const { PrismaClient } = require(path.join(backendPath, 'node_modules/@prisma/client'));

const prisma = new PrismaClient();

async function testConnection() {
    try {
        console.log('Testing database connection...');
        console.log('DATABASE_URL:', process.env.DATABASE_URL ? '✅ Set' : '❌ Not set');
        
        await prisma.$connect();
        console.log('✅ Database connected successfully!');
        
        // Test a simple query
        const result = await prisma.$queryRaw`SELECT 1 as test`;
        console.log('✅ Query test passed:', result);
        
        // Check if tables exist
        const tableCount = await prisma.$queryRaw`
            SELECT COUNT(*) as count 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        `;
        console.log('✅ Tables found:', tableCount[0].count);
        
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
        console.log('Connection closed.');
    }
}

testConnection();

