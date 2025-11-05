/**
 * Generate JWT Token for Existing User
 * 
 * This script generates a JWT token for an existing user in the database.
 * Run with: node scripts/generate-token-for-user.js <user-email>
 */

const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const prisma = new PrismaClient();

// Get JWT secret from environment
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
    console.error('❌ Error: JWT_SECRET not found in environment variables');
    console.error('Please set JWT_SECRET in your .env file');
    process.exit(1);
}

// Get email from command line argument
const userEmail = process.argv[2];

if (!userEmail) {
    console.error('❌ Error: Please provide user email as argument');
    console.error('Usage: node scripts/generate-token-for-user.js <user-email>');
    console.error('Example: node scripts/generate-token-for-user.js admin@laundry.com');
    process.exit(1);
}

async function generateTokenForUser() {
    try {
        // Find user in database
        const user = await prisma.user.findUnique({
            where: { email: userEmail },
            include: {
                mart: {
                    select: {
                        mart_id: true,
                        mart_name: true,
                    },
                },
            },
        });

        if (!user) {
            console.error(`❌ Error: User with email '${userEmail}' not found`);
            console.error('Please check the email address and try again');
            await prisma.$disconnect();
            process.exit(1);
        }

        if (!user.is_active) {
            console.error(`❌ Error: User account is inactive`);
            await prisma.$disconnect();
            process.exit(1);
        }

        // Token payload
        const payload = {
            user_id: user.user_id,
            email: user.email,
            role: user.role,
            mart_id: user.mart_id,
            full_name: user.full_name,
        };

        // Token options
        const options = {
            expiresIn: '7d', // Token expires in 7 days
        };

        // Generate token
        const token = jwt.sign(payload, JWT_SECRET, options);

        console.log('\n' + '='.repeat(80));
        console.log('🔑 JWT TOKEN GENERATED FOR USER');
        console.log('='.repeat(80));
        console.log('\n👤 User Details:');
        console.log(`   Name: ${user.full_name}`);
        console.log(`   Email: ${user.email}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Mart: ${user.mart?.mart_name || 'N/A'}`);
        console.log(`   Active: ${user.is_active}`);
        console.log('\n📋 Token Payload:');
        console.log(JSON.stringify(payload, null, 2));
        console.log('\n🎫 JWT Token:');
        console.log('\x1b[32m%s\x1b[0m', token);
        console.log('\n📝 Authorization Header:');
        console.log('\x1b[36m%s\x1b[0m', `Bearer ${token}`);
        console.log('\n⏰ Expires: 7 days from now');
        console.log('\n💡 Usage Example (cURL):');
        console.log(`\x1b[33m
curl -X POST http://localhost:3000/api/v1/marts/{MART_ID}/managers \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer ${token}" \\
  -d '{
    "fullName": "John Manager",
    "email": "john@example.com",
    "phone": "9876543210",
    "password": "password123",
    "isActive": true
  }'
\x1b[0m`);
        console.log('='.repeat(80) + '\n');

        // Verify the token
        const decoded = jwt.verify(token, JWT_SECRET);
        console.log('✅ Token verified successfully!');
        console.log('Token will expire at:', new Date(decoded.exp * 1000).toLocaleString());
        console.log('\n');

        await prisma.$disconnect();
    } catch (error) {
        console.error('❌ Error:', error.message);
        await prisma.$disconnect();
        process.exit(1);
    }
}

generateTokenForUser();

