# Mart Owner Registration Flow

## Overview

The mart owner registration process uses a **two-step email verification** approach to ensure both the owner's personal email and the mart's business email are verified before registration is completed.

---

## Registration Flow Steps

### Step 1: Verify Owner Email

**Endpoint:** `POST /api/v1/auth/owner/send-otp`

The owner enters their personal email address.

```json
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

---

### Step 2: Verify Owner OTP

**Endpoint:** `POST /api/v1/auth/owner/verify-otp`

The owner enters the OTP received via email.

```json
{
  "email": "owner@example.com",
  "otp": "123456"
}
```

**Response (New Owner):**
```json
{
  "success": true,
  "message": "Email verified. Please complete your mart registration.",
  "data": {
    "isNewUser": true,
    "sessionToken": "abc123xyz456...",
    "expiresIn": 1800
  }
}
```

**Response (Existing Owner - Login):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "isNewUser": false,
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "userId": "user-uuid",
      "email": "owner@example.com",
      "fullName": "John Doe",
      "role": "admin",
      "martId": "mart-uuid",
      "mart": {
        "mart_id": "mart-uuid",
        "mart_name": "Clean & Fresh Laundry",
        "contact_email": "contact@cleanfresh.com"
      }
    }
  }
}
```

---

### Step 3: Verify Mart Email

**Endpoint:** `POST /api/v1/auth/owner/verify-mart-email/send-otp`

The owner provides the mart's business email (which may be different from their personal email).

```json
{
  "sessionToken": "abc123xyz456...",
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

**Important Notes:**
- The mart email must be unique (not already registered)
- The session token from Step 2 must be valid
- OTP will be sent to the mart email address

---

### Step 4: Verify Mart Email OTP

**Endpoint:** `POST /api/v1/auth/owner/verify-mart-email/verify-otp`

The owner enters the OTP received at the mart email.

```json
{
  "sessionToken": "abc123xyz456...",
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

---

### Step 5: Complete Registration

**Endpoint:** `POST /api/v1/auth/owner/complete-registration`

After both emails are verified, submit all mart and owner details in one request.

```json
{
  "sessionToken": "abc123xyz456...",
  "martData": {
    "martName": "Clean & Fresh Laundry",
    "martEmail": "contact@cleanfresh.com",
    "martContact": "+1234567890",
    "profileImageUrl": "https://s3.amazonaws.com/bucket/image.jpg",
    "martCoordinates": {
      "latitude": 37.7749,
      "longitude": -122.4194
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
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "mart": {
      "mart_id": "mart-uuid",
      "mart_name": "Clean & Fresh Laundry",
      "contact_email": "contact@cleanfresh.com",
      "contact_phone": "+1234567890",
      "latitude": "37.77490000",
      "longitude": "-122.41940000",
      "is_active": true,
      "created_at": "2025-11-04T05:59:05.000Z"
    },
    "owner": {
      "user_id": "user-uuid",
      "mart_id": "mart-uuid",
      "full_name": "John Doe",
      "email": "owner@example.com",
      "phone": "+1234567890",
      "role": "admin",
      "is_active": true,
      "created_at": "2025-11-04T05:59:05.000Z"
    }
  }
}
```

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    MART OWNER REGISTRATION                  │
└─────────────────────────────────────────────────────────────┘

Step 1: Owner Email Entry
┌──────────────────────┐
│ Enter owner email    │
│ owner@example.com    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ POST /owner/send-otp │
└──────────┬───────────┘
           │
           ▼
    ┌──────────────┐
    │  OTP sent    │
    │  via email   │
    └──────┬───────┘
           │
           ▼

Step 2: Owner OTP Verification
┌──────────────────────────┐
│ Enter OTP: 123456        │
└──────────┬───────────────┘
           │
           ▼
┌───────────────────────────┐
│ POST /owner/verify-otp    │
└──────────┬────────────────┘
           │
           ▼
    ┌─────────────────┐
    │ Is new user?    │
    └────┬─────┬──────┘
         │     │
    YES  │     │  NO
         │     │
         │     └────────────────────────┐
         │                              │
         ▼                              ▼
┌────────────────────┐         ┌────────────────┐
│ Get sessionToken   │         │ Login Complete │
└────────┬───────────┘         │ Return JWT     │
         │                     └────────────────┘
         │
         ▼

Step 3: Mart Email Entry
┌──────────────────────────────────┐
│ Enter mart email                 │
│ contact@cleanfresh.com           │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ POST /owner/verify-mart-email/       │
│      send-otp                        │
│ Body: { sessionToken, martEmail }   │
└──────────┬───────────────────────────┘
           │
           ▼
    ┌─────────────────┐
    │  OTP sent to    │
    │  mart email     │
    └────────┬────────┘
             │
             ▼

Step 4: Mart Email OTP Verification
┌──────────────────────────┐
│ Enter OTP: 789012        │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ POST /owner/verify-mart-email/       │
│      verify-otp                      │
│ Body: { sessionToken, martEmail,    │
│        otp }                         │
└──────────┬───────────────────────────┘
           │
           ▼
    ┌──────────────────────┐
    │ Mart email verified  │
    └──────────┬───────────┘
               │
               ▼

Step 5: Complete Registration
┌──────────────────────────────────────┐
│ Submit all details:                  │
│ • Mart: name, email, contact,        │
│   coordinates, image                 │
│ • Owner: name, phone, email          │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ POST /owner/complete-registration    │
│ Body: { sessionToken, martData,     │
│         ownerData }                  │
└──────────┬───────────────────────────┘
           │
           ▼
    ┌─────────────────────────┐
    │ Registration Complete!  │
    │ Return JWT Token        │
    │ Mart & Owner Created    │
    └─────────────────────────┘
```

---

## Data Requirements

### Mart Data
- **martName** (required): Name of the laundry mart
- **martEmail** (required): Verified business email
- **martContact** (optional): Contact phone number
- **profileImageUrl** (optional): URL to mart profile image (uploaded to S3)
- **martCoordinates** (required): GPS coordinates
  - `latitude`: Decimal number
  - `longitude`: Decimal number

### Owner Data
- **ownerName** (required): Full name of the owner
- **ownerPhone** (optional): Owner's contact phone
- **ownerEmail** (required): Owner's personal email (same as Step 1)

---

## Validation Rules

### Email Validation
- Both owner email and mart email must be valid email addresses
- Emails are normalized to lowercase
- Mart email must be unique (not already registered)
- Owner email must match the email verified in Step 1

### OTP Validation
- OTP expires in 5 minutes
- Maximum 5 verification attempts per OTP
- Rate limit: 1 OTP per email per minute

### Session Validation
- Session token expires in 30 minutes
- Session token is single-use (marked completed after registration)
- Mart email must be verified before completing registration

### Coordinates Validation
- Latitude: -90 to 90
- Longitude: -180 to 180

---

## Error Handling

### Common Errors

**Invalid Session Token**
```json
{
  "success": false,
  "message": "Invalid or expired session token",
  "errorCode": "AUTHENTICATION_ERROR"
}
```

**Mart Email Not Verified**
```json
{
  "success": false,
  "message": "Mart email must be verified before completing registration",
  "errorCode": "VALIDATION_ERROR"
}
```

**Mart Email Already Registered**
```json
{
  "success": false,
  "message": "This mart email is already registered",
  "errorCode": "VALIDATION_ERROR"
}
```

**OTP Expired**
```json
{
  "success": false,
  "message": "OTP has expired. Please request a new one.",
  "errorCode": "AUTHENTICATION_ERROR"
}
```

**Invalid OTP**
```json
{
  "success": false,
  "message": "Invalid OTP. 4 attempt(s) remaining.",
  "errorCode": "AUTHENTICATION_ERROR"
}
```

---

## Database Schema

### OtpSession Table
```sql
CREATE TABLE otp_sessions (
  session_id           UUID PRIMARY KEY,
  email                VARCHAR(255),
  user_type            VARCHAR(30),
  is_new_user          BOOLEAN,
  user_id              UUID,
  session_token        VARCHAR(500) UNIQUE,
  is_completed         BOOLEAN DEFAULT false,
  mart_email           VARCHAR(255),      -- NEW: Verified mart email
  mart_email_verified  BOOLEAN DEFAULT false,  -- NEW: Mart email verification status
  expires_at           TIMESTAMP,
  created_at           TIMESTAMP DEFAULT NOW()
);
```

### Key Fields
- `mart_email`: Stores the mart's business email after verification
- `mart_email_verified`: Boolean flag indicating if mart email OTP was verified
- These fields are only used for owner registration flow

---

## Security Considerations

1. **Two-Factor Email Verification**: Both personal and business emails must be verified
2. **Time-Limited Sessions**: Session tokens expire in 30 minutes
3. **Rate Limiting**: Prevents OTP spam attacks
4. **Unique Mart Emails**: Prevents duplicate mart registrations
5. **OTP Attempt Limits**: Maximum 5 attempts per OTP code
6. **Passwordless**: No passwords stored, reducing security risk

---

## Frontend Implementation Guide

### State Management

```javascript
// Registration state
const [registrationState, setRegistrationState] = useState({
  step: 1, // 1-5
  ownerEmail: '',
  sessionToken: '',
  martEmail: '',
  martEmailVerified: false,
  ownerData: {},
  martData: {}
});
```

### Step 1 & 2: Owner Email Verification

```javascript
// Send OTP
const sendOwnerOtp = async (email) => {
  const response = await api.post('/auth/owner/send-otp', { email });
  setRegistrationState(prev => ({ ...prev, ownerEmail: email, step: 2 }));
};

// Verify OTP
const verifyOwnerOtp = async (otp) => {
  const response = await api.post('/auth/owner/verify-otp', {
    email: registrationState.ownerEmail,
    otp
  });
  
  if (response.data.data.isNewUser) {
    setRegistrationState(prev => ({
      ...prev,
      sessionToken: response.data.data.sessionToken,
      step: 3
    }));
  } else {
    // Existing user - navigate to dashboard
    localStorage.setItem('token', response.data.data.token);
    navigate('/dashboard');
  }
};
```

### Step 3 & 4: Mart Email Verification

```javascript
// Send mart email OTP
const sendMartEmailOtp = async (martEmail) => {
  const response = await api.post('/auth/owner/verify-mart-email/send-otp', {
    sessionToken: registrationState.sessionToken,
    martEmail
  });
  setRegistrationState(prev => ({ ...prev, martEmail, step: 4 }));
};

// Verify mart email OTP
const verifyMartEmailOtp = async (otp) => {
  const response = await api.post('/auth/owner/verify-mart-email/verify-otp', {
    sessionToken: registrationState.sessionToken,
    martEmail: registrationState.martEmail,
    otp
  });
  setRegistrationState(prev => ({ ...prev, martEmailVerified: true, step: 5 }));
};
```

### Step 5: Complete Registration

```javascript
const completeRegistration = async (martData, ownerData) => {
  const response = await api.post('/auth/owner/complete-registration', {
    sessionToken: registrationState.sessionToken,
    martData: {
      martName: martData.name,
      martEmail: registrationState.martEmail, // Use verified email
      martContact: martData.contact,
      profileImageUrl: martData.imageUrl,
      martCoordinates: martData.coordinates
    },
    ownerData: {
      ownerName: ownerData.name,
      ownerPhone: ownerData.phone,
      ownerEmail: registrationState.ownerEmail // Use verified email
    }
  });
  
  // Save token and navigate
  localStorage.setItem('token', response.data.data.token);
  navigate('/dashboard');
};
```

---

## Testing Guide

### Using Postman/cURL

See `backend/test-mart-registration.js` for automated testing script.

### Manual Testing Steps

1. **Send owner OTP**: POST to `/owner/send-otp`
2. Check email for OTP code (or check console logs in development)
3. **Verify owner OTP**: POST to `/owner/verify-otp` with OTP
4. Copy `sessionToken` from response
5. **Send mart email OTP**: POST to `/owner/verify-mart-email/send-otp`
6. Check mart email for OTP (or console logs)
7. **Verify mart email OTP**: POST to `/owner/verify-mart-email/verify-otp`
8. **Complete registration**: POST to `/owner/complete-registration` with all data
9. Save JWT token from response

---

## Migration from Old Flow

If you have existing marts registered with the old flow:
- They can log in normally using their email + OTP
- No data migration needed
- New registrations will follow the new flow

---

**Last Updated:** November 4, 2025  
**Version:** 2.0 (Two-Step Email Verification)

