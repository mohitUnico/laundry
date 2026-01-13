# Backend Documentation

Welcome to the Laundry App backend documentation! This folder contains all the guides you need to understand and work with the **Email-First OTP Authentication** system.

---

## 📚 Documentation Index

### 🚀 Getting Started

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[QUICK_START.md](QUICK_START.md)** | Quick setup and testing guide | First time setup, testing flows |

### 🔐 Authentication System (Email-First OTP)

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md)** | Complete email-first authentication guide | Understanding the system, API reference, frontend integration |
| **[MART_REGISTRATION_FLOW.md](MART_REGISTRATION_FLOW.md)** | Mart owner two-step email verification flow | Implementing owner registration, understanding mart setup |
| **[MANAGER_REGISTRATION_API.md](MANAGER_REGISTRATION_API.md)** | Manager registration API documentation | Adding managers to a mart, request/response formats |
| **[STAFF_REGISTRATION_API.md](STAFF_REGISTRATION_API.md)** | Staff registration API documentation (Collection Manager, Distribution Manager, Service Man) | Owner/admin onboarding staff accounts (service man requires serviceId/serviceType; 1 per service) |
| **[EMAIL_FIRST_AUTH_SUMMARY.md](EMAIL_FIRST_AUTH_SUMMARY.md)** | Implementation summary and migration guide | Quick overview, migration from phone-first |

### 📧 Email Configuration

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[GMAIL_SMTP_SETUP.md](GMAIL_SMTP_SETUP.md)** | Gmail SMTP configuration guide | Setting up Gmail for sending OTP emails |

### 🏗️ Architecture Documentation (v2.0)

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md)** | Complete Architecture v2.0 with 6 user roles, cart system, and service queue | Understanding new system, planning development, API reference |
| **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** | Migration guide from Architecture v1.0 to v2.0 | Performing migration, understanding changes, troubleshooting |
| **[WORKFLOW_DIAGRAMS.md](WORKFLOW_DIAGRAMS.md)** | Visual workflow diagrams for all processes | Understanding flows visually, training staff |
| **[ARCHITECTURE_V2_SUMMARY.md](ARCHITECTURE_V2_SUMMARY.md)** | Quick reference and change summary | Quick reference, planning, progress tracking |
| **[new_order_creation_flow.md](new_order_creation_flow.md)** | Cart-based order creation flow and API documentation | Implementing order creation, API integration, understanding cart-to-order conversion |

### 📂 Archived Documentation

| Folder | Description |
|--------|-------------|
| **[archived_old_auth/](archived_old_auth/)** | Legacy phone-first OTP and older authentication docs | Historical reference |

---

## 🎯 Quick Navigation

### I want to...

**...get started quickly**  
→ Read [QUICK_START.md](QUICK_START.md)

**...understand how email-first authentication works**  
→ Read [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md)

**...implement mart owner registration (two-step email verification)**  
→ Read [MART_REGISTRATION_FLOW.md](MART_REGISTRATION_FLOW.md)

**...add a manager to a mart**  
→ Read [MANAGER_REGISTRATION_API.md](MANAGER_REGISTRATION_API.md)

**...set up email/SMTP for OTP delivery**  
→ Read [GMAIL_SMTP_SETUP.md](GMAIL_SMTP_SETUP.md)

**...integrate authentication in the frontend**  
→ See frontend integration section in [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#frontend-integration)

**...migrate from phone-first to email-first**  
→ Follow [EMAIL_FIRST_AUTH_SUMMARY.md](EMAIL_FIRST_AUTH_SUMMARY.md#migration-steps)

**...test the authentication flows**  
→ Run `node test-email-first-auth.js`

**...understand the new 6-user role architecture**  
→ Read [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md)

**...migrate to the new architecture**  
→ Follow [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

**...implement the cart system**  
→ See Cart System section in [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md#cart-system)

**...implement service queues (FIFO)**  
→ See Service Queue Management in [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md#service-queue-management)

**...see visual workflow diagrams**  
→ Read [WORKFLOW_DIAGRAMS.md](WORKFLOW_DIAGRAMS.md)

**...get a quick reference of all changes**  
→ Read [ARCHITECTURE_V2_SUMMARY.md](ARCHITECTURE_V2_SUMMARY.md)

**...track implementation progress**  
→ Use checklists in [ARCHITECTURE_V2_SUMMARY.md](ARCHITECTURE_V2_SUMMARY.md#implementation-checklist)

---

## 🔑 Key Concepts

### Email-First OTP Authentication

The system uses an **email-first** approach where:
1. User enters **email address only**
2. OTP is sent to their email (no SMS costs!)
3. After OTP verification:
   - **Existing user**: Logged in immediately with JWT token
   - **New user**: Prompted to complete profile registration

### Why Email-First?

✅ **Cost-Effective**: No SMS charges - email is free  
✅ **Universal**: Everyone has an email address  
✅ **Better UX**: No confusing "user not found" errors  
✅ **Simpler**: Single flow for login and signup  
✅ **Passwordless**: No passwords to remember or store  
✅ **Professional**: Branded HTML email templates  
✅ **Secure**: OTP-based verification with rate limiting  

---

## 📖 Document Summaries

### EMAIL_FIRST_AUTH_GUIDE.md
**Complete authentication system guide** (708 lines)

Contents:
- Overview and benefits of email-first authentication
- Authentication flow diagrams
- Database schema (OtpVerification, OtpSession)
- API endpoints for all user types
- Email service integration (SMTP)
- Frontend integration (React & Flutter examples)
- Email provider setup (Gmail, SendGrid, AWS SES, etc.)
- Security considerations
- Troubleshooting

**Best for**: Deep understanding, frontend integration, production setup

---

### MART_REGISTRATION_FLOW.md
**Mart owner two-step email verification flow** (588 lines)

Contents:
- Complete 5-step registration flow
- Owner email verification
- Mart email verification
- Complete registration with mart and owner details
- API endpoint details
- Request/response examples
- Frontend integration notes

**Best for**: Implementing owner registration, understanding mart setup

---

### MANAGER_REGISTRATION_API.md
**Manager registration API documentation** (406 lines)

Contents:
- Complete API reference
- Request/response formats
- Authentication requirements
- Error responses
- cURL and JavaScript examples
- Security notes

**Best for**: Adding managers to a mart, API integration

---

### EMAIL_FIRST_AUTH_SUMMARY.md
**Implementation summary and migration guide** (317 lines)

Contents:
- What changed from phone-first
- Files created/modified
- Database changes
- API endpoint changes
- Migration steps
- Environment variable setup
- Test results

**Best for**: Quick overview, migration from phone-first, deployment

---

### QUICK_START.md
**Quick setup and testing guide** (512 lines)

- Environment setup
- Starting the server
- Running test scripts
- Manual API testing with curl
- Email integration testing
- Troubleshooting

**Best for**: First-time setup, testing

---

### GMAIL_SMTP_SETUP.md
**Gmail SMTP configuration guide** (145 lines)

- Step-by-step Gmail setup
- Enabling 2-Step Verification
- Generating App Password
- Environment variable configuration
- Testing and troubleshooting

**Best for**: Setting up Gmail for sending OTP emails

---

## 🧪 Testing

### Interactive Tests
```bash
node test-email-first-auth.js
```
Full test suite for all user types (owner, manager, customer, delivery)

### Manual Testing
```bash
# Send OTP
curl -X POST http://localhost:3000/api/v1/auth/customer/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Check console (dev mode) or email inbox for OTP, then verify
curl -X POST http://localhost:3000/api/v1/auth/customer/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","otp":"123456"}'
```

---

## 🔌 API Endpoints Summary

All user types follow the same pattern:

```
POST /api/v1/auth/{userType}/send-otp
POST /api/v1/auth/{userType}/verify-otp
POST /api/v1/auth/{userType}/complete-registration
```

Where `{userType}` is one of:
- `owner` - Mart owners/admins
- `manager` - Mart managers
- `customer` - App customers
- `delivery` - Delivery staff

Common endpoints:
```
POST /api/v1/auth/resend-otp
POST /api/v1/auth/logout
```

---

## 🛠️ Development Environment

### Without SMTP (Console Mode)
- OTPs displayed in server console
- No emails actually sent
- Perfect for development and testing
- Default mode

### With SMTP (Production Mode)
- Real emails sent to users
- Requires SMTP configuration (Gmail, SendGrid, etc.)
- See [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#email-service) for setup

---

## 📁 Folder Structure

```
docs/
├── README.md (this file)
├── QUICK_START.md
├── EMAIL_FIRST_AUTH_GUIDE.md
├── EMAIL_FIRST_AUTH_SUMMARY.md
├── MART_REGISTRATION_FLOW.md
├── MANAGER_REGISTRATION_API.md
├── GMAIL_SMTP_SETUP.md
└── archived_old_auth/ (legacy documentation)
    ├── PHONE_FIRST_AUTH_GUIDE.md
    ├── PHONE_FIRST_AUTH_IMPLEMENTATION_SUMMARY.md
    ├── TWILIO_SETUP_GUIDE.md
    ├── OTP_AUTHENTICATION_GUIDE.md
    └── ... (other old docs)
```

---

## 🔄 Migration from Phone-First

If you're coming from the phone-first authentication system:

**Old System (Phone-First):**
- Phone number as primary identifier
- SMS OTP delivery (costs money)
- Twilio integration required
- Phone verification fields in database

**New System (Email-First):**
- Email address as primary identifier  
- Email OTP delivery (free)
- SMTP integration (multiple providers)
- Email-based verification
- Phone is now optional contact info

**Migration Steps:**
1. Install nodemailer: `npm install nodemailer`
2. Clear OTP data: `node clear-otp-and-migrate.js`
3. Run migration: `npx prisma migrate dev --name switch_to_email_first_auth`
4. Update `.env` with SMTP config
5. Restart server
6. Test with `node test-email-first-auth.js`

See [EMAIL_FIRST_AUTH_SUMMARY.md](EMAIL_FIRST_AUTH_SUMMARY.md) for detailed migration guide.

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution | Reference |
|-------|----------|-----------|
| Server won't start | Check PostgreSQL, port 3000 | QUICK_START.md |
| OTP email not received | Check spam, verify SMTP config | EMAIL_FIRST_AUTH_GUIDE.md |
| Invalid OTP error | OTP expires in 5 min, max 5 attempts | EMAIL_FIRST_AUTH_GUIDE.md |
| Session expired | Session lasts 30 min, request new OTP | EMAIL_FIRST_AUTH_GUIDE.md |
| Rate limit error | Wait 60 seconds between OTP requests | EMAIL_FIRST_AUTH_GUIDE.md |
| SMTP connection failed | Verify SMTP credentials, check firewall | EMAIL_FIRST_AUTH_GUIDE.md |

---

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] Set up SMTP provider account (Gmail, SendGrid, etc.)
- [ ] Configure SMTP environment variables
- [ ] Set up email domain authentication (SPF, DKIM, DMARC)
- [ ] Run database migrations
- [ ] Test with real email accounts
- [ ] Verify emails don't go to spam
- [ ] Set up monitoring and logging
- [ ] Configure rate limiting at API gateway level
- [ ] Set up cron job for expired OTP cleanup
- [ ] Test all user type flows (owner, manager, customer, delivery)

See [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#production-checklist) for details.

---

## 📧 Email Providers

Supported SMTP providers:
- **Gmail** - Easy setup with App Password
- **SendGrid** - Reliable with free tier
- **AWS SES** - Scalable for high volume
- **Mailgun** - Developer-friendly
- **Mailjet** - Good deliverability

See [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#email-service) for setup instructions.

---

## 📞 Support

For issues or questions:
- Check the [Email-First Auth Guide](EMAIL_FIRST_AUTH_GUIDE.md) first
- Review [Quick Start](QUICK_START.md) for setup issues
- Check troubleshooting sections in each guide
- Review server logs in `backend/logs/`
- Examine error responses for detailed error codes

---

## 📝 Contributing

When adding new documentation:
1. Follow the existing structure and format
2. Include code examples where appropriate
3. Add the document to this README index
4. Keep examples up to date with code changes
5. Archive old documentation when superseded

---

**Last Updated**: November 5, 2025  
**Authentication Version**: 3.0 (Email-First OTP)  
**API Version**: v1  
**Current Architecture**: Email-First OTP with Two-Step Mart Owner Registration

