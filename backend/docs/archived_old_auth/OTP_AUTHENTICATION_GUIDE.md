# OTP-Based Passwordless Authentication System

## Overview

The Laundry App implements a **complete passwordless authentication system** using SMS OTP verification. All user types authenticate without passwords - authentication is done entirely through phone number verification via One-Time Passwords (OTP).

## Key Features

✅ **No Passwords** - No passwords stored in database  
✅ **Phone Verification** - All users verify their phone via OTP  
✅ **Multi-User Support** - Works for owners, managers, customers, and delivery staff  
✅ **Rate Limiting** - 1 OTP per minute per phone  
✅ **OTP Expiry** - OTPs expire after 5 minutes  
✅ **Max Attempts** - 5 failed attempts before requiring new OTP  
✅ **One-Time Use** - OTPs invalidated after successful verification  
✅ **JWT Tokens** - Secure JWT tokens issued after OTP verification  

---

## User Types

### 1. **Mart Owners (Admin)**
- **Signup**: Two-step OTP (verify mart phone + owner phone)
- **Login**: Phone OTP verification
- **Role**: `admin`

### 2. **Managers**
- **Signup**: Added by owner, phone verified via OTP
- **Login**: Phone OTP verification
- **Role**: `manager`

### 3. **Customers**
- **Signup**: Phone + profile details, verify via OTP
- **Login**: Phone OTP verification
- **Role**: `customer`

### 4. **Delivery Staff**
- **Signup**: Phone + vehicle details, verify via OTP
- **Login**: Phone OTP verification
- **Role**: `delivery_staff`

---

## Authentication Flows

### Mart Registration (Two-Step OTP)

**Step 1: Verify Mart Phone**
```bash
POST /api/v1/auth/mart/verify-phone/send-otp

Request:
{
  "phone": "9876543210",
  "martData": {
    "martName": "My Laundry Mart",
    "contactEmail": "contact@mymart.com",
    "address": "123 Main Street, City, State",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "serviceRadiusKm": {
      "maxRadius": 10,
      "tiers": [
        { "minKm": 0, "maxKm": 5, "pricePerKm": 20 },
        { "minKm": 5, "maxKm": 10, "pricePerKm": 40 }
      ]
    }
  }
}

Response:
{
  "success": true,
  "data": { "expiresIn": 300 },
  "message": "OTP sent to mart contact phone"
}
```

**Step 2: Verify Mart Phone OTP**
```bash
POST /api/v1/auth/mart/verify-phone/verify-otp

Request:
{
  "phone": "9876543210",
  "otp": "123456"
}

Response:
{
  "success": true,
  "data": {
    "verified": true,
    "message": "Mart phone verified. Now verify owner phone."
  }
}
```

**Step 3: Verify Owner Phone**
```bash
POST /api/v1/auth/mart/verify-owner/send-otp

Request:
{
  "phone": "9123456789",
  "ownerData": {
    "fullName": "John Doe",
    "email": "john@mymart.com"
  }
}

Response:
{
  "success": true,
  "data": { "expiresIn": 300 },
  "message": "OTP sent to owner phone"
}
```

**Step 4: Verify Owner Phone OTP**
```bash
POST /api/v1/auth/mart/verify-owner/verify-otp

Request:
{
  "phone": "9123456789",
  "otp": "654321"
}

Response:
{
  "success": true,
  "data": {
    "verified": true,
    "message": "Owner phone verified. You can now complete mart registration."
  }
}
```

**Step 5: Complete Registration**
```bash
POST /api/v1/marts/register

Request:
{
  "martName": "My Laundry Mart",
  "contactEmail": "contact@mymart.com",
  "contactPhone": "9876543210",
  "address": "123 Main Street, City, State",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "serviceRadiusKm": {
    "maxRadius": 10,
    "tiers": [
      { "minKm": 0, "maxKm": 5, "pricePerKm": 20 },
      { "minKm": 5, "maxKm": 10, "pricePerKm": 40 }
    ]
  },
  "owner": {
    "fullName": "John Doe",
    "email": "john@mymart.com",
    "phone": "9123456789"
  }
}

Response:
{
  "success": true,
  "data": {
    "mart": { ...mart details... },
    "owner": { ...owner details... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Mart registered successfully"
}
```

---

### Admin/Manager Login

**Step 1: Send OTP**
```bash
POST /api/v1/auth/admin/login/send-otp

Request:
{
  "phone": "9123456789"
}

Response:
{
  "success": true,
  "data": {
    "expiresIn": 300,
    "userName": "John Doe"
  },
  "message": "OTP sent to your phone"
}
```

**Step 2: Verify OTP & Login**
```bash
POST /api/v1/auth/admin/login/verify-otp

Request:
{
  "phone": "9123456789",
  "otp": "123456"
}

Response:
{
  "success": true,
  "data": {
    "user": {
      "user_id": "uuid",
      "full_name": "John Doe",
      "email": "john@mymart.com",
      "phone": "9123456789",
      "role": "admin",
      "is_phone_verified": true,
      "mart": { ...mart details... }
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Login successful"
}
```

---

### Manager Addition (by Owner)

**Step 1: Send OTP to Manager Phone** (Protected - requires admin auth)
```bash
POST /api/v1/auth/manager/add/send-otp
Authorization: Bearer <owner_token>

Request:
{
  "phone": "9234567890",
  "managerData": {
    "fullName": "Jane Manager",
    "email": "jane@mymart.com"
  }
}

Response:
{
  "success": true,
  "data": { "expiresIn": 300 },
  "message": "OTP sent to manager phone"
}
```

**Step 2: Verify OTP & Create Manager** (Protected - requires admin auth)
```bash
POST /api/v1/auth/manager/add/verify-otp
Authorization: Bearer <owner_token>

Request:
{
  "phone": "9234567890",
  "otp": "123456"
}

Response:
{
  "success": true,
  "data": {
    "manager": {
      "user_id": "uuid",
      "full_name": "Jane Manager",
      "email": "jane@mymart.com",
      "phone": "9234567890",
      "role": "manager",
      "is_phone_verified": true,
      "mart": { ...mart details... }
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Manager added successfully"
}
```

---

### Customer Signup

**Step 1: Send OTP**
```bash
POST /api/v1/auth/customer/signup/send-otp

Request:
{
  "phone": "9345678901",
  "fullName": "Alice Customer",
  "email": "alice@example.com"
}

Response:
{
  "success": true,
  "data": { "expiresIn": 300 },
  "message": "OTP sent to your phone"
}
```

**Step 2: Verify OTP & Create Account**
```bash
POST /api/v1/auth/customer/signup/verify-otp

Request:
{
  "phone": "9345678901",
  "otp": "123456"
}

Response:
{
  "success": true,
  "data": {
    "customer": {
      "customer_id": "uuid",
      "full_name": "Alice Customer",
      "email": "alice@example.com",
      "phone": "9345678901",
      "is_phone_verified": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Account created successfully"
}
```

---

### Customer Login

**Step 1: Send OTP**
```bash
POST /api/v1/auth/customer/login/send-otp

Request:
{
  "phone": "9345678901"
}

Response:
{
  "success": true,
  "data": {
    "expiresIn": 300,
    "userName": "Alice Customer"
  },
  "message": "OTP sent to your phone"
}
```

**Step 2: Verify OTP & Login**
```bash
POST /api/v1/auth/customer/login/verify-otp

Request:
{
  "phone": "9345678901",
  "otp": "123456"
}

Response:
{
  "success": true,
  "data": {
    "customer": {
      "customer_id": "uuid",
      "full_name": "Alice Customer",
      "email": "alice@example.com",
      "phone": "9345678901",
      "is_phone_verified": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Login successful"
}
```

---

### Delivery Staff Signup

**Step 1: Send OTP**
```bash
POST /api/v1/auth/delivery/signup/send-otp

Request:
{
  "phone": "9456789012",
  "fullName": "Bob Delivery",
  "email": "bob@example.com",
  "martId": "mart-uuid-here",
  "vehicleType": "bike",
  "vehicleNumber": "KA01AB1234",
  "licenseNumber": "KA1234567890"
}

Response:
{
  "success": true,
  "data": { "expiresIn": 300 },
  "message": "OTP sent to your phone"
}
```

**Step 2: Verify OTP & Create Account**
```bash
POST /api/v1/auth/delivery/signup/verify-otp

Request:
{
  "phone": "9456789012",
  "otp": "123456"
}

Response:
{
  "success": true,
  "data": {
    "deliveryStaff": {
      "staff_id": "uuid",
      "full_name": "Bob Delivery",
      "email": "bob@example.com",
      "phone": "9456789012",
      "vehicle_type": "bike",
      "vehicle_number": "KA01AB1234",
      "verification_status": "pending",
      "is_phone_verified": true,
      "is_active": false,
      "mart": { ...mart details... }
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "note": "Your account is pending approval from the mart admin."
  },
  "message": "Account created successfully"
}
```

---

### Resend OTP

Works for any authentication flow:

```bash
POST /api/v1/auth/resend-otp

Request:
{
  "phone": "9876543210",
  "otpType": "customer_login"
}

OTP Types:
- "mart_signup"
- "owner_signup"
- "manager_signup"
- "customer_signup"
- "customer_login"
- "delivery_signup"
- "delivery_login"
- "login"

Response:
{
  "success": true,
  "data": { "expiresIn": 300 },
  "message": "OTP resent successfully"
}
```

---

## Database Schema

### OTP Verification Table

```prisma
model OtpVerification {
  otp_id       String   @id @default(uuid())
  phone        String   @db.VarChar(20)
  otp_code     String   @db.VarChar(6)
  otp_type     String   @db.VarChar(30)
  user_type    String   @db.VarChar(30)
  user_data    Json?
  is_verified  Boolean  @default(false)
  expires_at   DateTime
  created_at   DateTime @default(now())
  attempts     Int      @default(0)
  max_attempts Int      @default(5)
}
```

### User Tables (Phone Verification Fields)

All user tables (`LaundryMart`, `User`, `Customer`, `DeliveryStaff`) have:

```prisma
phone             String   @unique @db.VarChar(20)
password          String?  @db.VarChar(255)  // Optional, null for OTP-based auth
is_phone_verified Boolean  @default(false)
```

---

## Security Features

### Rate Limiting
- **Limit**: 1 OTP request per minute per phone number
- **Purpose**: Prevent spam and abuse
- **Implementation**: Check for recent OTP requests within 60 seconds

### OTP Expiry
- **Duration**: 5 minutes
- **Purpose**: Prevent replay attacks
- **Implementation**: `expires_at` timestamp checked during verification

### Max Attempts
- **Limit**: 5 failed verification attempts
- **Purpose**: Prevent brute force attacks
- **Implementation**: `attempts` counter incremented on failed verification

### One-Time Use
- **Rule**: OTPs can only be used once
- **Implementation**: `is_verified` flag set to `true` after successful verification

### Phone Validation
- **Format**: 10-digit Indian mobile number
- **Pattern**: Must start with 6, 7, 8, or 9
- **Regex**: `/^[6-9]\d{9}$/`

### OTP Format
- **Length**: 6 digits
- **Pattern**: Numeric only
- **Regex**: `/^\d{6}$/`

---

## SMS Provider Integration

### Development Mode
```javascript
// OTPs logged to console, no SMS sent
if (process.env.NODE_ENV === 'development') {
  console.log(`OTP for ${phone}: ${otp}`);
}
```

### Production Mode (Twilio Example)
```javascript
const twilio = require('twilio')(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

await twilio.messages.create({
  body: `Your OTP for Laundry App is: ${otp}. Valid for 5 minutes.`,
  from: process.env.TWILIO_PHONE_NUMBER,
  to: `+91${phone}`
});
```

### Environment Variables
```env
# Development
NODE_ENV=development

# Production SMS Provider (Twilio)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# Production SMS Provider (MSG91 for India)
MSG91_AUTH_KEY=your_auth_key
MSG91_SENDER_ID=LNDRYAPP
MSG91_TEMPLATE_ID=your_template_id

# JWT Settings
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRY=7d
```

---

## JWT Token Structure

After successful OTP verification, a JWT token is issued:

```javascript
{
  user_id: "uuid",
  email: "user@example.com",
  role: "admin|manager|customer|delivery_staff",
  mart_id: "uuid",  // For admin/manager/delivery_staff
  full_name: "User Name",
  iat: 1234567890,
  exp: 1234567890
}
```

### Using JWT Token
```bash
GET /api/v1/orders
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Error Handling

### Common Errors

#### Phone Already Registered
```json
{
  "success": false,
  "message": "This phone number is already registered",
  "errorCode": "VALIDATION_ERROR"
}
```

#### Invalid OTP
```json
{
  "success": false,
  "message": "Invalid OTP code",
  "errorCode": "VALIDATION_ERROR"
}
```

#### OTP Expired
```json
{
  "success": false,
  "message": "OTP has expired. Please request a new one.",
  "errorCode": "VALIDATION_ERROR"
}
```

#### Max Attempts Exceeded
```json
{
  "success": false,
  "message": "Maximum attempts exceeded. Please request a new OTP.",
  "errorCode": "VALIDATION_ERROR"
}
```

#### Rate Limit Exceeded
```json
{
  "success": false,
  "message": "Please wait 1 minute before requesting another OTP",
  "errorCode": "RATE_LIMIT_ERROR"
}
```

---

## Testing

### Manual Testing (Development)

1. **Start Server**
   ```bash
   cd backend
   npm run dev
   ```

2. **Send OTP** (Check console for OTP code)
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/customer/login/send-otp \
     -H "Content-Type: application/json" \
     -d '{"phone": "9876543210"}'
   ```

3. **Verify OTP** (Use OTP from console)
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/customer/login/verify-otp \
     -H "Content-Type: application/json" \
     -d '{"phone": "9876543210", "otp": "123456"}'
   ```

4. **Use JWT Token**
   ```bash
   curl -X GET http://localhost:3000/api/v1/orders \
     -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
   ```

---

## Frontend Integration

### React Example (Customer Login)

```typescript
// auth.service.ts
export const customerLogin = async (phone: string, otp: string) => {
  // Step 1: Send OTP
  const sendResponse = await fetch('/api/v1/auth/customer/login/send-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone })
  });
  
  // Step 2: Verify OTP (after user enters it)
  const verifyResponse = await fetch('/api/v1/auth/customer/login/verify-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone, otp })
  });
  
  const data = await verifyResponse.json();
  
  // Store token
  if (data.success) {
    localStorage.setItem('token', data.data.token);
    localStorage.setItem('user', JSON.stringify(data.data.customer));
  }
  
  return data;
};
```

### Flutter Example (Customer Login)

```dart
// auth_service.dart
Future<AuthResponse> customerLogin(String phone, String otp) async {
  // Step 1: Send OTP
  final sendResponse = await http.post(
    Uri.parse('$baseUrl/auth/customer/login/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone}),
  );
  
  // Step 2: Verify OTP (after user enters it)
  final verifyResponse = await http.post(
    Uri.parse('$baseUrl/auth/customer/login/verify-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone, 'otp': otp}),
  );
  
  final data = jsonDecode(verifyResponse.body);
  
  // Store token
  if (data['success']) {
    await storage.write(key: 'token', value: data['data']['token']);
    await storage.write(key: 'user', value: jsonEncode(data['data']['customer']));
  }
  
  return AuthResponse.fromJson(data);
}
```

---

## Maintenance

### Cleanup Expired OTPs

Run periodically via cron job:

```javascript
// cleanup-otps.js
const otpService = require('./src/services/otp.service');

async function cleanup() {
  const count = await otpService.cleanupExpiredOTPs();
  console.log(`Cleaned up ${count} expired OTPs`);
}

cleanup();
```

**Cron Job (Every hour)**:
```bash
0 * * * * cd /path/to/backend && node cleanup-otps.js
```

---

## Best Practices

✅ **Never log OTP codes in production**  
✅ **Use HTTPS in production**  
✅ **Implement proper rate limiting**  
✅ **Monitor OTP delivery failures**  
✅ **Set up SMS provider alerts**  
✅ **Regularly cleanup expired OTPs**  
✅ **Track failed authentication attempts**  
✅ **Implement account lockout for suspicious activity**  
✅ **Use environment-specific SMS providers**  
✅ **Test OTP flow thoroughly before production**  

---

## Support

For issues or questions:
- Check the backend logs for detailed error messages
- Verify SMS provider credentials
- Ensure database is running and accessible
- Check rate limiting configuration
- Verify JWT_SECRET is set in environment variables

---

## Summary

The OTP-based passwordless authentication system provides a secure, user-friendly way to authenticate all user types without the complexity and security risks of password management. All authentication flows are designed to be simple, secure, and scalable.

