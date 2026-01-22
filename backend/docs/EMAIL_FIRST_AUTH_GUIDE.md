# Email-First OTP Authentication Guide

## Overview

The Laundry App uses **Email-First OTP (One-Time Password) Authentication** - a passwordless authentication system that provides a secure and cost-effective way to verify users. Unlike traditional SMS-based OTP systems, email OTP eliminates SMS costs while maintaining security and user experience.

## Why Email-First Authentication?

### Benefits

✅ **Cost-Effective**: No SMS charges - email is free  
✅ **Secure**: OTP codes expire in 5 minutes with rate limiting  
✅ **Universal**: Everyone has an email address  
✅ **Reliable**: Email delivery is more reliable than SMS in many regions  
✅ **No Passwords**: Users don't need to remember passwords  
✅ **Professional**: Branded email templates for better user experience  

### Trade-offs

⚠️ **Email Access Required**: Users must have access to their email  
⚠️ **Slightly Slower**: Email delivery can be slower than SMS (usually 1-10 seconds)  
⚠️ **Spam Filters**: OTP emails might land in spam (can be mitigated)  

---

## Architecture

### Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Email-First OTP Flow                      │
└─────────────────────────────────────────────────────────────┘

Step 1: User enters email address
        ↓
Step 2: Backend sends 6-digit OTP to email
        ↓
Step 3: User receives email and enters OTP
        ↓
Step 4: Backend verifies OTP
        ↓
        ├─ Existing User? ────→ Return JWT Token (Login Complete)
        │
        └─ New User? ──────────→ Return Session Token
                                 ↓
                                User completes profile information
                                 ↓
                                Backend creates account
                                 ↓
                                Return JWT Token (Registration Complete)
```

### User Types

The system supports four user types:

1. **Owner (Mart Admin)**: Manages laundry mart, requires mart details during registration
2. **Manager**: Staff member with admin privileges, belongs to a mart
3. **Customer**: End-users who place laundry orders
4. **Delivery Staff**: Delivery partners, belongs to a mart

---

## Database Schema

### OTP Verification Table

Stores OTP codes for email verification:

```prisma
model OtpVerification {
  otp_id       String   @id @default(uuid())
  email        String   @db.VarChar(255)
  otp_code     String   @db.VarChar(6)
  purpose      String   @db.VarChar(50)  // login_or_signup, email_change, password_reset
  user_type    String   @db.VarChar(30)  // owner, manager, customer, delivery_staff
  is_verified  Boolean  @default(false)
  expires_at   DateTime
  created_at   DateTime @default(now())
  attempts     Int      @default(0)
  max_attempts Int      @default(5)

  @@index([email, purpose])
  @@index([expires_at])
  @@map("otp_verifications")
}
```

### OTP Session Table

Tracks verified email sessions before registration completion:

```prisma
model OtpSession {
  session_id           String   @id @default(uuid())
  email                String   @db.VarChar(255)
  user_type            String   @db.VarChar(30)
  is_new_user          Boolean  // true = needs registration, false = existing user
  user_id              String?  // If existing user, store their ID
  mart_email           String?  @db.VarChar(255)     // For owner: verified mart email
  mart_email_verified  Boolean  @default(false)  // true when mart email OTP verified
  session_token String   @unique @db.VarChar(500)
  is_completed  Boolean  @default(false)
  expires_at    DateTime // Session expires in 30 minutes
  created_at    DateTime @default(now())

  @@index([email])
  @@index([session_token])
  @@map("otp_sessions")
}
```

### User Tables

Email is now the primary authentication identifier:

- **LaundryMart**: `contact_email` (required), `contact_phone` (optional)
- **User**: `email` (required, unique), `phone` (optional)
- **Customer**: `email` (required, unique), `phone` (optional)
- **DeliveryStaff**: `email` (required, unique), `phone` (optional)

No `password` field required - authentication is entirely via OTP.

---

## API Endpoints

### Owner Authentication

#### 1. Send OTP

```http
POST /api/v1/auth/owner/send-otp
Content-Type: application/json

{
  "email": "owner@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully to your email",
  "data": {
    "email": "owner@example.com",
    "expiresIn": 300
  }
}
```

#### 2. Verify OTP (Existing Owner)

```http
POST /api/v1/auth/owner/verify-otp
Content-Type: application/json

{
  "email": "owner@example.com",
  "otp": "123456"
}
```

**Response (Existing User):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "isNewUser": false,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "userId": "uuid",
      "email": "owner@example.com",
      "fullName": "John Doe",
      "role": "admin",
      "martId": "mart-uuid"
    }
  }
}
```

**Response (New User):**
```json
{
  "success": true,
  "message": "Email verified. Please complete your mart registration.",
  "data": {
    "isNewUser": true,
    "sessionToken": "abc123def456...",
    "expiresIn": 1800
  }
}
```

#### 3. Send OTP to Mart Email (New Owner)

After owner email is verified, verify the mart's business email:

```http
POST /api/v1/auth/owner/verify-mart-email/send-otp
Content-Type: application/json

{
  "sessionToken": "abc123def456...",
  "martEmail": "contact@cleanfresh.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully to mart email",
  "data": {
    "martEmail": "contact@cleanfresh.com",
    "expiresIn": 300
  }
}
```

#### 4. Verify Mart Email OTP (New Owner)

```http
POST /api/v1/auth/owner/verify-mart-email/verify-otp
Content-Type: application/json

{
  "sessionToken": "abc123def456...",
  "martEmail": "contact@cleanfresh.com",
  "otp": "789012"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Mart email verified successfully. You can now complete registration.",
  "data": {
    "martEmail": "contact@cleanfresh.com",
    "martEmailVerified": true
  }
}
```

#### 5. Complete Registration (New Owner)

After both emails are verified, submit all details in one request:

```http
POST /api/v1/auth/owner/complete-registration
Content-Type: application/json

{
  "sessionToken": "abc123def456...",
  "martData": {
    "martName": "Clean & Fresh Laundry",
    "martEmail": "contact@cleanfresh.com",
    "martContact": "+1234567890",
    "profileImageUrl": "https://s3.amazonaws.com/bucket/image.jpg",
    "martCoordinates": {
      "latitude": 28.6139,
      "longitude": 77.2090
    }
  },
  "ownerData": {
    "ownerName": "John Doe",
    "ownerPhone": "+1234567890",
    "ownerEmail": "owner@example.com"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration completed successfully. Welcome to Laundry App!",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "mart": {
      "mart_id": "uuid",
      "mart_name": "Clean & Fresh Laundry",
      "contact_email": "contact@cleanfresh.com",
      "contact_phone": "+1234567890",
      "is_active": true
    },
    "owner": {
      "user_id": "uuid",
      "full_name": "John Doe",
      "email": "owner@example.com",
      "phone": "+1234567890",
      "role": "admin"
    }
  }
}
```

> **Important:** The mart email verification (steps 3-4) must be completed before final registration. This ensures both the owner's personal email and the mart's business email are verified.

### Customer Authentication

#### 1. Send OTP

```http
POST /api/v1/auth/customer/send-otp
Content-Type: application/json

{
  "email": "customer@example.com"
}
```

#### 2. Verify OTP

```http
POST /api/v1/auth/customer/verify-otp
Content-Type: application/json

{
  "email": "customer@example.com",
  "otp": "123456"
}
```

#### 3. Complete Registration (New Customer)

```http
POST /api/v1/auth/customer/complete-registration
Content-Type: application/json

{
  "sessionToken": "abc123def456...",
  "customerData": {
    "fullName": "Jane Smith",
    "phone": "9876543210",
    "address": {
      "addressLabel": "home",
      "address": "123 Main Street, City, State, ZIP Code",
      "latitude": 37.7749,
      "longitude": -122.4194
    }
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration completed successfully. Welcome to Laundry App!",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "customer": {
      "customerId": "uuid",
      "fullName": "Jane Smith",
      "email": "customer@example.com",
      "phone": "9876543210",
      "address": {
        "addressId": "uuid",
        "addressLabel": "home",
        "address": "123 Main Street, City, State, ZIP Code",
        "latitude": "37.77490000",
        "longitude": "-122.41940000",
        "isDefault": true
      }
    }
  }
}
```

### Manager & Delivery Staff

Similar flow as Customer, with additional fields:

- **Manager**: Requires `martId` during registration
- **Delivery Staff**: Requires `vehicleType`, `vehicleNumber`, `address`, `currentCoordinates` and files (profile image, ID-proof doc, driving license doc)

Additional staff roles (Owner/Admin-created on first registration):

- **Collection Manager**: First-time profile creation must be completed by Owner/Admin (requires owner/admin JWT on `complete-registration`)
- **Distribution Manager**: First-time profile creation must be completed by Owner/Admin (requires owner/admin JWT on `complete-registration`)
- **Service Man**: First-time profile creation must be completed by Owner/Admin and must be linked to a service (1 service man per 1 service). `serviceId` or `serviceType` is required on send/verify/complete.

Collection Manager endpoints:
- `POST /api/v1/auth/collection-manager/send-otp`
- `POST /api/v1/auth/collection-manager/verify-otp`
- `POST /api/v1/auth/collection-manager/complete-registration` (requires `Authorization: Bearer <owner_or_admin_token>`)

Distribution Manager endpoints:
- `POST /api/v1/auth/distribution-manager/send-otp`
- `POST /api/v1/auth/distribution-manager/verify-otp`
- `POST /api/v1/auth/distribution-manager/complete-registration` (requires `Authorization: Bearer <owner_or_admin_token>`)

Service Man endpoints:
- `POST /api/v1/auth/service-man/send-otp` (requires `serviceId` or `serviceType`)
- `POST /api/v1/auth/service-man/verify-otp` (requires `serviceId` or `serviceType`)
- `POST /api/v1/auth/service-man/complete-registration` (requires `Authorization: Bearer <owner_or_admin_token>`; `serviceId` or `serviceType` required)

### Common Endpoints

#### Resend OTP

```http
POST /api/v1/auth/resend-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "userType": "customer"
}
```

#### Logout

```http
POST /api/v1/auth/logout
Authorization: Bearer <token>
```

---

## Email Service

### Development Mode

In development, OTP emails are logged to the console instead of being sent:

```
========================================
📧 OTP EMAIL (Development Mode)
========================================
To: user@example.com
Subject: Your Laundry App Verification Code
User Type: Customer
OTP Code: 123456
Expires: 5 minutes
========================================
```

### Production Mode (SMTP)

Configure email sending via SMTP:

```env
# SMTP Configuration
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE="false"
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-specific-password"
SMTP_FROM_EMAIL="Laundry App <noreply@laundryapp.com>"
```

#### Supported Email Providers

| Provider | SMTP Host | Port | Notes |
|----------|-----------|------|-------|
| **Gmail** | smtp.gmail.com | 587 | Requires App Password |
| **SendGrid** | smtp.sendgrid.net | 587 | Use API key as password |
| **AWS SES** | email-smtp.region.amazonaws.com | 587 | Use SMTP credentials |
| **Mailgun** | smtp.mailgun.org | 587 | Use SMTP credentials |
| **Mailjet** | in-v3.mailjet.com | 587 | Use API credentials |

#### Gmail Setup

1. Enable 2-Factor Authentication on your Google Account
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the generated password in `SMTP_PASSWORD`

---

## Security Features

### 1. OTP Expiry

OTPs expire after 5 minutes (configurable via `OTP_EXPIRY_MINUTES`).

### 2. Rate Limiting

Only 1 OTP request allowed per minute per email address.

```
⏱️ Rate Limit: 1 OTP / 60 seconds / email
```

### 3. Maximum Attempts

Users get 5 attempts to enter the correct OTP before needing a new one.

```
🔐 Max Attempts: 5 failed attempts
```

### 4. One-Time Use

OTPs can only be used once. After successful verification, they're marked as verified.

### 5. Session Expiry

Session tokens for new user registration expire after 30 minutes.

### 6. Email Normalization

Email addresses are normalized (lowercase, trimmed) to prevent duplicates.

---

## Email Templates

### OTP Email Template

Professional HTML email with:
- Branded header with app logo
- Large, easy-to-read OTP code
- Expiry warning
- Security reminder
- Mobile-responsive design

### Welcome Email Template

Sent after successful registration:
- Welcome message
- Feature highlights
- Getting started guide
- Contact information

---

## Environment Variables

```env
# OTP Settings
OTP_EXPIRY_MINUTES=5
OTP_MAX_ATTEMPTS=5
OTP_RATE_LIMIT_SECONDS=60

# SMTP Email Configuration
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE="false"
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-specific-password"
SMTP_FROM_EMAIL="Laundry App <noreply@laundryapp.com>"
```

---

## Testing

### Manual Testing

```bash
# Start server
npm run dev

# Test customer login/signup
curl -X POST http://localhost:3000/api/v1/auth/customer/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Check console for OTP code, then verify
curl -X POST http://localhost:3000/api/v1/auth/customer/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","otp":"123456"}'
```

### Automated Test Script

```bash
# Run comprehensive test script
node test-email-first-auth.js
```

---

## Frontend Integration

### React Example

```typescript
// Login Flow
async function handleLogin(email: string) {
  // Step 1: Send OTP
  const response1 = await fetch('/api/v1/auth/customer/send-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  
  // Show OTP input form
  setShowOtpInput(true);
}

async function handleVerifyOtp(email: string, otp: string) {
  // Step 2: Verify OTP
  const response = await fetch('/api/v1/auth/customer/verify-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, otp })
  });
  
  const data = await response.json();
  
  if (data.data.isNewUser) {
    // New user - show registration form
    setSessionToken(data.data.sessionToken);
    setShowRegistrationForm(true);
  } else {
    // Existing user - store token and redirect
    localStorage.setItem('token', data.data.token);
    router.push('/dashboard');
  }
}

async function handleCompleteRegistration(
  sessionToken: string,
  userData: any
) {
  // Step 3: Complete registration (new users only)
  const response = await fetch('/api/v1/auth/customer/complete-registration', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionToken, customerData: userData })
  });
  
  const data = await response.json();
  localStorage.setItem('token', data.data.token);
  router.push('/dashboard');
}
```

---

## Troubleshooting

### OTP Emails Not Received

1. **Check spam folder**: OTP emails might be marked as spam
2. **Verify SMTP credentials**: Ensure email configuration is correct
3. **Check email provider limits**: Some providers have daily send limits
4. **Review logs**: Check server logs for email sending errors

### "Invalid OTP" Error

1. **Check expiry**: OTPs expire after 5 minutes
2. **Verify attempts**: Only 5 attempts allowed per OTP
3. **Check email match**: Email must match exactly (case-insensitive)
4. **Use resend**: Request a new OTP if needed

### "Rate Limit Exceeded" Error

Wait 60 seconds before requesting another OTP.

### Session Expired

Session tokens expire after 30 minutes. Start the flow again if expired.

---

## Migration from Phone-First

If migrating from phone-first OTP:

1. **Clear old OTP data**:
   ```bash
   node clear-otp-and-migrate.js
   ```

2. **Run migration**:
   ```bash
   npm install nodemailer
   npx prisma migrate dev --name switch_to_email_first_auth
   ```

3. **Update environment variables**: Add SMTP configuration

4. **Update frontend**: Change from phone input to email input

5. **Test thoroughly**: Verify all user types work correctly

---

## Best Practices

✅ **Always validate email format** on frontend and backend  
✅ **Show clear error messages** for OTP failures  
✅ **Implement loading states** during OTP sending/verification  
✅ **Add countdown timer** for OTP resend button  
✅ **Store JWT token securely** (httpOnly cookies recommended)  
✅ **Handle network errors gracefully**  
✅ **Test with real email providers** before production  
✅ **Monitor email delivery rates** in production  
✅ **Set up email domain authentication** (SPF, DKIM, DMARC)  

---

## Production Checklist

- [ ] SMTP credentials configured
- [ ] Email domain verified
- [ ] SPF/DKIM/DMARC records set
- [ ] Email templates tested
- [ ] Rate limiting configured
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] JWT_SECRET changed from default
- [ ] Email delivery monitoring setup
- [ ] Spam filter testing completed

---

## Support

For issues or questions:
- Check server logs for detailed error messages
- Review email service provider documentation
- Ensure database migrations are up to date
- Verify environment variables are set correctly

---

**Last Updated**: November 3, 2025  
**Version**: 2.0.0 (Email-First)

