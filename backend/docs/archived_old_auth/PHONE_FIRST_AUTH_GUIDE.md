# Phone-First OTP Authentication Guide

## Overview

The Laundry App uses a **phone-first OTP authentication system** that provides a seamless user experience:

1. User enters phone number → OTP sent
2. User verifies OTP → System checks if user exists
   - **Existing user**: Logged in automatically with JWT token
   - **New user**: Prompted to complete registration with profile details
3. New user completes registration → Account created and JWT token issued

This approach eliminates the need for passwords and provides a smooth onboarding experience.

---

## Table of Contents

- [Authentication Flow](#authentication-flow)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Implementation Details](#implementation-details)
- [Testing](#testing)
- [Frontend Integration](#frontend-integration)
- [Security Considerations](#security-considerations)

---

## Authentication Flow

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHONE-FIRST AUTH FLOW                         │
└─────────────────────────────────────────────────────────────────┘

Step 1: User enters phone number
   ↓
   POST /auth/{userType}/send-otp { phone }
   ↓
   OTP sent to phone (SMS or Console in dev)

Step 2: User enters OTP code
   ↓
   POST /auth/{userType}/verify-otp { phone, otp }
   ↓
   System checks if user exists

   ┌─────────────────┬─────────────────────┐
   │ User EXISTS     │ User DOES NOT EXIST │
   └─────────────────┴─────────────────────┘
          │                      │
          ↓                      ↓
   Return JWT Token      Return Session Token
   (Login Complete)      (Registration Required)
          │                      │
          ↓                      ↓
   User Dashboard        Show Registration Form

                                 ↓
                    Step 3: User enters profile details
                                 ↓
                    POST /auth/{userType}/complete-registration
                    { sessionToken, userData }
                                 ↓
                    Account Created + JWT Token Issued
                                 ↓
                    User Dashboard
```

---

## Database Schema

### OtpVerification Table

Stores OTP codes for verification:

```sql
CREATE TABLE otp_verifications (
  otp_id       UUID PRIMARY KEY,
  phone        VARCHAR(20) NOT NULL,
  otp_code     VARCHAR(6) NOT NULL,
  purpose      VARCHAR(50) NOT NULL,  -- 'login_or_signup', 'phone_change', 'password_reset'
  user_type    VARCHAR(30) NOT NULL,  -- 'owner', 'manager', 'customer', 'delivery_staff'
  is_verified  BOOLEAN DEFAULT false,
  expires_at   TIMESTAMP NOT NULL,
  created_at   TIMESTAMP DEFAULT NOW(),
  attempts     INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 5
);

CREATE INDEX idx_otp_phone_purpose ON otp_verifications(phone, purpose);
CREATE INDEX idx_otp_expires ON otp_verifications(expires_at);
```

### OtpSession Table

Tracks verified phone sessions before registration completion:

```sql
CREATE TABLE otp_sessions (
  session_id    UUID PRIMARY KEY,
  phone         VARCHAR(20) NOT NULL,
  user_type     VARCHAR(30) NOT NULL,  -- 'owner', 'manager', 'customer', 'delivery_staff'
  is_new_user   BOOLEAN NOT NULL,      -- true = needs registration, false = logged in
  user_id       UUID,                  -- If existing user, their ID
  session_token VARCHAR(500) UNIQUE NOT NULL,  -- Temporary session token
  is_completed  BOOLEAN DEFAULT false, -- true when registration is completed
  expires_at    TIMESTAMP NOT NULL,    -- Session expires in 30 minutes
  created_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_session_phone ON otp_sessions(phone);
CREATE INDEX idx_session_token ON otp_sessions(session_token);
CREATE INDEX idx_session_expires ON otp_sessions(expires_at);
```

---

## API Endpoints

### 1. Owner Authentication

#### Send OTP
```http
POST /api/v1/auth/owner/send-otp
Content-Type: application/json

{
  "phone": "9876543210"
}

Response (200):
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "phone": "9876543210",
    "expiresIn": 300  // seconds
  }
}
```

#### Verify OTP
```http
POST /api/v1/auth/owner/verify-otp
Content-Type: application/json

{
  "phone": "9876543210",
  "otp": "123456"
}

Response (200) - Existing User:
{
  "success": true,
  "message": "Login successful",
  "data": {
    "isNewUser": false,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "phone": "9876543210",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "admin",
      "martId": "mart-uuid",
      "martName": "Clean & Fresh Laundry"
    }
  }
}

Response (200) - New User:
{
  "success": true,
  "message": "OTP verified. Please complete registration.",
  "data": {
    "isNewUser": true,
    "sessionToken": "abc123def456...",
    "expiresIn": 1800  // 30 minutes
  }
}
```

#### Complete Registration
```http
POST /api/v1/auth/owner/complete-registration
Content-Type: application/json

{
  "sessionToken": "abc123def456...",
  "martData": {
    "martName": "Clean & Fresh Laundry",
    "contactEmail": "contact@cleanfresh.com",
    "contactPhone": "9876543211",
    "address": "123 Main Street, City, State",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "serviceRadiusKm": {
      "0-5": 20,
      "5-10": 40,
      "10-15": 60
    }
  },
  "ownerData": {
    "fullName": "John Doe",
    "email": "john@example.com"
  }
}

Response (201):
{
  "success": true,
  "message": "Registration completed successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "mart": {
      "id": "mart-uuid",
      "name": "Clean & Fresh Laundry",
      "email": "contact@cleanfresh.com",
      "phone": "9876543211",
      "address": "123 Main Street, City, State"
    },
    "owner": {
      "id": "user-uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210",
      "role": "admin"
    }
  }
}
```

### 2. Manager Authentication

Same flow as Owner, but with different endpoints:
- `POST /api/v1/auth/manager/send-otp`
- `POST /api/v1/auth/manager/verify-otp`
- `POST /api/v1/auth/manager/complete-registration`

Registration payload:
```json
{
  "sessionToken": "abc123...",
  "managerData": {
    "martId": "mart-uuid",
    "fullName": "Jane Smith",
    "email": "jane@example.com"
  }
}
```

### 3. Customer Authentication

Same flow as Owner, but with different endpoints:
- `POST /api/v1/auth/customer/send-otp`
- `POST /api/v1/auth/customer/verify-otp`
- `POST /api/v1/auth/customer/complete-registration`

Registration payload:
```json
{
  "sessionToken": "abc123...",
  "customerData": {
    "fullName": "Alice Johnson",
    "email": "alice@example.com"
  }
}
```

### 4. Delivery Staff Authentication

Same flow as Owner, but with different endpoints:
- `POST /api/v1/auth/delivery/send-otp`
- `POST /api/v1/auth/delivery/verify-otp`
- `POST /api/v1/auth/delivery/complete-registration`

Registration payload:
```json
{
  "sessionToken": "abc123...",
  "deliveryData": {
    "martId": "mart-uuid",
    "fullName": "Bob Wilson",
    "email": "bob@example.com",
    "vehicleType": "bike",
    "vehicleNumber": "DL01AB1234",
    "licenseNumber": "DL123456789"
  }
}
```

### 5. Common Endpoints

#### Resend OTP
```http
POST /api/v1/auth/resend-otp
Content-Type: application/json

{
  "phone": "9876543210",
  "userType": "owner"  // or "manager", "customer", "delivery_staff"
}
```

#### Logout
```http
POST /api/v1/auth/logout
Authorization: Bearer <token>

Response (200):
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## Implementation Details

### OTP Service (`src/services/otp.service.js`)

Key functions:

- **`sendOtp(phone, userType)`**: Send OTP to phone number
  - Validates user type
  - Checks rate limiting (60 seconds between requests)
  - Generates 6-digit OTP
  - Saves to database
  - Sends SMS (Twilio in production, console in development)

- **`verifyOtp(phone, otp, userType)`**: Verify OTP and check if user exists
  - Validates OTP code
  - Checks expiry and attempt limits
  - Searches for existing user in appropriate table
  - **Existing user**: Updates `is_phone_verified`, returns JWT token
  - **New user**: Creates OTP session with session token

- **`completeOwnerRegistration(sessionToken, martData, ownerData)`**: Complete owner + mart registration
  - Validates session token
  - Creates mart and owner in a transaction
  - Returns JWT token

- **`completeManagerRegistration(sessionToken, managerData)`**: Complete manager registration
- **`completeCustomerRegistration(sessionToken, customerData)`**: Complete customer registration
- **`completeDeliveryRegistration(sessionToken, deliveryData)`**: Complete delivery staff registration

- **`resendOtp(phone, userType)`**: Resend OTP (alias for `sendOtp`)

- **`cleanupExpired()`**: Clean up expired OTPs and sessions (can be run as a cron job)

### SMS Provider Integration

The system uses Twilio for SMS delivery in production:

```javascript
// Environment variables
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone

// In development without Twilio: Logs to console
// In production or development with Twilio: Sends real SMS
```

---

## Testing

### Manual Testing with cURL

See `test-phone-first-auth.js` for comprehensive test examples.

**Example: Owner Login/Signup Flow**

```bash
# Step 1: Send OTP
curl -X POST http://localhost:3000/api/v1/auth/owner/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210"}'

# Check console for OTP (in development)

# Step 2: Verify OTP (existing user - logs in)
curl -X POST http://localhost:3000/api/v1/auth/owner/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","otp":"123456"}'

# Returns: { isNewUser: false, token, user }

# OR

# Step 2: Verify OTP (new user - needs registration)
curl -X POST http://localhost:3000/api/v1/auth/owner/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9999999999","otp":"123456"}'

# Returns: { isNewUser: true, sessionToken, expiresIn }

# Step 3: Complete registration (only for new users)
curl -X POST http://localhost:3000/api/v1/auth/owner/complete-registration \
  -H "Content-Type: application/json" \
  -d '{
    "sessionToken": "abc123...",
    "martData": {
      "martName": "New Laundry",
      "contactEmail": "new@laundry.com",
      "contactPhone": "9999999998",
      "address": "456 Street, City",
      "latitude": 28.5,
      "longitude": 77.5
    },
    "ownerData": {
      "fullName": "New Owner",
      "email": "owner@laundry.com"
    }
  }'

# Returns: { token, mart, owner }
```

---

## Frontend Integration

### React (Admin Panel)

```typescript
// 1. Send OTP
const sendOtp = async (phone: string, userType: 'owner' | 'manager') => {
  const response = await fetch(`/api/v1/auth/${userType}/send-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone })
  });
  return response.json();
};

// 2. Verify OTP
const verifyOtp = async (phone: string, otp: string, userType: string) => {
  const response = await fetch(`/api/v1/auth/${userType}/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone, otp })
  });
  const data = await response.json();
  
  if (data.data.isNewUser) {
    // Show registration form
    return { needsRegistration: true, sessionToken: data.data.sessionToken };
  } else {
    // Save token and redirect to dashboard
    localStorage.setItem('token', data.data.token);
    return { needsRegistration: false, user: data.data.user };
  }
};

// 3. Complete registration (if needed)
const completeRegistration = async (
  sessionToken: string,
  martData: any,
  ownerData: any,
  userType: string
) => {
  const response = await fetch(`/api/v1/auth/${userType}/complete-registration`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionToken, martData, ownerData })
  });
  const data = await response.json();
  localStorage.setItem('token', data.data.token);
  return data.data;
};
```

### Flutter (Mobile Apps)

```dart
// 1. Send OTP
Future<void> sendOtp(String phone, String userType) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/$userType/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone}),
  );
  return jsonDecode(response.body);
}

// 2. Verify OTP
Future<Map<String, dynamic>> verifyOtp(
  String phone,
  String otp,
  String userType,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/$userType/verify-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone, 'otp': otp}),
  );
  final data = jsonDecode(response.body);
  
  if (data['data']['isNewUser']) {
    // Navigate to registration screen
    return {
      'needsRegistration': true,
      'sessionToken': data['data']['sessionToken']
    };
  } else {
    // Save token and navigate to home
    await storage.write(key: 'token', value: data['data']['token']);
    return {'needsRegistration': false, 'user': data['data']['user']};
  }
}

// 3. Complete registration
Future<void> completeRegistration(
  String sessionToken,
  Map<String, dynamic> userData,
  String userType,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/$userType/complete-registration'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'sessionToken': sessionToken,
      '${userType}Data': userData,
    }),
  );
  final data = jsonDecode(response.body);
  await storage.write(key: 'token', value: data['data']['token']);
}
```

---

## Security Considerations

### OTP Security

1. **Rate Limiting**: Max 1 OTP request per 60 seconds per phone
2. **Expiry**: OTPs expire after 5 minutes
3. **Attempt Limiting**: Max 5 verification attempts per OTP
4. **One-time Use**: OTP is marked as verified and cannot be reused

### Session Security

1. **Session Expiry**: Session tokens expire after 30 minutes
2. **One-time Completion**: Session can only be used once for registration
3. **Validation**: Session is validated before allowing registration

### JWT Security

1. **Secret Key**: Strong JWT secret stored in environment variables
2. **Expiry**: Tokens expire after 7 days (configurable)
3. **Payload**: Contains minimal data (userId, phone, role, martId)

### Phone Verification

1. **Phone Uniqueness**: Enforced at database level with unique constraints
2. **Verification Flag**: `is_phone_verified` flag updated after OTP verification
3. **No Passwords**: System is completely passwordless, reducing password-related vulnerabilities

---

## Environment Variables

```env
# OTP Configuration
OTP_EXPIRY_MINUTES=5
OTP_MAX_ATTEMPTS=5
OTP_RATE_LIMIT_SECONDS=60

# Twilio Configuration (Production)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_min_32_chars
JWT_EXPIRY=7d
```

---

## Best Practices

### Development

1. **Console Logging**: In development without Twilio, OTPs are logged to console
2. **Test Numbers**: Use consistent test phone numbers for testing
3. **Clear Sessions**: Regularly clean up expired OTPs and sessions

### Production

1. **Twilio Setup**: Configure Twilio credentials for SMS delivery
2. **Monitoring**: Monitor OTP delivery success rates
3. **Rate Limiting**: Implement additional rate limiting at API gateway level
4. **Logging**: Log authentication events for security auditing
5. **Cron Jobs**: Set up cron job to clean up expired records daily

---

## Troubleshooting

### OTP Not Received

- Check if Twilio credentials are configured
- Check phone number format (must be 10 digits)
- Check rate limiting (wait 60 seconds between requests)
- In development: Check console output

### Invalid OTP Error

- Check if OTP has expired (5 minutes)
- Check if max attempts exceeded (5 attempts)
- Ensure correct OTP code from SMS/console

### Session Expired Error

- Session tokens expire after 30 minutes
- Request new OTP and verify again to get fresh session token

### Registration Failed

- Check if phone number is already registered
- Verify all required fields are provided
- Check database constraints (email uniqueness, etc.)

---

## Migration from Old System

If migrating from the previous multi-step OTP system:

1. **Database Migration**: Run `npx prisma migrate dev --name phone_first_auth_flow`
2. **Clear Old Sessions**: Old OTP records are automatically cleared
3. **Update Frontend**: Update all authentication UI to new flow
4. **Test Thoroughly**: Test all user types (owner, manager, customer, delivery)

---

## Future Enhancements

1. **Biometric Authentication**: Add fingerprint/face ID after initial OTP login
2. **Remember Device**: Option to remember device and skip OTP
3. **Social Login**: Add Google/Facebook login as alternatives
4. **Magic Links**: Email magic links as alternative to OTP
5. **Multi-factor Auth**: Optional second factor for high-security accounts

---

## Support

For issues or questions:
- Check logs in `backend/logs/`
- Review error responses for detailed error codes
- Refer to API documentation in Swagger UI
- Contact development team

---

**Last Updated**: November 3, 2025
**Version**: 2.0 (Phone-First Authentication)

