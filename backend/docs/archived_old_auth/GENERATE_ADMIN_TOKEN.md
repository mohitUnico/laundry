# How to Generate Admin Bearer Token

## Quick Start - 3 Methods

### Method 1: Generate Test Token (No Database Required) ⚡

**Fastest way for testing!**

```bash
cd backend
node scripts/generate-admin-token.js
```

This generates a test admin token that you can use immediately. **No database setup required!**

**Output:**
```
🔑 ADMIN JWT TOKEN GENERATED
================================================================================

📋 Token Payload:
{
  "user_id": "test-admin-uuid",
  "email": "admin@laundry.com",
  "role": "admin",
  "mart_id": "test-mart-uuid"
}

🎫 JWT Token:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGVzdC1hZG1pbi11dWlkIiwiZW1haWwiOiJhZG1pbkBsYXVuZHJ5LmNvbSIsInJvbGUiOiJhZG1pbiIsIm1hcnRfaWQiOiJ0ZXN0LW1hcnQtdXVpZCIsImlhdCI6MTY5ODY3MzIwMCwiZXhwIjoxNjk5Mjc4MDAwfQ.xxx

📝 Authorization Header:
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

⏰ Expires: 7 days from now
```

### Method 2: Generate Token for Existing User 🎯

**If you have an admin user in the database:**

```bash
cd backend
node scripts/generate-token-for-user.js admin@laundry.com
```

This generates a JWT token for an actual user from your database.

**Requirements:**
- Database must be running
- User must exist in the database
- User account must be active

### Method 3: Register a Mart (Creates Admin User) 🏢

**Create a real admin user by registering a mart:**

```bash
curl -X POST http://localhost:3000/api/v1/marts/register \
  -H "Content-Type: application/json" \
  -d '{
    "martName": "Test Laundry Mart",
    "contactEmail": "mart@test.com",
    "contactPhone": "9123456789",
    "address": "123 Main Street, City, State, 123456",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "serviceRadiusKm": {
      "maxRadius": 10,
      "tiers": [
        {"minKm": 0, "maxKm": 5, "pricePerKm": 20},
        {"minKm": 5, "maxKm": 10, "pricePerKm": 40}
      ]
    },
    "owner": {
      "fullName": "Admin User",
      "email": "admin@test.com",
      "phone": "9876543210",
      "password": "admin123"
    }
  }'
```

Then generate token for the created user:
```bash
node scripts/generate-token-for-user.js admin@test.com
```

## Setup Requirements

### 1. Environment Variables

Create a `.env` file in the `backend` directory:

```bash
cd backend
cat > .env << 'EOF'
# Database
DATABASE_URL="postgresql://username:password@localhost:5432/laundry_db"

# JWT Secret (CHANGE THIS!)
JWT_SECRET="your-super-secret-jwt-key-change-in-production"

# Server
PORT=3000
NODE_ENV=development

# Logging
LOG_LEVEL=info
EOF
```

**Important:** Change `JWT_SECRET` to a secure random string!

Generate a secure JWT_SECRET:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 2. Install Dependencies

```bash
cd backend
npm install
```

### 3. Setup Database (for Method 2 & 3)

```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Start the server
npm run dev
```

## Testing the Token

### Using cURL

```bash
# Replace {MART_ID} with actual mart ID
# Replace {TOKEN} with the generated token

curl -X POST http://localhost:3000/api/v1/marts/{MART_ID}/managers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN}" \
  -d '{
    "fullName": "John Manager",
    "email": "john.manager@example.com",
    "phone": "9876543210",
    "password": "SecurePass123!",
    "isActive": true
  }'
```

### Using Postman

1. Open Postman
2. Create a new POST request
3. URL: `http://localhost:3000/api/v1/marts/{MART_ID}/managers`
4. Headers:
   - `Content-Type`: `application/json`
   - `Authorization`: `Bearer {YOUR_TOKEN}`
5. Body (raw JSON):
```json
{
  "fullName": "John Manager",
  "email": "john.manager@example.com",
  "phone": "9876543210",
  "password": "SecurePass123!",
  "isActive": true
}
```

### Using JavaScript

```javascript
const axios = require('axios');

const token = 'YOUR_JWT_TOKEN_HERE';
const martId = 'YOUR_MART_ID_HERE';

async function addManager() {
  try {
    const response = await axios.post(
      `http://localhost:3000/api/v1/marts/${martId}/managers`,
      {
        fullName: 'John Manager',
        email: 'john.manager@example.com',
        phone: '9876543210',
        password: 'SecurePass123!',
        isActive: true
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      }
    );
    
    console.log('✅ Manager added:', response.data);
  } catch (error) {
    console.error('❌ Error:', error.response.data);
  }
}

addManager();
```

## Token Details

### Token Payload Structure

```json
{
  "user_id": "uuid-here",
  "email": "admin@laundry.com",
  "role": "admin",
  "mart_id": "mart-uuid-here",
  "iat": 1698673200,
  "exp": 1699278000
}
```

### Token Expiration

- Default expiration: **7 days**
- After expiration, generate a new token
- In production, implement refresh token mechanism

### Required Token Fields for Manager API

The JWT token **must** contain:
- `role`: Must be `'admin'` (checked by authorization middleware)
- Other fields are optional but recommended for logging

## Troubleshooting

### Error: "JWT_SECRET not found"

**Solution:** Add `JWT_SECRET` to your `.env` file

```bash
echo "JWT_SECRET=your-secret-key-here" >> .env
```

### Error: "User not found"

**Solution:** 
- Check if the user exists in database
- Verify email spelling
- Register a mart to create an admin user

### Error: "No token provided"

**Solution:** Make sure you're including the Authorization header:
```
Authorization: Bearer {YOUR_TOKEN}
```

### Error: "Invalid token"

**Solution:**
- Token might be expired (generate a new one)
- JWT_SECRET might have changed
- Token might be corrupted (copy it carefully)

### Error: "You do not have permission"

**Solution:**
- Make sure the token has `role: 'admin'`
- Verify you're using the correct endpoint

## Script Customization

### Customize Token Payload

Edit `scripts/generate-admin-token.js`:

```javascript
const payload = {
  user_id: 'your-user-id',
  email: 'your-email@example.com',
  role: 'admin',  // or 'manager', 'staff'
  mart_id: 'your-mart-id',
  // Add custom fields here
};
```

### Customize Token Expiration

```javascript
const options = {
  expiresIn: '7d',  // Change to '1d', '30d', '1h', etc.
};
```

## Production Considerations

⚠️ **For production, you should:**

1. **Implement proper login endpoint** - Don't generate tokens manually
2. **Use strong JWT_SECRET** - At least 64 random bytes
3. **Implement refresh tokens** - Don't use long-lived tokens
4. **Store tokens securely** - Use httpOnly cookies or secure storage
5. **Implement token revocation** - Maintain a blacklist or use short expiration
6. **Add rate limiting** - Prevent brute force attacks
7. **Use HTTPS only** - Never send tokens over HTTP

## Next Steps

1. ✅ Generate admin token using one of the methods above
2. ✅ Test the `/api/v1/marts/:martId/managers` endpoint
3. ⏭️ Implement proper login endpoint for production
4. ⏭️ Add refresh token mechanism
5. ⏭️ Implement password reset functionality

## Quick Reference

```bash
# Generate test token (fastest)
node scripts/generate-admin-token.js

# Generate token for existing user
node scripts/generate-token-for-user.js user@email.com

# Test the API
curl -X POST http://localhost:3000/api/v1/marts/{MART_ID}/managers \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"fullName":"John","email":"john@test.com","phone":"9876543210","password":"pass123"}'
```

That's it! You now have an admin token to test your API! 🎉

