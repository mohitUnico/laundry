# Mart Management API Guide

Complete guide for Laundry Mart registration and user management endpoints.

## Table of Contents
1. [Register New Mart](#1-register-new-mart)
2. [Add User to Mart](#2-add-user-to-mart)
3. [Get Mart Details](#3-get-mart-details)
4. [Update Mart Details](#4-update-mart-details)
5. [Get All Marts](#5-get-all-marts)
6. [Get Mart Users](#6-get-mart-users)
7. [Deactivate Mart](#7-deactivate-mart)

---

## 1. Register New Mart

Register a new laundry mart along with an owner/admin user.

### Endpoint
```
POST /api/v1/marts/register
```

### Access
Public (No authentication required)

### Request Body

```json
{
  "martName": "Fresh Laundry Services",
  "contactEmail": "contact@freshlaundry.com",
  "contactPhone": "9876543210",
  "address": "123, MG Road, Bangalore, Karnataka, 560001",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "serviceRadiusKm": {
    "maxRadius": 15,
    "tiers": [
      {
        "minKm": 0,
        "maxKm": 5,
        "pricePerKm": 20
      },
      {
        "minKm": 5,
        "maxKm": 10,
        "pricePerKm": 40
      },
      {
        "minKm": 10,
        "maxKm": 15,
        "pricePerKm": 60
      }
    ]
  },
  "isActive": true,
  "owner": {
    "fullName": "John Doe",
    "email": "john@freshlaundry.com",
    "phone": "9876543211",
    "password": "SecurePass@123"
  }
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `martName` | String | Yes | Name of the laundry mart (3-255 chars) |
| `contactEmail` | String | Yes | Contact email (must be unique) |
| `contactPhone` | String | Yes | 10-digit Indian mobile number |
| `address` | String | Yes | Full address (10-1000 chars) |
| `latitude` | Number | Yes | Latitude coordinate (-90 to 90) |
| `longitude` | Number | Yes | Longitude coordinate (-180 to 180) |
| `serviceRadiusKm` | Object | Yes | Service area and pricing tiers |
| `serviceRadiusKm.maxRadius` | Number | Yes | Maximum service radius in km |
| `serviceRadiusKm.tiers` | Array | Yes | Pricing tiers based on distance |
| `isActive` | Boolean | No | Mart active status (default: true) |
| `owner` | Object | Yes | Owner/admin user details |
| `owner.fullName` | String | Yes | Full name (3-255 chars) |
| `owner.email` | String | Yes | Email (must be unique) |
| `owner.phone` | String | Yes | 10-digit mobile number |
| `owner.password` | String | Yes | Password (min 8 chars) |

### Success Response (201 Created)

```json
{
  "success": true,
  "data": {
    "mart": {
      "mart_id": "550e8400-e29b-41d4-a716-446655440000",
      "mart_name": "Fresh Laundry Services",
      "contact_email": "contact@freshlaundry.com",
      "contact_phone": "9876543210",
      "address": "123, MG Road, Bangalore, Karnataka, 560001",
      "latitude": "12.97160000",
      "longitude": "77.59460000",
      "service_radius_km": {
        "maxRadius": 15,
        "tiers": [
          {
            "minKm": 0,
            "maxKm": 5,
            "pricePerKm": 20
          }
        ]
      },
      "is_active": true,
      "created_at": "2025-10-30T10:00:00.000Z",
      "updated_at": "2025-10-30T10:00:00.000Z"
    },
    "owner": {
      "user_id": "660e8400-e29b-41d4-a716-446655440001",
      "mart_id": "550e8400-e29b-41d4-a716-446655440000",
      "full_name": "John Doe",
      "email": "john@freshlaundry.com",
      "phone": "9876543211",
      "role": "admin",
      "is_active": true,
      "created_at": "2025-10-30T10:00:00.000Z",
      "updated_at": "2025-10-30T10:00:00.000Z"
    }
  },
  "message": "Mart registered successfully"
}
```

### Error Responses

**400 Validation Error**
```json
{
  "success": false,
  "message": "Validation failed",
  "errorCode": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "contactEmail",
      "message": "Please provide a valid email address"
    }
  ]
}
```

**409 Conflict**
```json
{
  "success": false,
  "message": "A mart with this email already exists",
  "errorCode": "VALIDATION_ERROR"
}
```

### cURL Example

```bash
curl -X POST http://localhost:5000/api/v1/marts/register \
  -H "Content-Type: application/json" \
  -d '{
    "martName": "Fresh Laundry Services",
    "contactEmail": "contact@freshlaundry.com",
    "contactPhone": "9876543210",
    "address": "123, MG Road, Bangalore",
    "latitude": 12.9716,
    "longitude": 77.5946,
    "serviceRadiusKm": {
      "maxRadius": 15,
      "tiers": [
        {"minKm": 0, "maxKm": 5, "pricePerKm": 20},
        {"minKm": 5, "maxKm": 10, "pricePerKm": 40}
      ]
    },
    "owner": {
      "fullName": "John Doe",
      "email": "john@freshlaundry.com",
      "phone": "9876543211",
      "password": "SecurePass@123"
    }
  }'
```

---

## 2. Add User to Mart

Add a new user (admin/manager/staff) to an existing mart.

### Endpoint
```
POST /api/v1/marts/users
```

### Access
Private (Admin only)

### Headers
```
Authorization: Bearer <JWT_TOKEN>
```

### Request Body

```json
{
  "martId": "550e8400-e29b-41d4-a716-446655440000",
  "fullName": "Jane Smith",
  "email": "jane@freshlaundry.com",
  "phone": "9876543212",
  "password": "SecurePass@123",
  "role": "manager",
  "isActive": true
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `martId` | UUID | Yes | ID of the mart |
| `fullName` | String | Yes | Full name (3-255 chars) |
| `email` | String | Yes | Email (must be unique) |
| `phone` | String | Yes | 10-digit mobile number |
| `password` | String | Yes | Password (min 8 chars) |
| `role` | String | No | Role: admin, manager, staff (default: staff) |
| `isActive` | Boolean | No | User active status (default: true) |

### Success Response (201 Created)

```json
{
  "success": true,
  "data": {
    "user_id": "770e8400-e29b-41d4-a716-446655440002",
    "mart_id": "550e8400-e29b-41d4-a716-446655440000",
    "full_name": "Jane Smith",
    "email": "jane@freshlaundry.com",
    "phone": "9876543212",
    "role": "manager",
    "is_active": true,
    "created_at": "2025-10-30T10:00:00.000Z",
    "updated_at": "2025-10-30T10:00:00.000Z",
    "mart": {
      "mart_id": "550e8400-e29b-41d4-a716-446655440000",
      "mart_name": "Fresh Laundry Services",
      "contact_email": "contact@freshlaundry.com"
    }
  },
  "message": "User added to mart successfully"
}
```

### Error Responses

**401 Unauthorized**
```json
{
  "success": false,
  "message": "No token provided",
  "errorCode": "UNAUTHORIZED"
}
```

**403 Forbidden**
```json
{
  "success": false,
  "message": "Insufficient permissions",
  "errorCode": "FORBIDDEN"
}
```

**404 Not Found**
```json
{
  "success": false,
  "message": "Mart not found",
  "errorCode": "NOT_FOUND"
}
```

### cURL Example

```bash
curl -X POST http://localhost:5000/api/v1/marts/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "martId": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "Jane Smith",
    "email": "jane@freshlaundry.com",
    "phone": "9876543212",
    "password": "SecurePass@123",
    "role": "manager"
  }'
```

---

## 3. Get Mart Details

Retrieve detailed information about a specific mart.

### Endpoint
```
GET /api/v1/marts/:martId
```

### Access
Private (Authenticated users)

### Headers
```
Authorization: Bearer <JWT_TOKEN>
```

### URL Parameters
- `martId` (required): UUID of the mart

### Success Response (200 OK)

```json
{
  "success": true,
  "data": {
    "mart_id": "550e8400-e29b-41d4-a716-446655440000",
    "mart_name": "Fresh Laundry Services",
    "contact_email": "contact@freshlaundry.com",
    "contact_phone": "9876543210",
    "address": "123, MG Road, Bangalore",
    "latitude": "12.97160000",
    "longitude": "77.59460000",
    "service_radius_km": {
      "maxRadius": 15,
      "tiers": [...]
    },
    "is_active": true,
    "created_at": "2025-10-30T10:00:00.000Z",
    "updated_at": "2025-10-30T10:00:00.000Z",
    "users": [
      {
        "user_id": "660e8400-e29b-41d4-a716-446655440001",
        "full_name": "John Doe",
        "email": "john@freshlaundry.com",
        "phone": "9876543211",
        "role": "admin",
        "is_active": true,
        "created_at": "2025-10-30T10:00:00.000Z"
      }
    ],
    "_count": {
      "orders": 145,
      "services": 12,
      "delivery_staffs": 8
    }
  }
}
```

### cURL Example

```bash
curl -X GET http://localhost:5000/api/v1/marts/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 4. Update Mart Details

Update information for an existing mart.

### Endpoint
```
PATCH /api/v1/marts/:martId
```

### Access
Private (Admin only)

### Headers
```
Authorization: Bearer <JWT_TOKEN>
```

### Request Body

```json
{
  "martName": "Fresh Laundry Services Updated",
  "contactPhone": "9876543299",
  "serviceRadiusKm": {
    "maxRadius": 20,
    "tiers": [
      {"minKm": 0, "maxKm": 10, "pricePerKm": 25}
    ]
  }
}
```

### Success Response (200 OK)

```json
{
  "success": true,
  "data": {
    "mart_id": "550e8400-e29b-41d4-a716-446655440000",
    "mart_name": "Fresh Laundry Services Updated",
    "contact_email": "contact@freshlaundry.com",
    "contact_phone": "9876543299",
    "updated_at": "2025-10-30T11:00:00.000Z"
  },
  "message": "Mart updated successfully"
}
```

---

## 5. Get All Marts

Retrieve a paginated list of all marts (Super Admin only).

### Endpoint
```
GET /api/v1/marts
```

### Access
Private (Super Admin only)

### Query Parameters
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `isActive` (optional): Filter by active status (true/false)
- `search` (optional): Search by name, email, or phone

### Example Request
```
GET /api/v1/marts?page=1&limit=10&isActive=true&search=fresh
```

### Success Response (200 OK)

```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "totalPages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

---

## 6. Get Mart Users

Retrieve all users of a specific mart.

### Endpoint
```
GET /api/v1/marts/:martId/users
```

### Access
Private (Admin only)

### Query Parameters
- `role` (optional): Filter by role (admin/manager/staff)
- `isActive` (optional): Filter by active status

### Example Request
```
GET /api/v1/marts/550e8400-e29b-41d4-a716-446655440000/users?role=admin&isActive=true
```

---

## 7. Deactivate Mart

Deactivate a mart (soft delete).

### Endpoint
```
DELETE /api/v1/marts/:martId
```

### Access
Private (Super Admin only)

### Success Response (200 OK)

```json
{
  "success": true,
  "data": {
    "mart_id": "550e8400-e29b-41d4-a716-446655440000",
    "is_active": false,
    "updated_at": "2025-10-30T12:00:00.000Z"
  },
  "message": "Mart deactivated successfully"
}
```

---

## Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Authentication required or failed |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Testing with Postman

1. **Import Collection**: Create a new Postman collection for Laundry App API
2. **Set Environment Variables**:
   - `base_url`: http://localhost:5000/api/v1
   - `admin_token`: Your JWT token after login
3. **Test Registration**: Start with POST `/marts/register`
4. **Save Token**: Extract JWT from login response
5. **Test Protected Routes**: Add token to Authorization header

---

## Authentication Flow

1. **Register Mart**: POST `/marts/register` (Returns owner user details)
2. **Login**: POST `/auth/login` with owner credentials (Returns JWT token)
3. **Use Token**: Add `Authorization: Bearer <token>` header to all protected requests
4. **Add Users**: POST `/marts/users` with admin token

---

## Notes

- All passwords are automatically hashed with bcrypt before storage
- Email addresses must be unique across all users
- Contact emails must be unique across all marts
- Phone numbers follow Indian mobile format (10 digits starting with 6-9)
- Service radius pricing tiers must not overlap
- First user created with mart is always assigned 'admin' role
- Marts can be deactivated but not permanently deleted (soft delete)

