/**
 * Generate Admin JWT Token - Development Utility
 * 
 * This script generates a JWT token for testing purposes.
 * Run with: node scripts/generate-admin-token.js
 */

const jwt = require('jsonwebtoken');
require('dotenv').config();

// Get JWT secret from environment or use default for development
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';

// Token payload - customize as needed
const payload = {
    user_id: 'test-admin-uuid',
    email: 'admin@laundry.com',
    role: 'admin',
    mart_id: 'test-mart-uuid',
};

// Token options
const options = {
    expiresIn: '7d', // Token expires in 7 days
};

try {
    // Generate token
    const token = jwt.sign(payload, JWT_SECRET, options);

    console.log('\n' + '='.repeat(80));
    console.log('🔑 ADMIN JWT TOKEN GENERATED');
    console.log('='.repeat(80));
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
} catch (error) {
    console.error('❌ Error generating token:', error.message);
    process.exit(1);
}

