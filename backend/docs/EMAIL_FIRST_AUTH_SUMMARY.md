# Email-First OTP Authentication - Implementation Summary

## What Changed

### From: Phone-First OTP Authentication
- Authentication via phone number + SMS OTP
- SMS costs for every authentication
- Twilio dependency

### To: Email-First OTP Authentication
- Authentication via email address + Email OTP
- No SMS costs (email is free)
- Nodemailer for email sending

---

## Key Changes

### 1. Database Schema

**Modified Tables:**
- `LaundryMart`: Removed `is_phone_verified`, `contact_phone` made optional
- `User`: Removed `is_phone_verified`, `phone` made optional
- `Customer`: Removed `is_phone_verified`, `phone` made optional
- `DeliveryStaff`: Removed `is_phone_verified`, `phone` made optional, `email` now required

**OTP Tables:**
- `OtpVerification`: Changed `phone` → `email`
- `OtpSession`: Changed `phone` → `email`

### 2. New Services

**`email.service.js`** - Email sending service
- `sendOtpEmail(email, otp, userType)` - Send OTP verification emails
- `sendWelcomeEmail(email, userName, userType)` - Send welcome emails
- Development mode: Logs to console
- Production mode: Sends via SMTP

**Updated: `otp.service.js`**
- All methods updated to use email instead of phone
- Removed Twilio SMS integration
- Added email service integration

### 3. Updated Files

#### Controllers
- `auth.controller.js` - Changed from phone to email in all endpoints

#### Routes
- `auth.routes.js` - Updated route documentation for email

#### Validators
- `auth.validator.js` - Changed validation from phone to email

#### Services
- `mart.service.js` - Marked old methods as deprecated
- `otp.service.js` - Complete rewrite for email-based flow

### 4. New Dependencies

```json
{
  "nodemailer": "^6.9.7"
}
```

---

## API Endpoint Changes

### Before (Phone-First)
```
POST /api/v1/auth/customer/send-otp
Body: { "phone": "9876543210" }
```

### After (Email-First)
```
POST /api/v1/auth/customer/send-otp
Body: { "email": "customer@example.com" }
```

All endpoints follow the same pattern - replace `phone` with `email`.

### Supported User Types (Email-First OTP)

- `owner`
- `manager`
- `collection_manager`
- `distribution_manager`
- `service_man` (requires `serviceId` or `serviceType` during send/verify/complete)
- `customer`
- `delivery_staff`

---

## Environment Variables

### New Variables

```env
# SMTP Email Configuration
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE="false"
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-specific-password"
SMTP_FROM_EMAIL="Laundry App <noreply@laundryapp.com>"
```

### Removed Variables
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_PHONE_NUMBER`

### Kept Variables
- `OTP_EXPIRY_MINUTES=5`
- `OTP_MAX_ATTEMPTS=5`
- `OTP_RATE_LIMIT_SECONDS=60`

---

## Files Created

1. **`src/services/email.service.js`** - Email sending service
2. **`docs/EMAIL_FIRST_AUTH_GUIDE.md`** - Complete documentation
3. **`docs/EMAIL_FIRST_AUTH_SUMMARY.md`** - This file
4. **`test-email-first-auth.js`** - Interactive test script
5. **`clear-otp-and-migrate.js`** - Migration helper script

---

## Migration Steps

### 1. Install Dependencies
```bash
npm install nodemailer
```

### 2. Clear OTP Data (Optional)
```bash
node clear-otp-and-migrate.js
```

### 3. Run Database Migration
```bash
npx prisma migrate dev --name switch_to_email_first_auth
```

### 4. Update Environment Variables
Add SMTP configuration to your `.env` file:
```env
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE="false"
SMTP_USER="mohit.unico@gmail.com"
SMTP_PASSWORD="your-app-password"
SMTP_FROM_EMAIL="Laundry App <noreply@laundryapp.com>"
```

### 5. Restart Server
```bash
npm run dev
```

### 6. Test
```bash
node test-email-first-auth.js
```

---

## Development vs Production

### Development Mode
- OTPs are logged to console
- No email actually sent
- Perfect for local testing

### Production Mode
- OTPs sent via SMTP
- Requires SMTP configuration
- Supports Gmail, SendGrid, AWS SES, etc.

---

## Testing

### Quick Test

```bash
# Start server
npm run dev

# In another terminal, run test script
node test-email-first-auth.js
```

### Manual curl Test

```bash
# 1. Send OTP
curl -X POST http://localhost:3000/api/v1/auth/customer/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# 2. Check console for OTP, then verify
curl -X POST http://localhost:3000/api/v1/auth/customer/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","otp":"123456"}'
```

---

## Frontend Changes Needed

### Old (Phone-First)
```jsx
<input 
  type="tel" 
  placeholder="Enter phone number"
  value={phone}
  onChange={(e) => setPhone(e.target.value)}
/>
```

### New (Email-First)
```jsx
<input 
  type="email" 
  placeholder="Enter email address"
  value={email}
  onChange={(e) => setEmail(e.target.value)}
/>
```

### API Calls
Change all `phone` parameters to `email` in API requests.

---

## Benefits

✅ **Cost Savings**: No SMS fees  
✅ **Better UX**: Professional email templates  
✅ **Universal**: Everyone has email  
✅ **Reliable**: Email delivery is more consistent  
✅ **Scalable**: No SMS provider limits  

---

## Trade-offs

⚠️ **Email Access**: Users must check email  
⚠️ **Slightly Slower**: Email delivery can take 1-10 seconds  
⚠️ **Spam Filters**: Requires email authentication setup  

---

## Security Features

🔒 **OTP Expiry**: 5 minutes  
🔒 **Rate Limiting**: 1 OTP per minute per email  
🔒 **Max Attempts**: 5 attempts per OTP  
🔒 **One-Time Use**: OTPs invalidated after use  
🔒 **Session Expiry**: 30 minutes for registration  

---

## Documentation

📚 **Complete Guide**: `docs/EMAIL_FIRST_AUTH_GUIDE.md`  
📚 **API Documentation**: See guide for all endpoints  
📚 **Test Script**: `test-email-first-auth.js`  
📚 **Migration Script**: `clear-otp-and-migrate.js`  

---

## Support

### Common Issues

1. **OTP not received**: Check spam folder, verify SMTP config
2. **Invalid OTP**: Check expiry (5 mins), verify email match
3. **Rate limit**: Wait 60 seconds before retry
4. **Session expired**: 30-minute limit, start over if expired

### Logs

Check server logs for detailed error messages:
```bash
# Development
npm run dev

# Check logs in backend/logs/
```

---

## Next Steps

1. ✅ Backend migration complete
2. ⏳ Update frontend (React admin panel)
3. ⏳ Update mobile apps (Flutter)
4. ⏳ Set up email domain authentication (SPF/DKIM/DMARC)
5. ⏳ Configure production SMTP provider
6. ⏳ Test with real email accounts
7. ⏳ Deploy to staging environment
8. ⏳ Production deployment

---

## Contact

For questions or issues with the email-first authentication system:
- Review the complete guide: `EMAIL_FIRST_AUTH_GUIDE.md`
- Check server logs for errors
- Run the test script: `node test-email-first-auth.js`
- Ensure database migrations are up to date

---

**Migration Date**: November 3, 2025  
**Version**: 2.0.0  
**Status**: ✅ Backend Complete

