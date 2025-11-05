# 🚀 Mart Registration - Quick Reference

## API Endpoints (5 Steps)

### 1️⃣ Send Owner OTP
```bash
POST /api/v1/auth/owner/send-otp
{ "email": "owner@example.com" }
```

### 2️⃣ Verify Owner OTP
```bash
POST /api/v1/auth/owner/verify-otp
{ "email": "owner@example.com", "otp": "123456" }
→ Returns: { sessionToken: "..." }
```

### 3️⃣ Send Mart Email OTP
```bash
POST /api/v1/auth/owner/verify-mart-email/send-otp
{ "sessionToken": "...", "martEmail": "contact@mart.com" }
```

### 4️⃣ Verify Mart Email OTP
```bash
POST /api/v1/auth/owner/verify-mart-email/verify-otp
{
  "sessionToken": "...",
  "martEmail": "contact@mart.com",
  "otp": "789012"
}
```

### 5️⃣ Complete Registration
```bash
POST /api/v1/auth/owner/complete-registration
{
  "sessionToken": "...",
  "martData": {
    "martName": "Clean & Fresh",
    "martEmail": "contact@mart.com",
    "martContact": "+1234567890",
    "profileImageUrl": "https://...",
    "martCoordinates": { "latitude": 37.77, "longitude": -122.41 }
  },
  "ownerData": {
    "ownerName": "John Doe",
    "ownerPhone": "+1234567890",
    "ownerEmail": "owner@example.com"
  }
}
→ Returns: { token: "JWT...", mart: {...}, owner: {...} }
```

---

## 📚 Documentation

| What | Where |
|------|-------|
| **Complete Guide** | `backend/docs/MART_REGISTRATION_FLOW.md` |
| **What Changed** | `MART_REGISTRATION_UPDATE.md` |
| **Implementation Status** | `IMPLEMENTATION_COMPLETE.md` |
| **Auth System** | `backend/docs/EMAIL_FIRST_AUTH_GUIDE.md` |

---

## 🔑 Key Points

- ✅ **Two emails verified**: Owner personal + Mart business
- ✅ **Session token**: Valid for 30 minutes
- ✅ **OTP expiry**: 5 minutes
- ✅ **Rate limit**: 1 OTP per minute
- ✅ **Max attempts**: 5 per OTP

---

## 🧪 Test (Development)

```bash
# Start server
cd backend && npm run dev

# Check OTPs in logs
tail -f backend/logs/combined.log
```

---

## ⚡ Quick Commands

```bash
# Kill server
lsof -ti :3000 | xargs kill -9

# Start server
npm run dev

# Watch logs
tail -f logs/combined.log
```

---

**Server:** http://localhost:3000  
**API Base:** http://localhost:3000/api/v1

