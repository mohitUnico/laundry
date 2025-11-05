# Automatic JWT Token Generation

## Overview

The Laundry App backend now automatically generates JWT tokens when:
1. **Registering a mart** - Returns token for the owner
2. **Adding a manager** - Returns token for the manager  
3. **Adding any user** - Returns token for the user

This eliminates the need to manually generate tokens and provides a seamless authentication experience.

## Benefits

✅ **No Manual Token Generation** - Tokens are created automatically  
✅ **Immediate Authentication** - Use the token right away in subsequent requests  
✅ **Secure** - Tokens are properly signed with JWT_SECRET  
✅ **Consistent** - Same token structure across all endpoints  
✅ **Reusable** - Store tokens for future login sessions  

## How It Works

### 1. Mart Registration (Creates Owner + Token)

When you register a mart, the owner user is created and a JWT token is automatically generated.

**Endpoint**: `POST /api/v1/marts/register`

**Request**:
```json
{
  "martName": "Clean & Fresh Laundry",
  "contactEmail": "contact@cleanfresh.com",
  "contactPhone": "9123456789",
  "address": "123 Main Street, City, State",
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
    "fullName": "John Doe",
    "email": "john.owner@example.com",
    "phone": "9876543210",
    "password": "SecurePass123!"
  }
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "mart": {
      "mart_id": "uuid-here",
      "mart_name": "Clean & Fresh Laundry",
      "contact_email": "contact@cleanfresh.com",
      "contact_phone": "9123456789",
      "address": "123 Main Street, City, State",
      "latitude": 28.6139,
      "longitude": 77.2090,
      "is_active": true,
      "created_at": "2025-10-30T12:00:00.000Z"
    },
    "owner": {
      "user_id": "owner-uuid-here",
      "mart_id": "uuid-here",
      "full_name": "John Doe",
      "email": "john.owner@example.com",
      "phone": "9876543210",
      "role": "admin",
      "is_active": true,
      "created_at": "2025-10-30T12:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib3duZXItdXVpZC1oZXJlIiwiZW1haWwiOiJqb2huLm93bmVyQGV4YW1wbGUuY29tIiwicm9sZSI6ImFkbWluIiwibWFydF9pZCI6InV1aWQtaGVyZSIsImZ1bGxfbmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNzYxODE5MjEzLCJleHAiOjE3NjI0MjQwMTN9.xxx"
  },
  "message": "Mart registered successfully"
}
```

**Important**: Save the `token` from the response! Use it for:
- Adding managers
- Managing mart settings
- Any other authenticated requests

### 2. Add Manager (Uses Owner Token + Returns Manager Token)

Use the owner's token to add a manager, and get back the manager's token.

**Endpoint**: `POST /api/v1/marts/:martId/managers`

**Headers**:
```
Authorization: Bearer {OWNER_TOKEN_FROM_REGISTRATION}
Content-Type: application/json
```

**Request**:
```json
{
  "fullName": "Jane Manager",
  "email": "jane.manager@example.com",
  "phone": "9876543211",
  "password": "ManagerPass123!",
  "isActive": true
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "manager": {
      "user_id": "manager-uuid-here",
      "mart_id": "mart-uuid-here",
      "full_name": "Jane Manager",
      "email": "jane.manager@example.com",
      "phone": "9876543211",
      "role": "manager",
      "is_active": true,
      "created_at": "2025-10-30T12:05:00.000Z",
      "mart": {
        "mart_id": "mart-uuid-here",
        "mart_name": "Clean & Fresh Laundry",
        "contact_email": "contact@cleanfresh.com",
        "contact_phone": "9123456789"
      }
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFuYWdlci11dWlkLWhlcmUiLCJlbWFpbCI6ImphbmUubWFuYWdlckBleGFtcGxlLmNvbSIsInJvbGUiOiJtYW5hZ2VyIiwibWFydF9pZCI6Im1hcnQtdXVpZC1oZXJlIiwiZnVsbF9uYW1lIjoiSmFuZSBNYW5hZ2VyIiwiaWF0IjoxNzYxODE5NTAwLCJleHAiOjE3NjI0MjQzMDB9.yyy"
  },
  "message": "Manager added to mart successfully"
}
```

**Important**: Give the `token` to the manager! They can use it for:
- Login authentication
- Managing orders
- Any manager-level operations

### 3. Add User (Generic User Addition)

Similar to adding a manager, but you specify the role.

**Endpoint**: `POST /api/v1/marts/users`

**Headers**:
```
Authorization: Bearer {OWNER_TOKEN}
Content-Type: application/json
```

**Request**:
```json
{
  "martId": "mart-uuid-here",
  "fullName": "Bob Staff",
  "email": "bob.staff@example.com",
  "phone": "9876543212",
  "password": "StaffPass123!",
  "role": "staff",
  "isActive": true
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": "staff-uuid-here",
      "mart_id": "mart-uuid-here",
      "full_name": "Bob Staff",
      "email": "bob.staff@example.com",
      "phone": "9876543212",
      "role": "staff",
      "is_active": true,
      "created_at": "2025-10-30T12:10:00.000Z",
      "mart": {
        "mart_id": "mart-uuid-here",
        "mart_name": "Clean & Fresh Laundry"
      }
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3RhZmYtdXVpZC1oZXJlIiwiZW1haWwiOiJib2Iuc3RhZmZAZXhhbXBsZS5jb20iLCJyb2xlIjoic3RhZmYiLCJtYXJ0X2lkIjoibWFydC11dWlkLWhlcmUiLCJmdWxsX25hbWUiOiJCb2IgU3RhZmYiLCJpYXQiOjE3NjE4MTk4MDAsImV4cCI6MTc2MjQyNDYwMH0.zzz"
  },
  "message": "User added to mart successfully"
}
```

## Token Structure

### JWT Payload

```json
{
  "user_id": "uuid-here",
  "email": "user@example.com",
  "role": "admin|manager|staff",
  "mart_id": "mart-uuid-here",
  "full_name": "User Name",
  "iat": 1761819213,
  "exp": 1762424013
}
```

### Token Fields

| Field | Description |
|-------|-------------|
| `user_id` | Unique user identifier |
| `email` | User's email address |
| `role` | User role (admin/manager/staff) |
| `mart_id` | Associated mart ID |
| `full_name` | User's full name |
| `iat` | Issued at timestamp |
| `exp` | Expiration timestamp |

### Token Expiration

- **Default**: 7 days
- **Configurable**: Set `JWT_EXPIRY` in `.env` (e.g., `1d`, `30d`, `1h`)

## Complete Workflow Example

### Step 1: Register Mart

```bash
curl -X POST http://localhost:3000/api/v1/marts/register \
  -H "Content-Type: application/json" \
  -d '{
    "martName": "My Laundry",
    "contactEmail": "contact@mylaundry.com",
    "contactPhone": "9123456789",
    "address": "123 Main St",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "serviceRadiusKm": {
      "maxRadius": 10,
      "tiers": [{"minKm": 0, "maxKm": 5, "pricePerKm": 20}]
    },
    "owner": {
      "fullName": "Owner Name",
      "email": "owner@mylaundry.com",
      "phone": "9876543210",
      "password": "owner123"
    }
  }'
```

**Save the response**:
- `data.mart.mart_id` - You'll need this for adding managers
- `data.token` - Owner's JWT token

### Step 2: Add Manager (Using Owner Token)

```bash
# Replace {MART_ID} and {OWNER_TOKEN}
curl -X POST http://localhost:3000/api/v1/marts/{MART_ID}/managers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {OWNER_TOKEN}" \
  -d '{
    "fullName": "Manager Name",
    "email": "manager@mylaundry.com",
    "phone": "9876543211",
    "password": "manager123",
    "isActive": true
  }'
```

**Save the response**:
- `data.token` - Manager's JWT token (give this to the manager!)

### Step 3: Use Tokens for Authentication

Both owner and manager can now use their tokens:

```bash
# Owner making a request
curl -X GET http://localhost:3000/api/v1/marts/{MART_ID} \
  -H "Authorization: Bearer {OWNER_TOKEN}"

# Manager making a request
curl -X GET http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer {MANAGER_TOKEN}"
```

## Environment Configuration

Add to your `.env` file:

```bash
# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-change-in-production-64-bytes"
JWT_EXPIRY="7d"  # 7 days (can be 1d, 30d, 1h, etc.)
```

**Generate a secure JWT_SECRET**:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Token Storage Best Practices

### Frontend (React/Flutter)

1. **Store securely**:
   - Use `httpOnly` cookies (web)
   - Use secure storage (mobile: Flutter Secure Storage, Keychain)
   - Never store in localStorage (XSS vulnerable)

2. **Send with requests**:
```javascript
// JavaScript example
axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
```

3. **Handle expiration**:
   - Implement refresh token mechanism
   - Redirect to login on 401 errors

### Mobile Apps

```dart
// Flutter example
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Save token
await storage.write(key: 'jwt_token', value: token);

// Retrieve token
String? token = await storage.read(key: 'jwt_token');

// Use in API calls
headers: {'Authorization': 'Bearer $token'}
```

## Testing Tokens

### Verify Token Contents

```bash
# Install jwt-cli
npm install -g jwt-cli

# Decode token
jwt {YOUR_TOKEN}
```

### Test Authentication

```bash
# Test with valid token
curl -X GET http://localhost:3000/api/v1/marts/{MART_ID} \
  -H "Authorization: Bearer {TOKEN}"

# Expected: 200 OK with mart details

# Test without token
curl -X GET http://localhost:3000/api/v1/marts/{MART_ID}

# Expected: 401 Unauthorized
```

## Token Lifecycle

```
┌─────────────────┐
│  Register Mart  │
└────────┬────────┘
         │
         ▼
   ┌───────────┐
   │ Get Token │ ──► Store token
   └─────┬─────┘
         │
         ▼
   ┌──────────────┐
   │ Use Token in │
   │   Requests   │
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │ Token Valid? │
   └──────┬───────┘
      Yes │  No
          │   └──► Re-authenticate
          ▼
   ┌──────────────┐
   │   Success    │
   └──────────────┘
```

## Error Scenarios

### Token Expired

**Response** (401):
```json
{
  "success": false,
  "message": "Token expired",
  "errorCode": "AUTHENTICATION_ERROR"
}
```

**Solution**: Register/login again to get a new token

### Invalid Token

**Response** (401):
```json
{
  "success": false,
  "message": "Invalid token",
  "errorCode": "AUTHENTICATION_ERROR"
}
```

**Solution**: Check token format and ensure it's not corrupted

### No Token Provided

**Response** (401):
```json
{
  "success": false,
  "message": "No token provided",
  "errorCode": "AUTHENTICATION_ERROR"
}
```

**Solution**: Include `Authorization: Bearer {TOKEN}` header

## Advantages Over Manual Generation

| Manual Generation | Automatic Generation |
|-------------------|---------------------|
| ❌ Extra step required | ✅ Token included in response |
| ❌ Need database access | ✅ Works immediately |
| ❌ Separate script/tool | ✅ Part of normal flow |
| ❌ Easy to forget | ✅ Always available |
| ❌ Testing complexity | ✅ Simple testing |

## Security Considerations

1. **JWT_SECRET**: Use a strong, random secret (64+ bytes)
2. **HTTPS Only**: Never send tokens over HTTP in production
3. **Token Expiry**: Use reasonable expiration times (7 days default)
4. **Secure Storage**: Store tokens securely on client side
5. **Refresh Tokens**: Implement for long-term sessions
6. **Rotation**: Regenerate tokens periodically
7. **Revocation**: Implement token blacklist if needed

## Future Enhancements

- [ ] Login endpoint (authenticate with email/password, get new token)
- [ ] Refresh token endpoint (get new token without re-authenticating)
- [ ] Token revocation/blacklist
- [ ] Remember me functionality
- [ ] Multi-device token management
- [ ] Token usage analytics

## Related Documentation

- `docs/ADD_MANAGER_API.md` - Manager API details
- `docs/MART_API_GUIDE.md` - Complete mart API documentation
- `docs/GENERATE_ADMIN_TOKEN.md` - Old manual token generation (deprecated)

---

**That's it!** Tokens are now generated automatically. Just register a mart or add a manager, and you'll get a token in the response! 🎉

