# Staff Registration API Documentation (Collection Manager, Distribution Manager, Service Man)

## Overview

This document covers onboarding and login for the **staff roles** using **Email-First OTP Authentication**:

- **Collection Manager**
- **Distribution Manager**
- **Service Man** (must be linked to a service; **1 service man per 1 service**)

### Flow Summary

- **Login (all staff)**: `send-otp` → `verify-otp`
- **First-time profile creation (all staff)**: must be completed by **Mart Admin/Owner** using `complete-registration` (**requires owner/admin JWT**)

### Cross-role email restriction (Staff only)

If an email is already registered in `staff` under a different role:
- Sending OTP for another staff role will return an error like: **"This email is already registered as service man"**
- OTP will **not** be sent in that case.

---

## Collection Manager

### 1) Send OTP

```
POST /api/v1/auth/collection-manager/send-otp
```

```json
{
  "email": "collection.manager@example.com"
}
```

### 2) Verify OTP

```
POST /api/v1/auth/collection-manager/verify-otp
```

```json
{
  "email": "collection.manager@example.com",
  "otp": "123456"
}
```

### 3) Complete Registration (Owner/Admin Only)

```
POST /api/v1/auth/collection-manager/complete-registration
```

**Headers**

```http
Authorization: Bearer {owner_or_admin_jwt_token}
```

**Body**

```json
{
  "sessionToken": "abc123def456...",
  "collectionManagerData": {
    "fullName": "Collection Manager Name",
    "phone": "9876543210"
  }
}
```

**Notes**
- `email` is taken from the OTP session (not from `collectionManagerData`)

---

## Distribution Manager

### 1) Send OTP

```
POST /api/v1/auth/distribution-manager/send-otp
```

```json
{
  "email": "distribution.manager@example.com"
}
```

### 2) Verify OTP

```
POST /api/v1/auth/distribution-manager/verify-otp
```

```json
{
  "email": "distribution.manager@example.com",
  "otp": "123456"
}
```

### 3) Complete Registration (Owner/Admin Only)

```
POST /api/v1/auth/distribution-manager/complete-registration
```

**Headers**

```http
Authorization: Bearer {owner_or_admin_jwt_token}
```

**Body**

```json
{
  "sessionToken": "abc123def456...",
  "distributionManagerData": {
    "fullName": "Distribution Manager Name",
    "phone": "9876543210"
  }
}
```

**Notes**
- `email` is taken from the OTP session (not from `distributionManagerData`)

---

## Service Man

### Service ID Requirement (Registration Only)

- **Only during registration** (`complete-registration`), the owner/admin must provide `serviceId` (UUID).
- **For login** (`send-otp`, `verify-otp`), no service input is required.

### 1) Send OTP

```
POST /api/v1/auth/service-man/send-otp
```

```json
{
  "email": "serviceman@example.com"
}
```

### 2) Verify OTP

```
POST /api/v1/auth/service-man/verify-otp
```

```json
{
  "email": "serviceman@example.com",
  "otp": "123456"
}
```

**Response**
- Existing user → returns JWT token and also returns the linked `serviceName`
- New user → returns `sessionToken` (must be completed by owner/admin)

**Example success response (existing service man)**

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "isNewUser": false,
    "token": "jwt_token_here",
    "user": {
      "userId": "uuid",
      "email": "serviceman@example.com",
      "fullName": "Service Man Name",
      "role": "service_man",
      "serviceId": "service-uuid-here",
      "serviceName": "Wash and Fold"
    }
  }
}
```

### 3) Complete Registration (Owner/Admin Only)

```
POST /api/v1/auth/service-man/complete-registration
```

**Headers**

```http
Authorization: Bearer {owner_or_admin_jwt_token}
```

**Body**

```json
{
  "sessionToken": "abc123def456...",
  "serviceManData": {
    "fullName": "Service Man Name",
    "phone": "9876543210",
    "serviceId": "service-uuid-here"
  }
}
```

**Notes**
- Registration is rejected if the selected service already has a service man assigned.


