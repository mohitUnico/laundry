# Backend Documentation Index

This document provides a comprehensive index of all backend documentation, organized by purpose and use case.

**Last Updated**: November 5, 2025  
**Current Architecture**: Email-First OTP Authentication with Two-Step Mart Owner Registration

---

## 📚 Quick Navigation by Use Case

### I want to...

#### 🚀 Get Started
- **First time setup** → [QUICK_START.md](QUICK_START.md)
- **Understand the architecture** → [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#architecture)

#### 🔐 Authentication
- **Understand email-first OTP system** → [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md)
- **Implement mart owner registration** → [MART_REGISTRATION_FLOW.md](MART_REGISTRATION_FLOW.md)
- **Add a manager to a mart** → [MANAGER_REGISTRATION_API.md](MANAGER_REGISTRATION_API.md)
- **Migrate from phone-first** → [EMAIL_FIRST_AUTH_SUMMARY.md](EMAIL_FIRST_AUTH_SUMMARY.md)

#### 📧 Email Configuration
- **Set up Gmail SMTP** → [GMAIL_SMTP_SETUP.md](GMAIL_SMTP_SETUP.md)
- **Configure other email providers** → [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#email-service)

#### 🔧 Development
- **Test authentication flows** → [QUICK_START.md](QUICK_START.md#testing)
- **Frontend integration** → [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#frontend-integration)

---

## 📖 Document Catalog

### Core Documentation

#### [README.md](README.md)
**Main documentation index and navigation hub**

- Complete documentation overview
- Quick navigation by use case
- Document summaries
- API endpoint summary
- Troubleshooting guide
- Deployment checklist

**Best for**: Starting point, finding the right document

---

#### [QUICK_START.md](QUICK_START.md)
**Quick setup and testing guide**

- Environment setup
- Database configuration
- Server startup
- Interactive testing
- Manual API testing with curl
- Email integration testing
- Troubleshooting common issues

**Best for**: First-time setup, testing, development

---

#### [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md)
**Complete email-first authentication system guide** (708 lines)

**Contents:**
- Overview and benefits
- Architecture and flow diagrams
- Database schema (OtpVerification, OtpSession)
- API endpoints for all user types
- Email service integration (SMTP)
- Frontend integration examples (React & Flutter)
- Email provider setup (Gmail, SendGrid, AWS SES, etc.)
- Security considerations
- Troubleshooting
- Production checklist

**Best for**: Deep understanding, frontend integration, production setup

---

#### [MART_REGISTRATION_FLOW.md](MART_REGISTRATION_FLOW.md)
**Mart owner two-step email verification flow** (588 lines)

**Contents:**
- Complete 5-step registration flow
- Owner email verification
- Mart email verification
- Complete registration with mart and owner details
- API endpoint details
- Request/response examples
- Frontend integration notes
- Data requirements
- Flow diagrams

**Best for**: Implementing owner registration, understanding mart setup

---

#### [MANAGER_REGISTRATION_API.md](MANAGER_REGISTRATION_API.md)
**Manager registration API documentation** (406 lines)

**Contents:**
- Complete API reference
- Request/response formats
- Authentication requirements
- Field descriptions
- Error responses
- cURL and JavaScript examples
- Complete flow example
- Security notes

**Best for**: Adding managers to a mart, API integration

---

#### [EMAIL_FIRST_AUTH_SUMMARY.md](EMAIL_FIRST_AUTH_SUMMARY.md)
**Implementation summary and migration guide** (317 lines)

**Contents:**
- What changed from phone-first
- Files created/modified
- Database changes
- API endpoint changes
- Migration steps
- Environment variable setup
- Test results
- Frontend changes needed

**Best for**: Quick overview, migration from phone-first, deployment

---

#### [GMAIL_SMTP_SETUP.md](GMAIL_SMTP_SETUP.md)
**Gmail SMTP configuration guide** (145 lines)

**Contents:**
- Step-by-step Gmail setup
- Enabling 2-Step Verification
- Generating App Password
- Environment variable configuration
- Testing SMTP connection
- Troubleshooting

**Best for**: Setting up Gmail for sending OTP emails

---

### Archived Documentation

#### [archived_old_auth/](archived_old_auth/)
**Legacy phone-first authentication documentation**

These documents are archived for historical reference only. They document the old phone-first authentication system that has been replaced by email-first authentication.

**Archived Documents:**
- `PHONE_FIRST_AUTH_GUIDE.md` - Old phone-first guide
- `PHONE_FIRST_AUTH_IMPLEMENTATION_SUMMARY.md` - Phone-first implementation
- `OTP_AUTHENTICATION_GUIDE.md` - Original OTP guide
- `TWILIO_SETUP_GUIDE.md` - Twilio SMS setup (no longer used)
- `MART_API_GUIDE.md` - Old mart API documentation
- `ADD_MANAGER_API.md` - Old manager API (replaced by MANAGER_REGISTRATION_API.md)
- Other legacy implementation summaries

**Note**: These are kept for reference only. Do not use for new implementations.

---

## 🎯 Common Tasks & Documentation

### Setting Up a New Environment

1. Read [QUICK_START.md](QUICK_START.md)
2. Follow environment setup section
3. Configure database and run migrations
4. Test with `node test-email-first-auth.js`

### Implementing Authentication

1. Read [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md) for overview
2. For owner registration: Read [MART_REGISTRATION_FLOW.md](MART_REGISTRATION_FLOW.md)
3. For manager registration: Read [MANAGER_REGISTRATION_API.md](MANAGER_REGISTRATION_API.md)
4. For frontend: See frontend integration section in [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#frontend-integration)

### Setting Up Email (SMTP)

1. Choose email provider (Gmail recommended for development)
2. Follow [GMAIL_SMTP_SETUP.md](GMAIL_SMTP_SETUP.md) for Gmail
3. For other providers: See [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#email-service)
4. Test email delivery

### Troubleshooting

1. Check [QUICK_START.md](QUICK_START.md#troubleshooting)
2. Review [EMAIL_FIRST_AUTH_GUIDE.md](EMAIL_FIRST_AUTH_GUIDE.md#troubleshooting)
3. Check server logs in `backend/logs/`
4. Review error responses for detailed error codes

---

## 📋 Current System Architecture

### Authentication System
- **Type**: Email-First OTP (Passwordless)
- **Version**: 3.0
- **Primary Identifier**: Email address
- **OTP Delivery**: Email (SMTP)
- **Session Management**: JWT tokens + session tokens

### User Types
1. **Mart Owners (Admin)**: Two-step email verification (owner + mart email)
2. **Managers**: Email verification + owner authorization
3. **Customers**: Email verification + address registration
4. **Delivery Staff**: Email verification + vehicle info

### Key Features
- ✅ No passwords (passwordless)
- ✅ No SMS costs (email-based)
- ✅ Smart user detection (existing vs new)
- ✅ Session-based registration
- ✅ Rate limiting and security
- ✅ Multiple SMTP provider support

---

## 🔄 Documentation Maintenance

### When to Update Documentation

1. **New Features**: Add new docs or update existing ones
2. **API Changes**: Update endpoint documentation
3. **Architecture Changes**: Update architecture guides
4. **Breaking Changes**: Update migration guides
5. **Bug Fixes**: Update troubleshooting sections

### Documentation Standards

- Follow existing structure and format
- Include code examples where appropriate
- Add to README.md index
- Keep examples up to date with code
- Archive old documentation when superseded
- Use consistent formatting and style

---

## 📞 Support & Resources

- **Main Documentation**: [README.md](README.md)
- **Architecture Rules**: `.cursor/rules/backend/`
- **API Guidelines**: `.cursor/rules/backend/backend-api-guideline.mdc`
- **Code Standards**: `.cursor/rules/backend/javascript-coding-standards.mdc`

---

**Documentation Version**: 1.0  
**Last Reviewed**: November 5, 2025

