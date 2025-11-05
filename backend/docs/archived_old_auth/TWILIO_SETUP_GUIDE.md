# Twilio Setup Guide for OTP SMS

This guide will help you set up Twilio for sending OTP SMS messages in the Laundry App.

---

## Step 1: Create Twilio Account

1. **Visit Twilio Website**
   - Go to [https://www.twilio.com/try-twilio](https://www.twilio.com/try-twilio)
   - Click **"Sign up"** or **"Start for free"**

2. **Create Account**
   - Enter your email, password
   - Verify your email address
   - Complete the registration process

3. **Verify Your Phone Number**
   - Twilio will ask you to verify your personal phone number
   - This is required for trial accounts
   - You'll receive an SMS verification code

4. **Complete Setup Wizard**
   - Answer a few questions about your use case
   - Select "SMS" as your product interest
   - Choose "With code" as integration method
   - Select "Node.js" as your language

---

## Step 2: Get Twilio Credentials

### A. Account SID and Auth Token

1. **Go to Twilio Console Dashboard**
   - URL: [https://console.twilio.com/](https://console.twilio.com/)
   - After login, you'll see the Dashboard

2. **Locate Your Credentials**
   - On the Dashboard, you'll see:
     - **Account SID**: Starts with `AC...`
     - **Auth Token**: Click "Show" to reveal it
   
   ```
   Account SID: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Auth Token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. **Copy These Credentials**
   - Keep them safe - you'll need them in your `.env` file

### B. Get a Phone Number

1. **Get a Twilio Phone Number**
   - In the Twilio Console, go to: **Phone Numbers** → **Manage** → **Buy a number**
   - OR click: [https://console.twilio.com/us1/develop/phone-numbers/manage/search](https://console.twilio.com/us1/develop/phone-numbers/manage/search)

2. **Choose a Number**
   - **For India**: Select "India" in the country dropdown
   - Check **SMS** capability (required)
   - Click **Search**
   - Choose a number and click **Buy**

3. **Trial Account Limitations**
   - **Free Trial**: $15.50 credit (limited SMS)
   - **Can only send SMS to verified phone numbers**
   - **SMS will include trial message prefix**
   - **Upgrade to remove limitations**

4. **Copy Your Twilio Phone Number**
   ```
   Example: +91XXXXXXXXXX (for India)
   Example: +1XXXXXXXXXX (for US)
   ```

---

## Step 3: Verify Test Phone Numbers (Trial Account Only)

**Important**: With a trial account, you can only send SMS to verified phone numbers.

1. **Go to Verified Caller IDs**
   - Navigate to: **Phone Numbers** → **Manage** → **Verified Caller IDs**
   - OR visit: [https://console.twilio.com/us1/develop/phone-numbers/manage/verified](https://console.twilio.com/us1/develop/phone-numbers/manage/verified)

2. **Add Your Test Phone Numbers**
   - Click **"Add a new Caller ID"** or **"+"**
   - Enter the phone number you want to test with (e.g., `+919876543210`)
   - Select **"Text you instead"** (SMS verification)
   - Click **"Text You"**
   - Enter the verification code you receive
   - Click **"Verify"**

3. **Verify All Test Numbers**
   - Add all phone numbers you'll use for testing
   - Each team member should verify their phone number

---

## Step 4: Install Twilio SDK

```bash
cd backend
npm install twilio
```

---

## Step 5: Update Environment Variables

**Edit `backend/.env`:**

```env
# Database
DATABASE_URL="postgresql://postgres:admin@localhost:5432/laundry_db"

# JWT Settings
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
JWT_EXPIRY="7d"

# Server
PORT=3000
NODE_ENV=development

# Logging
LOG_LEVEL=debug

# Twilio SMS Configuration
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+91XXXXXXXXXX
```

**Replace with your actual Twilio credentials:**
- `TWILIO_ACCOUNT_SID`: Your Account SID from Twilio Console
- `TWILIO_AUTH_TOKEN`: Your Auth Token from Twilio Console
- `TWILIO_PHONE_NUMBER`: Your Twilio phone number (with country code, e.g., +919876543210)

---

## Step 6: Update OTP Service for Twilio

The OTP service is already set up to use Twilio! Just uncomment the production code.

**File: `src/services/otp.service.js`**

Update the `sendSMS` function:

```javascript
const sendSMS = async (phone, otp) => {
  const message = `Your OTP for Laundry App is: ${otp}. Valid for 5 minutes. Do not share this code.`;
  
  // Development mode: Log to console
  if (process.env.NODE_ENV === 'development' && !process.env.TWILIO_ACCOUNT_SID) {
    logger.info(`📱 OTP sent to ${phone}`, { otp });
    console.log(`\n┌─────────────────────────────────────────┐`);
    console.log(`│  🔐 OTP SENT TO: ${phone}          │`);
    console.log(`│  CODE: ${otp}                         │`);
    console.log(`│  Valid for: 5 minutes                  │`);
    console.log(`└─────────────────────────────────────────┘\n`);
    return true;
  }

  // Production mode: Send SMS via Twilio
  try {
    const twilio = require('twilio')(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    
    await twilio.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: `+91${phone}` // Add country code for India
    });

    logger.info('SMS sent successfully via Twilio', { phone });
    return true;
  } catch (error) {
    logger.error('Failed to send SMS via Twilio', {
      error: error.message,
      phone: phone,
      code: error.code
    });
    throw new Error(`SMS sending failed: ${error.message}`);
  }
};
```

---

## Step 7: Testing

### A. Test in Development Mode (Console OTP)

**Without Twilio credentials (default):**

```bash
# Start server
cd backend
npm run dev
```

```bash
# Send OTP request
curl -X POST http://localhost:3000/api/v1/auth/customer/login/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9876543210"}'
```

**Check console for OTP code.**

### B. Test with Twilio (Trial Account)

**Prerequisites:**
1. ✅ Twilio credentials added to `.env`
2. ✅ Test phone number verified in Twilio Console
3. ✅ `twilio` npm package installed
4. ✅ OTP service updated with Twilio code

**Step 1: Send OTP**

```bash
curl -X POST http://localhost:3000/api/v1/auth/customer/login/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9876543210"}'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "expiresIn": 300,
    "userName": "John Doe"
  },
  "message": "OTP sent to your phone"
}
```

**Step 2: Check Your Phone**
You should receive an SMS like:
```
Sent from your Twilio trial account - Your OTP for Laundry App is: 123456. Valid for 5 minutes. Do not share this code.
```

**Note**: Trial accounts add a prefix message.

**Step 3: Verify OTP**

```bash
curl -X POST http://localhost:3000/api/v1/auth/customer/login/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9876543210", "otp": "123456"}'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "customer": {
      "customer_id": "uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210",
      "is_phone_verified": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Login successful"
}
```

---

## Step 8: Upgrade to Production (Optional)

### Why Upgrade?

**Trial Limitations:**
- ❌ Can only send SMS to verified numbers
- ❌ SMS includes trial message prefix
- ❌ Limited to $15.50 credit (~500 SMS)

**Production Benefits:**
- ✅ Send SMS to any number
- ✅ No trial message prefix
- ✅ Pay-as-you-go pricing
- ✅ Higher rate limits
- ✅ Better reliability

### How to Upgrade

1. **Go to Twilio Console**
   - Visit: [https://console.twilio.com/](https://console.twilio.com/)

2. **Upgrade Account**
   - Look for **"Upgrade"** button (usually in top right)
   - OR go to: **Account** → **Upgrade**

3. **Add Payment Method**
   - Add credit card or other payment method
   - No immediate charge (pay-as-you-go)

4. **Benefits Take Effect Immediately**
   - Remove trial restrictions
   - Send SMS to any number
   - No trial message prefix

### Pricing (as of 2024)
- **India SMS**: ~₹0.50 - ₹1.00 per SMS
- **US SMS**: ~$0.0079 per SMS
- **No monthly fees** (pay only for usage)

---

## Troubleshooting

### Issue 1: "Unable to create record: The number is unverified"

**Problem**: Trying to send SMS to unverified number on trial account.

**Solution**:
1. Verify the phone number in Twilio Console
2. OR upgrade your Twilio account

### Issue 2: SMS Not Received

**Possible Causes**:
1. **Wrong phone number format**
   - Ensure: `+91` prefix for India
   - Example: `+919876543210`

2. **Twilio credentials incorrect**
   - Double-check Account SID and Auth Token
   - Make sure no extra spaces

3. **Twilio phone number incorrect**
   - Verify the "from" number in Twilio Console
   - Include country code: `+919876543210`

4. **Network/carrier issues**
   - Try different phone number
   - Check carrier SMS settings

### Issue 3: "Authentication Error" from Twilio

**Problem**: Wrong credentials.

**Solution**:
1. Verify Account SID starts with `AC`
2. Regenerate Auth Token if needed
3. Check for typos in `.env` file
4. Restart server after updating `.env`

### Issue 4: Rate Limiting

**Problem**: Too many SMS in short time.

**Solution**:
1. Twilio has rate limits
2. Implement proper rate limiting in your app (already done!)
3. Upgrade account for higher limits

---

## Cost Optimization Tips

1. **Use Different Providers by Region**
   - Twilio for US/International
   - MSG91 for India (cheaper)
   - AWS SNS for existing AWS infrastructure

2. **Implement SMS Fallbacks**
   - Try primary provider first
   - Fallback to secondary if failure

3. **Monitor Usage**
   - Set up Twilio usage alerts
   - Track SMS sending patterns
   - Identify and fix spam/abuse

4. **Use Templates**
   - Consistent message format
   - Easier to track delivery rates

---

## Production Deployment Checklist

Before deploying to production:

- [ ] Upgrade Twilio account
- [ ] Add production credentials to `.env`
- [ ] Set `NODE_ENV=production`
- [ ] Test SMS delivery in production environment
- [ ] Set up Twilio usage alerts
- [ ] Configure error monitoring
- [ ] Set up SMS delivery tracking
- [ ] Implement retry logic for failed SMS
- [ ] Add Twilio webhook for delivery status
- [ ] Document SMS costs in budget

---

## Alternative: MSG91 (For India)

If targeting primarily Indian users, MSG91 might be cheaper:

### MSG91 Setup (Brief)

1. **Sign up**: [https://msg91.com](https://msg91.com)
2. **Get API Key**: Dashboard → API Keys
3. **Get Sender ID**: Create sender ID (e.g., LNDRYAPP)
4. **Create Template**: Required for Indian telecom regulations

**Install SDK:**
```bash
npm install msg91-sms
```

**Update `.env`:**
```env
MSG91_AUTH_KEY=your_api_key
MSG91_SENDER_ID=LNDRYAPP
MSG91_TEMPLATE_ID=your_template_id
```

**Update OTP Service:**
```javascript
// For MSG91
const axios = require('axios');

const sendSMS = async (phone, otp) => {
  try {
    const response = await axios.post('https://api.msg91.com/api/v5/otp', {
      template_id: process.env.MSG91_TEMPLATE_ID,
      mobile: phone,
      authkey: process.env.MSG91_AUTH_KEY,
      otp: otp
    });
    
    return true;
  } catch (error) {
    logger.error('MSG91 SMS failed', { error: error.message });
    throw error;
  }
};
```

---

## Summary

**Quick Setup Checklist:**

1. ✅ Create Twilio account
2. ✅ Get Account SID, Auth Token, Phone Number
3. ✅ Verify test phone numbers (trial account)
4. ✅ Install `twilio` npm package
5. ✅ Add credentials to `.env`
6. ✅ Update OTP service with Twilio code
7. ✅ Test SMS delivery
8. ✅ Upgrade account for production

**Need Help?**
- Twilio Documentation: [https://www.twilio.com/docs/sms](https://www.twilio.com/docs/sms)
- Twilio Support: [https://support.twilio.com/](https://support.twilio.com/)
- Laundry App OTP Guide: `docs/OTP_AUTHENTICATION_GUIDE.md`

---

**You're all set! 🎉**

Your OTP authentication system is now ready to send real SMS messages via Twilio!

