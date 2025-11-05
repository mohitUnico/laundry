# Automatic JWT Token Generation - Feature Summary

## What Changed

The mart registration and user management endpoints now **automatically generate JWT tokens** and include them in the API response. This eliminates the need for manual token generation scripts.

## Modified Files

### 1. **New File**: `src/utils/jwt.js`
**Purpose**: Utility functions for JWT token generation and verification

**Functions**:
- `generateToken(user)` - Generate JWT token from user object
- `verifyToken(token)` - Verify and decode JWT token
- `decodeToken(token)` - Decode token without verification (debugging)
- `getTokenExpiry(expiresIn)` - Calculate token expiry date

### 2. **Modified**: `src/services/mart.service.js`
**Changes**:
- Added `const { generateToken } = require('../utils/jwt');`
- Modified `registerMart()` to return `{ mart, owner, token }`
- Modified `addUserToMart()` to return `{ user, token }`
- Modified `addManagerToMart()` to return `{ manager, token }`

**Before**:
```javascript
return {
  mart: result.mart,
  owner: ownerWithoutPassword,
};
```

**After**:
```javascript
const token = generateToken(result.owner);
return {
  mart: result.mart,
  owner: ownerWithoutPassword,
  token, // JWT token for immediate use
};
```

### 3. **Modified**: `src/controllers/mart.controller.js`
**Changes**:
- Updated `addUserToMart()` to handle `{ user, token }` response
- Updated `addManagerToMart()` to handle `{ manager, token }` response
- Both controllers now pass the full result object to the client

**Before**:
```javascript
const user = await martService.addUserToMart(req.body);
res.status(201).json({
  success: true,
  data: user,
  message: 'User added to mart successfully',
});
```

**After**:
```javascript
const result = await martService.addUserToMart(req.body);
res.status(201).json({
  success: true,
  data: result, // Contains { user, token }
  message: 'User added to mart successfully',
});
```

### 4. **New File**: `docs/AUTOMATIC_TOKEN_GENERATION.md`
**Purpose**: Complete documentation for automatic token generation feature

**Sections**:
- Overview and benefits
- How it works (3 endpoints)
- Token structure and fields
- Complete workflow example
- Environment configuration
- Token storage best practices
- Testing tokens
- Error scenarios
- Security considerations

### 5. **New File**: `docs/TOKEN_FEATURE_SUMMARY.md` (this file)
**Purpose**: Quick reference for developers

## API Response Changes

### 1. POST `/api/v1/marts/register`

**Before**:
```json
{
  "success": true,
  "data": {
    "mart": {...},
    "owner": {...}
  },
  "message": "Mart registered successfully"
}
```

**After**:
```json
{
  "success": true,
  "data": {
    "mart": {...},
    "owner": {...},
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Mart registered successfully"
}
```

### 2. POST `/api/v1/marts/users`

**Before**:
```json
{
  "success": true,
  "data": {
    "user_id": "...",
    "full_name": "...",
    "email": "...",
    ...
  },
  "message": "User added to mart successfully"
}
```

**After**:
```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": "...",
      "full_name": "...",
      "email": "...",
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "User added to mart successfully"
}
```

### 3. POST `/api/v1/marts/:martId/managers`

**Before**:
```json
{
  "success": true,
  "data": {
    "user_id": "...",
    "full_name": "...",
    "email": "...",
    "role": "manager",
    ...
  },
  "message": "Manager added to mart successfully"
}
```

**After**:
```json
{
  "success": true,
  "data": {
    "manager": {
      "user_id": "...",
      "full_name": "...",
      "email": "...",
      "role": "manager",
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Manager added to mart successfully"
}
```

## Token Payload Structure

```json
{
  "user_id": "uuid-here",
  "email": "user@example.com",
  "role": "admin",
  "mart_id": "mart-uuid-here",
  "full_name": "User Name",
  "iat": 1761819213,
  "exp": 1762424013
}
```

## Environment Variables

Add to your `.env` file:

```bash
# JWT Configuration (Required)
JWT_SECRET="your-64-byte-random-secret-key"
JWT_EXPIRY="7d"  # Optional, defaults to 7 days
```

Generate a secure JWT_SECRET:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Usage Flow

```
1. Register Mart
   ↓
   Get owner token
   ↓
2. Store owner token
   ↓
3. Use owner token to add managers
   ↓
   Get manager token
   ↓
4. Give manager token to manager
   ↓
5. Both can authenticate with their tokens
```

## Quick Test

### 1. Register a mart:
```bash
curl -X POST http://localhost:3000/api/v1/marts/register \
  -H "Content-Type: application/json" \
  -d '{
    "martName": "Test Mart",
    "contactEmail": "test@mart.com",
    "contactPhone": "9123456789",
    "address": "123 Main St",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "serviceRadiusKm": {
      "maxRadius": 10,
      "tiers": [{"minKm": 0, "maxKm": 5, "pricePerKm": 20}]
    },
    "owner": {
      "fullName": "Test Owner",
      "email": "owner@test.com",
      "phone": "9876543210",
      "password": "test123"
    }
  }'
```

**Expected**: Response includes `data.token`

### 2. Add a manager (use token from step 1):
```bash
curl -X POST http://localhost:3000/api/v1/marts/{MART_ID}/managers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN_FROM_STEP_1}" \
  -d '{
    "fullName": "Test Manager",
    "email": "manager@test.com",
    "phone": "9876543211",
    "password": "manager123",
    "isActive": true
  }'
```

**Expected**: Response includes `data.token` for the manager

## Breaking Changes

⚠️ **Client applications need to update**:

1. **Access token in response**:
   - Old: `response.data` (user object)
   - New: `response.data.token` (JWT token)

2. **User object location**:
   - Old: `response.data`
   - New: `response.data.user` or `response.data.manager`

## Migration Guide for Clients

### React/JavaScript
```javascript
// Old code
const response = await registerMart(data);
const owner = response.data;

// New code
const response = await registerMart(data);
const { owner, token } = response.data;
// Store token for future use
localStorage.setItem('token', token);
```

### Flutter/Dart
```dart
// Old code
final response = await registerMart(data);
final owner = response.data;

// New code
final response = await registerMart(data);
final owner = response.data['owner'];
final token = response.data['token'];
// Store token securely
await storage.write(key: 'jwt_token', value: token);
```

## Benefits

✅ **Streamlined Registration**: No need to call login after registration  
✅ **Immediate Access**: Owner can start managing mart right away  
✅ **Manager Onboarding**: Managers get token when added  
✅ **Consistent Pattern**: Same approach across all user creation endpoints  
✅ **Better UX**: Fewer steps for users  
✅ **Simplified Testing**: No need for separate token generation scripts  

## Logging

Enhanced logging for token operations:

```
INFO: JWT token generated for owner {userId: ..., email: ...}
INFO: JWT token generated for manager {userId: ..., email: ..., role: ...}
INFO: JWT token generated for user {userId: ..., email: ..., role: ...}
```

## Security

- Tokens are signed with `JWT_SECRET` from environment
- Default expiry: 7 days (configurable via `JWT_EXPIRY`)
- Passwords are never included in tokens
- Tokens include user role for authorization checks
- All token operations are logged for audit trail

## Next Steps

Recommended enhancements:
1. Implement login endpoint (email/password → token)
2. Add refresh token mechanism
3. Implement token revocation/blacklist
4. Add "remember me" functionality
5. Support multi-device token management

## Related Files

- `src/utils/jwt.js` - JWT utility functions
- `src/services/mart.service.js` - Token generation logic
- `src/controllers/mart.controller.js` - API response formatting
- `src/middleware/auth.middleware.js` - Token verification
- `docs/AUTOMATIC_TOKEN_GENERATION.md` - Complete documentation
- `docs/ADD_MANAGER_API.md` - Manager API documentation
- `docs/MART_API_GUIDE.md` - Complete mart API guide

---

**Status**: ✅ **Complete and Ready for Testing**

The automatic token generation feature is fully implemented and ready to use!

