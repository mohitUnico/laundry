# Quick Start Guide - Email-First Authentication

## 🚀 Quick Test (Development Mode - Console OTP)

### 1. Setup & Start Server

```bash
cd backend

# Install dependencies (if not done)
npm install

# Set up environment variables
cp .env.example .env
# Edit .env and set DATABASE_URL and JWT_SECRET

# Run database migrations
npx prisma migrate dev

# Start the server
npm run dev
```

Server will start on `http://localhost:3000`

### 2. Run Interactive Tests

```bash
# Run the comprehensive test suite
node test-email-first-auth.js
```

This launches an interactive test suite for all authentication flows (owner, customer, delivery).

---

## 📧 Manual API Testing

### Test 1: Existing Owner Login

**Step 1: Send OTP to Email**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com"}'
```

**Check console output for OTP code** (displayed in a box):
```
========================================
📧 OTP EMAIL (Development Mode)
========================================
To: owner@example.com
Subject: Your Laundry App Verification Code
User Type: Owner
OTP Code: 123456
Expires: 5 minutes
========================================
```

**Step 2: Verify OTP**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","otp":"123456"}'
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
      "martId": "uuid",
      "mart": {
        "mart_id": "uuid",
        "mart_name": "Clean & Fresh Laundry",
        "contact_email": "contact@cleanfresh.com"
      }
    }
  }
}
```

✅ **Login complete!** Use the JWT token for authenticated requests.

---

### Test 2: New Owner Signup (Two-Step Email Verification)

**Step 1: Send OTP to Owner Email**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"newowner@example.com"}'
```

**Step 2: Verify Owner Email OTP**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"newowner@example.com","otp":"123456"}'
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

**Step 3: Send OTP to Mart Email**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/verify-mart-email/send-otp \
  -H "Content-Type: application/json" \
  -d '{
    "sessionToken": "abc123def456...",
    "martEmail": "contact@freshlaundry.com"
  }'
```

**Step 4: Verify Mart Email OTP**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/verify-mart-email/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "sessionToken": "abc123def456...",
    "martEmail": "contact@freshlaundry.com",
    "otp": "789012"
  }'
```

**Step 5: Complete Registration**
```bash
curl -X POST http://localhost:3000/api/v1/auth/owner/complete-registration \
  -H "Content-Type: application/json" \
  -d '{
    "sessionToken": "abc123def456...",
    "martData": {
      "martName": "Fresh Laundry",
      "martEmail": "contact@freshlaundry.com",
      "martContact": "+1234567890",
      "address": "123 Main St, City, State",
      "profileImageUrl": "https://s3.amazonaws.com/bucket/image.jpg",
      "martCoordinates": {
        "latitude": 28.6139,
        "longitude": 77.2090
      }
    },
    "ownerData": {
      "ownerName": "John Doe",
      "ownerPhone": "+1234567890",
      "ownerEmail": "newowner@example.com"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Registration completed successfully. Welcome to Laundry App!",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "mart": {
      "mart_id": "uuid",
      "mart_name": "Fresh Laundry",
      "contact_email": "contact@freshlaundry.com",
      "profile_image_url": "https://s3.amazonaws.com/bucket/image.jpg"
    },
    "owner": {
      "user_id": "uuid",
      "full_name": "John Doe",
      "email": "newowner@example.com",
      "role": "admin"
    }
  }
}
```

✅ **Registration complete!** Mart and owner created, JWT token issued.

---

### Test 3: Customer Flow

**Send OTP**
```bash
curl -X POST http://localhost:3000/api/v1/auth/customer/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com"}'
```

**Verify OTP**
```bash
curl -X POST http://localhost:3000/api/v1/auth/customer/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","otp":"123456"}'
```

**If new customer, complete registration:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/customer/complete-registration \
  -H "Content-Type: application/json" \
  -d '{
    "sessionToken": "YOUR_SESSION_TOKEN",
    "customerData": {
      "fullName": "Alice Johnson",
      "phone": "9876543210",
      "address": {
        "addressLabel": "home",
        "address": "123 Main Street, City, State, ZIP Code",
        "latitude": 37.7749,
        "longitude": -122.4194
      }
    }
  }'
```

---

## 📧 Test with Real Email (SMTP)

### Prerequisites
1. Gmail account with App Password (or SendGrid/AWS SES account)
2. SMTP credentials ready
3. Email credentials added to `.env`

### 1. Add SMTP Credentials to `.env`

**For Gmail:**
```env
# Add these to your .env file
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-16-char-app-password
SMTP_FROM_EMAIL=Laundry App <your-email@gmail.com>
```

**For SendGrid:**
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_FROM_EMAIL=Laundry App <noreply@yourdomain.com>
```

> **Note:** For Gmail, you need to create an **App Password** (not your regular password). See `docs/GMAIL_SMTP_SETUP.md` for detailed instructions.

### 2. Restart Server

```bash
# Stop the server (Ctrl+C)
# Start again
npm run dev
```

You should see:
```
📧 Email service initialized with SMTP (real email sending enabled)
   SMTP Host: smtp.gmail.com
   SMTP User: your-email@gmail.com
```

### 3. Test with Real Email

Send OTP to your email:
```bash
curl -X POST http://localhost:3000/api/v1/auth/customer/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@example.com"}'
```

**You should receive a real email with OTP code!**

Console will show:
```
📧 OTP Email sent to your-email@example.com for customer
```

---

## 🔐 Using JWT Token

After successful login/signup, use the JWT token for authenticated requests:

```bash
# Example: Get orders
curl -X GET http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Example: Get mart details
curl -X GET http://localhost:3000/api/v1/marts/mart-uuid-123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Example: Update order status
curl -X PATCH http://localhost:3000/api/v1/orders/order-uuid-123/status \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_process"}'
```

---

## 🐛 Troubleshooting

### Server Not Starting
```bash
# Check if PostgreSQL is running
psql -U postgres -c "SELECT version();"

# Check if port 3000 is available
lsof -ti:3000 | xargs kill -9  # Kill any process on port 3000
```

### Database Connection Error
```bash
# Make sure PostgreSQL is running
# Verify DATABASE_URL in .env
# Run migrations
npx prisma migrate dev
```

### OTP Not Received (Email)
1. **Development Mode**: Check console logs for OTP code
2. **Production Mode**: 
   - Check SMTP credentials in `.env`
   - Verify email went to spam folder
   - Check SMTP logs in console
   - For Gmail: Ensure App Password is correct (not regular password)
3. Check console/logs for error messages

### Gmail Authentication Error
- **Error**: "Invalid login" or "Username and Password not accepted"
- **Solution**: 
  - Use App Password, not your regular Gmail password
  - Enable 2-Step Verification first
  - Generate App Password from: https://myaccount.google.com/apppasswords
  - See `docs/GMAIL_SMTP_SETUP.md` for detailed guide

### Rate Limit Error
Wait 60 seconds before requesting another OTP for the same email address.

### Invalid OTP Error
- OTP expires in 5 minutes
- Maximum 5 verification attempts per OTP
- Request new OTP if needed

### Session Expired Error
- Session tokens expire in 30 minutes
- Request new OTP and verify again to get fresh session token

### Mart Email Not Verified Error
- For new owner registration, mart email must be verified before completing registration
- Complete steps 3-4 (mart email verification) before step 5

---

## 📊 Available Endpoints

### Owner Authentication
```
POST /api/v1/auth/owner/send-otp
POST /api/v1/auth/owner/verify-otp
POST /api/v1/auth/owner/verify-mart-email/send-otp      (New owners only)
POST /api/v1/auth/owner/verify-mart-email/verify-otp   (New owners only)
POST /api/v1/auth/owner/complete-registration
```

### Manager Authentication
```
POST /api/v1/auth/manager/send-otp
POST /api/v1/auth/manager/verify-otp
POST /api/v1/auth/manager/complete-registration
```

### Customer Authentication
```
POST /api/v1/auth/customer/send-otp
POST /api/v1/auth/customer/verify-otp
POST /api/v1/auth/customer/complete-registration
```

### Delivery Staff Authentication
```
POST /api/v1/auth/delivery/send-otp
POST /api/v1/auth/delivery/verify-otp
POST /api/v1/auth/delivery/complete-registration
```

### Common
```
POST /api/v1/auth/resend-otp
POST /api/v1/auth/logout
```

---

## 📚 Documentation

- **Complete Guide**: `docs/EMAIL_FIRST_AUTH_GUIDE.md`
- **Mart Registration Flow**: `docs/MART_REGISTRATION_FLOW.md`
- **Implementation Summary**: `docs/EMAIL_FIRST_AUTH_SUMMARY.md`
- **Gmail SMTP Setup**: `docs/GMAIL_SMTP_SETUP.md`
- **Profile Image URL Update**: `docs/PROFILE_IMAGE_URL_UPDATE.md`

---

## 🎉 Success Indicators

### Development Mode (Console Logging)
✅ OTP displayed in console with formatted box  
✅ Server logs show "OTP sent successfully"  
✅ OTP verification returns JWT token (existing user)  
✅ OTP verification returns session token (new user)  
✅ Email service initialized in console mode

### Production Mode (SMTP)
✅ Email received in inbox within seconds  
✅ Console shows "OTP Email sent to [email]"  
✅ OTP verification works correctly  
✅ Server logs show email delivery success  
✅ Email service initialized with SMTP

---

## 🚀 Next Steps

1. **Run Tests**: Use `node test-email-first-auth.js` for comprehensive testing
2. **Set up SMTP**: See `docs/GMAIL_SMTP_SETUP.md` for production email delivery
3. **Integrate Frontend**: Use examples in `docs/EMAIL_FIRST_AUTH_GUIDE.md`
4. **Deploy**: Test in staging environment with real email addresses

---

## 💡 Key Differences from Traditional Auth

❌ **OLD**: Username/Password → Login  
✅ **NEW**: Email → OTP → Auto-detect login/signup

❌ **OLD**: Separate login and signup flows  
✅ **NEW**: Single flow, system detects if user exists

❌ **OLD**: Passwords stored in database  
✅ **NEW**: Completely passwordless, only OTP

❌ **OLD**: New users see "email not found" errors  
✅ **NEW**: New users seamlessly complete registration

❌ **OLD**: SMS costs money  
✅ **NEW**: Email is free (no SMS charges)

---

## 📧 Email vs SMS Comparison

| Feature | Email OTP | SMS OTP |
|---------|-----------|---------|
| **Cost** | ✅ Free | ❌ Charges per SMS |
| **Delivery Speed** | ⚠️ 1-10 seconds | ✅ 1-3 seconds |
| **Reliability** | ✅ High | ⚠️ Varies by region |
| **Spam Filtering** | ⚠️ May go to spam | ✅ Rarely filtered |
| **Universal Access** | ✅ Everyone has email | ✅ Everyone has phone |
| **Professional** | ✅ Branded templates | ⚠️ Plain text |
| **Cost-Effective** | ✅ Perfect for startups | ❌ Expensive at scale |

---

## 🎯 Quick Reference

### Development Mode (No SMTP)
- OTPs logged to console
- No email sent
- Perfect for testing
- No configuration needed

### Production Mode (SMTP Configured)
- OTPs sent via email
- Real email delivery
- Configure SMTP in `.env`
- See `docs/GMAIL_SMTP_SETUP.md`

### Mart Owner Registration Flow
1. Verify owner email → Get session token
2. Verify mart email → Mark verified
3. Complete registration → Get JWT token

### Login Flow (All Users)
1. Send OTP to email
2. Verify OTP → Get JWT token (if existing) or session token (if new)

---

Happy Testing! 🎉
