# Manager Registration API Documentation

## Overview

This endpoint allows mart owners to complete the registration of a new manager after the manager has verified their email via OTP. The endpoint requires owner authentication and validates that the owner owns the specified mart.

---

## Endpoint

```
POST /api/v1/auth/manager/complete-registration
```

## Authentication

**Required**: Owner/Admin JWT token in Authorization header

```http
Authorization: Bearer {owner_jwt_token}
```

**Note**: Only mart owners (`role: 'owner'`) or admins (`role: 'admin'`) can add managers to their mart.

---

## Prerequisites

1. **Manager OTP Verification**: The manager must complete the OTP flow first:
   - `POST /api/v1/auth/manager/send-otp` - Send OTP to manager's email
   - `POST /api/v1/auth/manager/verify-otp` - Verify OTP (returns `sessionToken`)

2. **Owner Authentication**: Owner must be logged in and have a valid JWT token

3. **Mart ID**: The `martId` in the request must match the owner's mart

---

## Request Format

### Headers

```http
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Request Body

```json
{
  "sessionToken": "abc123def456...",
  "managerData": {
    "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114",
    "fullName": "John Manager",
    "phone": "9876543210"
  }
}
```

### Field Descriptions

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `sessionToken` | string | Yes | Session token from manager's OTP verification | Valid session token |
| `managerData` | object | Yes | Manager registration data | - |
| `managerData.martId` | string (UUID) | Yes | ID of the laundry mart | Must be valid UUID, must match owner's mart |
| `managerData.fullName` | string | Yes | Full name of the manager | 2-255 characters |
| `managerData.phone` | string | Optional | Phone number of the manager | 10 digits (pattern: `^[0-9]{10}$`) or null/empty |

---

## Response Format

### Success Response (201 Created)

```json
{
  "success": true,
  "message": "Manager registration completed successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "manager": {
      "userId": "uuid",
      "fullName": "John Manager",
      "email": "manager@example.com",
      "role": "manager",
      "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114"
    },
    "owner": {
      "userId": "uuid",
      "fullName": "Owner Name",
      "email": "owner@example.com",
      "phone": "9876543210",
      "role": "owner",
      "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114"
    },
    "mart": {
      "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114",
      "martName": "Clean & Fresh Laundry",
      "contactEmail": "mart@example.com",
      "contactPhone": "9876543210",
      "address": "123 Main Street, City, State",
      "profileImageUrl": "https://s3.amazonaws.com/..."
    }
  }
}
```

### Response Field Descriptions

#### Manager Object
- `userId`: Unique identifier for the manager
- `fullName`: Manager's full name
- `email`: Manager's email (from OTP verification)
- `role`: Always `"manager"`
- `martId`: ID of the mart the manager belongs to

#### Owner Object
- `userId`: Unique identifier for the owner
- `fullName`: Owner's full name
- `email`: Owner's email
- `phone`: Owner's phone number (optional)
- `role`: Owner's role (`"owner"` or `"admin"`)
- `martId`: ID of the owner's mart

#### Mart Object
- `martId`: Unique identifier for the mart
- `martName`: Name of the laundry mart
- `contactEmail`: Mart's contact email
- `contactPhone`: Mart's contact phone
- `address`: Mart's physical address
- `profileImageUrl`: URL to mart's profile image (optional)

---

## Error Responses

### 400 Bad Request - Validation Error

```json
{
  "success": false,
  "message": "Validation failed",
  "errorCode": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "managerData.fullName",
      "message": "Manager name must be at least 2 characters"
    }
  ],
  "timestamp": "2025-11-04T12:00:00.000Z",
  "path": "/api/v1/auth/manager/complete-registration"
}
```

### 401 Unauthorized - Missing or Invalid Token

```json
{
  "success": false,
  "message": "No token provided",
  "errorCode": "AUTHENTICATION_ERROR",
  "timestamp": "2025-11-04T12:00:00.000Z",
  "path": "/api/v1/auth/manager/complete-registration"
}
```

### 403 Forbidden - Authorization Error

**Case 1: Not Owner/Admin**
```json
{
  "success": false,
  "message": "Only mart owners can add managers",
  "errorCode": "AUTHORIZATION_ERROR",
  "timestamp": "2025-11-04T12:00:00.000Z",
  "path": "/api/v1/auth/manager/complete-registration"
}
```

**Case 2: Mart ID Mismatch**
```json
{
  "success": false,
  "message": "Mart ID does not match owner's mart",
  "errorCode": "AUTHORIZATION_ERROR",
  "details": {
    "ownerMartId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114",
    "requestMartId": "different-mart-id"
  },
  "timestamp": "2025-11-04T12:00:00.000Z",
  "path": "/api/v1/auth/manager/complete-registration"
}
```

### 404 Not Found - Mart Not Found

```json
{
  "success": false,
  "message": "Mart not found",
  "errorCode": "NOT_FOUND",
  "timestamp": "2025-11-04T12:00:00.000Z",
  "path": "/api/v1/auth/manager/complete-registration"
}
```

### 409 Conflict - Manager Already Exists

```json
{
  "success": false,
  "message": "Manager with this email already exists",
  "errorCode": "DUPLICATE_ERROR",
  "timestamp": "2025-11-04T12:00:00.000Z",
  "path": "/api/v1/auth/manager/complete-registration"
}
```

---

## Example cURL Request

```bash
curl -X POST http://localhost:3000/api/v1/auth/manager/complete-registration \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "sessionToken": "abc123def456...",
    "managerData": {
      "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114",
      "fullName": "John Manager",
      "phone": "9876543210"
    }
  }'
```

---

## Example JavaScript/TypeScript Request

```javascript
const addManager = async (ownerToken, sessionToken, managerData) => {
  try {
    const response = await fetch('http://localhost:3000/api/v1/auth/manager/complete-registration', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${ownerToken}`
      },
      body: JSON.stringify({
        sessionToken,
        managerData: {
          martId: managerData.martId,
          fullName: managerData.fullName,
          phone: managerData.phone
        }
      })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Failed to register manager');
    }

    return data;
  } catch (error) {
    console.error('Manager registration error:', error);
    throw error;
  }
};

// Usage
const result = await addManager(
  'owner_jwt_token',
  'session_token_from_otp_verification',
  {
    martId: '35d9cc0e-eda6-49bd-a757-40b94dc2d114',
    fullName: 'John Manager',
    phone: '9876543210'
  }
);

console.log('Manager registered:', result.data.manager);
console.log('Manager token:', result.data.token);
```

---

## Complete Flow Example

### Step 1: Owner sends OTP to manager's email

```bash
curl -X POST http://localhost:3000/api/v1/auth/manager/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "manager@example.com"}'
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "email": "manager@example.com",
    "expiresIn": 300
  }
}
```

### Step 2: Manager verifies OTP

```bash
curl -X POST http://localhost:3000/api/v1/auth/manager/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@example.com",
    "otp": "123456"
  }'
```

**Response (New Manager):**
```json
{
  "success": true,
  "message": "Email verified. Please complete your registration.",
  "data": {
    "isNewUser": true,
    "sessionToken": "abc123def456...",
    "expiresIn": 1800
  }
}
```

### Step 3: Owner completes manager registration

```bash
curl -X POST http://localhost:3000/api/v1/auth/manager/complete-registration \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {owner_token}" \
  -d '{
    "sessionToken": "abc123def456...",
    "managerData": {
      "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114",
      "fullName": "John Manager",
      "phone": "9876543210"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Manager registration completed successfully",
  "data": {
    "token": "manager_jwt_token...",
    "manager": {
      "userId": "uuid",
      "fullName": "John Manager",
      "email": "manager@example.com",
      "role": "manager",
      "martId": "35d9cc0e-eda6-49bd-a757-40b94dc2d114"
    },
    "owner": { ... },
    "mart": { ... }
  }
}
```

---

## Security Notes

1. **Owner Authentication**: Only authenticated owners/admins can add managers
2. **Mart Ownership Verification**: System verifies that the owner owns the specified mart
3. **Session Token Expiry**: Session tokens expire after 30 minutes
4. **Email Verification**: Manager's email must be verified via OTP before registration
5. **One-Time Session**: Session tokens can only be used once

---

## Notes

- The `martId` in `managerData` must exactly match the owner's `mart_id`
- The `sessionToken` must be from a manager OTP verification session
- The manager's email is automatically set from the OTP verification session
- The manager's role is automatically set to `"manager"`
- The manager receives a JWT token upon successful registration for future authentication

---

## Related Endpoints

- `POST /api/v1/auth/manager/send-otp` - Send OTP to manager's email
- `POST /api/v1/auth/manager/verify-otp` - Verify OTP and get session token
- `POST /api/v1/auth/resend-otp` - Resend OTP if needed

## Related Staff Registration Docs (Architecture v2 Roles)

These roles follow the same pattern (OTP login, and first-time profile creation completed by Owner/Admin):

- **Collection Manager / Distribution Manager / Service Man** → [STAFF_REGISTRATION_API.md](STAFF_REGISTRATION_API.md)

---

**Last Updated**: November 4, 2025

