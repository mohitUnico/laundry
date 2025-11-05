# Gmail SMTP Setup Guide for Nodemailer

## Prerequisites
- A Gmail account
- 2-Step Verification enabled on your Google Account

---

## Step-by-Step Setup

### 1. Enable 2-Step Verification

1. Go to your Google Account: https://myaccount.google.com/
2. Click **Security** in the left sidebar
3. Under "Signing in to Google," click **2-Step Verification**
4. Follow the prompts to enable it (you'll need your phone)

### 2. Generate App Password

1. After enabling 2-Step Verification, go back to **Security**
2. Under "Signing in to Google," click **App passwords**
3. You might need to sign in again
4. In the "Select app" dropdown, choose **Mail**
5. In the "Select device" dropdown, choose **Other (Custom name)**
6. Type: `Laundry App Backend`
7. Click **Generate**
8. **Copy the 16-character password** (format: `xxxx xxxx xxxx xxxx`)
9. Remove spaces: `xxxxxxxxxxxxxxxx`

### 3. Update Your .env File

```env
# Environment (use 'production' to enable real email sending)
NODE_ENV=production

# SMTP Configuration (Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-gmail@gmail.com
SMTP_PASSWORD=your-16-char-app-password
SMTP_FROM_EMAIL=Your Name <your-gmail@gmail.com>
```

### 4. Important Notes

#### Gmail Limits
- **500 emails per day** for regular Gmail accounts
- **2000 emails per day** for Google Workspace accounts
- Perfect for development and small-scale production

#### Security
- ✅ App passwords are safer than your real password
- ✅ Can be revoked anytime from Google Account settings
- ✅ Limited to specific app access
- ❌ Don't share app passwords
- ❌ Don't commit .env to git

---

## Testing

After setup, test with:

```bash
node backend/test-email-first-auth.js
```

You should receive a real email with the OTP code!

---

## Troubleshooting

### Error: "Invalid login"
- ❌ Wrong email or password
- ❌ 2-Step Verification not enabled
- ❌ App password not generated correctly
- ✅ Double-check credentials in .env

### Error: "Connection timeout"
- ❌ Wrong SMTP_HOST or SMTP_PORT
- ❌ Firewall blocking port 587
- ✅ Check your network/firewall settings

### Gmail blocks sending
- ❌ Suspicious activity detected
- ✅ Verify your account at https://accounts.google.com/DisplayUnlockCaptcha
- ✅ Try using port 465 with SMTP_SECURE=true

---

## Alternative SMTP Providers

### SendGrid (Free tier: 100 emails/day)
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

### AWS SES (Pay as you go, very cheap)
```env
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=your-aws-smtp-username
SMTP_PASSWORD=your-aws-smtp-password
```

### Mailgun (Free tier: 100 emails/day)
```env
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=your-mailgun-smtp-username
SMTP_PASSWORD=your-mailgun-smtp-password
```

---

## Production Recommendations

For production, consider:

1. **SendGrid** - Easy to set up, good deliverability
2. **AWS SES** - Very cheap, scalable, reliable
3. **Mailgun** - Developer-friendly, good API
4. **Avoid Gmail** - Daily limits, can be blocked

---

## Security Checklist

- [ ] 2-Step Verification enabled
- [ ] App password generated (not regular password)
- [ ] .env file in .gitignore
- [ ] Different credentials for dev/prod
- [ ] App password revoked if compromised
- [ ] SPF/DKIM records configured (for custom domains)

---

**Last Updated:** November 3, 2025

