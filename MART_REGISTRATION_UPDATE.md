# Mart Registration Flow - Two-Step Email Verification

## 📋 Summary

The mart owner registration process has been updated to include **two-step email verification** to ensure both the owner's personal email and the mart's business email are properly verified before account creation.

---

## 🎯 What Changed

### Previous Flow (Old)
```
1. Owner enters email → Verify OTP
2. Submit mart + owner details → Complete
```

### New Flow (Current)
```
1. Owner enters email → Verify OTP (owner email)
2. Enter mart email → Verify OTP (mart email)
3. Submit all mart + owner details → Complete
```

---

## 🔧 Technical Changes

### 1. Database Schema

**Added to `OtpSession` table:**
```sql
ALTER TABLE otp_sessions 
ADD COLUMN mart_email VARCHAR(255),
ADD COLUMN mart_email_verified BOOLEAN DEFAULT false;
```

**Migration:** `20251104055905_add_mart_email_verification`

### 2. New API Endpoints

#### Send OTP to Mart Email
```
POST /api/v1/auth/owner/verify-mart-email/send-otp
Body: { sessionToken, martEmail }
```

#### Verify Mart Email OTP
```
POST /api/v1/auth/owner/verify-mart-email/verify-otp
Body: { sessionToken, martEmail, otp }
```

### 3. Updated Service Methods

**New methods in `otp.service.js`:**
- `sendMartEmailOtp(sessionToken, martEmail)`
- `verifyMartEmailOtp(sessionToken, martEmail, otp)`

**Updated method:**
- `completeOwnerRegistration()` - Now requires mart email verification

### 4. Updated Data Structure

**New mart data format:**
```javascript
{
  martName: "Clean & Fresh Laundry",
  martEmail: "contact@cleanfresh.com",  // NEW: Separate mart email
  martContact: "+1234567890",
  profileImageUrl: "https://...",
  martCoordinates: {
    latitude: 37.7749,
    longitude: -122.4194
  }
}
```

**New owner data format:**
```javascript
{
  ownerName: "John Doe",      // Changed from fullName
  ownerPhone: "+1234567890",  // Changed from phone
  ownerEmail: "owner@example.com"  // Explicitly required
}
```

---

## 📚 Documentation Updates

### New Documentation
- ✅ `backend/docs/MART_REGISTRATION_FLOW.md` - Complete guide with flow diagram
- ✅ Updated `backend/docs/EMAIL_FIRST_AUTH_GUIDE.md` - Added steps 3-5 for mart registration
- ✅ Updated `backend/docs/README.md` - Added reference to new flow
- ✅ Updated `.cursor/rules/backend/backend-architecture.mdc` - Updated schema and methods

### Documentation Locations
| Document | What's Updated |
|----------|---------------|
| `MART_REGISTRATION_FLOW.md` | Complete new flow with examples, error handling, frontend guide |
| `EMAIL_FIRST_AUTH_GUIDE.md` | Owner authentication section (steps 3-4-5 added) |
| `README.md` | Quick navigation and documentation index |
| `backend-architecture.mdc` | OTP schema, service methods, user types |

---

## 🚀 Complete Registration Flow

### Step-by-Step Process

#### **Step 1: Verify Owner Email**
```http
POST /api/v1/auth/owner/send-otp
{ "email": "owner@example.com" }

POST /api/v1/auth/owner/verify-otp
{ "email": "owner@example.com", "otp": "123456" }

Response: { sessionToken: "abc123...", isNewUser: true }
```

#### **Step 2: Verify Mart Email**
```http
POST /api/v1/auth/owner/verify-mart-email/send-otp
{ "sessionToken": "abc123...", "martEmail": "contact@cleanfresh.com" }

POST /api/v1/auth/owner/verify-mart-email/verify-otp
{ "sessionToken": "abc123...", "martEmail": "contact@cleanfresh.com", "otp": "789012" }

Response: { martEmailVerified: true }
```

#### **Step 3: Complete Registration**
```http
POST /api/v1/auth/owner/complete-registration
{
  "sessionToken": "abc123...",
  "martData": {
    "martName": "Clean & Fresh Laundry",
    "martEmail": "contact@cleanfresh.com",
    "martContact": "+1234567890",
    "profileImageUrl": "https://...",
    "martCoordinates": { "latitude": 37.7749, "longitude": -122.4194 }
  },
  "ownerData": {
    "ownerName": "John Doe",
    "ownerPhone": "+1234567890",
    "ownerEmail": "owner@example.com"
  }
}

Response: { token: "JWT...", mart: {...}, owner: {...} }
```

---

## ✅ Validation Rules

### Email Validation
- ✅ Both owner and mart emails must be valid
- ✅ Mart email must be unique (not already registered)
- ✅ Emails are normalized to lowercase
- ✅ Owner email must match the verified email from Step 1

### OTP Validation
- ✅ OTP expires in 5 minutes
- ✅ Maximum 5 verification attempts per OTP
- ✅ Rate limit: 1 OTP per email per minute
- ✅ OTPs are single-use

### Session Validation
- ✅ Session token expires in 30 minutes
- ✅ Mart email must be verified before completing registration
- ✅ Session marked as completed after successful registration

---

## 🔒 Security Enhancements

1. **Two-Factor Email Verification**: Both personal and business emails verified
2. **Unique Mart Emails**: Prevents duplicate mart registrations
3. **Time-Limited Sessions**: 30-minute expiry for session tokens
4. **Rate Limiting**: Prevents OTP spam
5. **Attempt Limits**: Maximum 5 OTP verification attempts

---

## 🎨 Frontend Implementation

### State Management
```javascript
const [registrationState, setRegistrationState] = useState({
  step: 1, // 1: Owner email, 2: Owner OTP, 3: Mart email, 4: Mart OTP, 5: Complete
  ownerEmail: '',
  sessionToken: '',
  martEmail: '',
  martEmailVerified: false
});
```

### Key Functions
1. `sendOwnerOtp(email)` - Step 1
2. `verifyOwnerOtp(otp)` - Step 2
3. `sendMartEmailOtp(martEmail)` - Step 3
4. `verifyMartEmailOtp(otp)` - Step 4
5. `completeRegistration(martData, ownerData)` - Step 5

**See:** `backend/docs/MART_REGISTRATION_FLOW.md` for complete frontend code examples

---

## 🧪 Testing

### Manual Testing
```bash
# Terminal 1: Start server
cd backend && npm run dev

# Terminal 2: Use curl or Postman
# Follow the 5-step process in MART_REGISTRATION_FLOW.md
```

### Automated Testing
Create a test script (see documentation) or use Postman collection

---

## 📦 Migration Notes

### Existing Marts
- ✅ No migration needed for existing marts
- ✅ Existing owners can log in normally
- ✅ Only new registrations use the new flow

### Backward Compatibility
- ✅ Old data format still works for existing records
- ✅ JWT tokens remain compatible
- ✅ No breaking changes to existing APIs (only additions)

---

## 🐛 Common Issues & Solutions

### Issue: "Mart email must be verified"
**Solution:** Complete steps 3-4 (mart email verification) before step 5

### Issue: "Mart email already registered"
**Solution:** Use a different email or log in with the existing mart account

### Issue: "Session has expired"
**Solution:** Session tokens expire in 30 minutes. Start the registration process again

### Issue: "Invalid session token"
**Solution:** Ensure you're using the sessionToken from the verify-otp response

---

## 📝 Code Files Changed

### Backend Files
- `prisma/schema.prisma` - Added mart_email fields to OtpSession
- `src/services/otp.service.js` - Added sendMartEmailOtp, verifyMartEmailOtp, updated completeOwnerRegistration
- `src/controllers/auth.controller.js` - Added sendMartEmailOtp, verifyMartEmailOtp controllers
- `src/routes/auth.routes.js` - Added 2 new routes

### Documentation Files
- `backend/docs/MART_REGISTRATION_FLOW.md` (NEW)
- `backend/docs/EMAIL_FIRST_AUTH_GUIDE.md` (UPDATED)
- `backend/docs/README.md` (UPDATED)
- `.cursor/rules/backend/backend-architecture.mdc` (UPDATED)

---

## 🎓 Key Takeaways

1. **Why Two Emails?**
   - Owner's personal email for login
   - Mart's business email for official communication and uniqueness

2. **Why Separate Verification?**
   - Ensures both emails are valid and accessible
   - Prevents fraudulent registrations
   - Better data integrity

3. **Session Token Flow**
   - After owner email verified → Get session token
   - Use session token for all subsequent steps
   - Session token ensures security and proper flow

4. **One Request for All Data**
   - After both emails verified, submit everything at once
   - Atomic operation - all or nothing
   - Reduces complexity and potential errors

---

## 📞 Need Help?

**Documentation:**
- 📖 Complete Guide: `backend/docs/MART_REGISTRATION_FLOW.md`
- 📖 API Reference: `backend/docs/EMAIL_FIRST_AUTH_GUIDE.md`
- 📖 Architecture: `.cursor/rules/backend/backend-architecture.mdc`

**Testing:**
- Run server: `npm run dev`
- Check logs: `tail -f backend/logs/combined.log`
- Test script: `node backend/test-email-first-auth.js`

---

**Last Updated:** November 4, 2025  
**Version:** 2.0.0  
**Migration:** `20251104055905_add_mart_email_verification`

