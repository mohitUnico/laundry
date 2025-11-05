# Add Manager to Mart API

## Overview
A dedicated convenience endpoint to add a manager user to an existing laundry mart. This endpoint automatically sets the role to 'manager' and associates the user with the specified mart.

## Endpoint Details

### **POST** `/api/v1/marts/:martId/managers`

**Description**: Add a manager to an existing mart

**Access**: Private (Admin only)

**Authentication**: Required (Bearer Token)

## URL Parameters

| Parameter | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| martId    | UUID   | Yes      | ID of the mart        |

## Request Body

```json
{
  "fullName": "John Doe",
  "email": "john.manager@example.com",
  "phone": "9876543210",
  "password": "SecurePass123!",
  "isActive": true
}
```

### Request Fields

| Field     | Type    | Required | Description                              | Validation                    |
|-----------|---------|----------|------------------------------------------|-------------------------------|
| fullName  | string  | Yes      | Full name of the manager                 | Min 3, Max 255 characters     |
| email     | string  | Yes      | Email address (must be unique)           | Valid email format            |
| phone     | string  | Yes      | Phone number                             | 10-digit Indian mobile number |
| password  | string  | Yes      | Password for the manager account         | Min 8 characters              |
| isActive  | boolean | No       | Whether the account is active (default: true) | -                         |

## Success Response

**Status Code**: `201 Created`

```json
{
  "success": true,
  "data": {
    "user_id": "uuid-here",
    "mart_id": "mart-uuid-here",
    "full_name": "John Doe",
    "email": "john.manager@example.com",
    "phone": "9876543210",
    "role": "manager",
    "is_active": true,
    "created_at": "2025-10-30T12:00:00.000Z",
    "updated_at": "2025-10-30T12:00:00.000Z",
    "mart": {
      "mart_id": "mart-uuid-here",
      "mart_name": "Clean & Fresh Laundry",
      "contact_email": "contact@cleanfresh.com",
      "contact_phone": "9123456789"
    }
  },
  "message": "Manager added to mart successfully"
}
```

## Error Responses

### Validation Error
**Status Code**: `400 Bad Request`

```json
{
  "success": false,
  "message": "Validation failed",
  "errorCode": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "email",
      "message": "Please provide a valid email address"
    }
  ],
  "timestamp": "2025-10-30T12:00:00.000Z",
  "path": "/api/v1/marts/uuid-here/managers"
}
```

### Duplicate Email Error
**Status Code**: `400 Bad Request`

```json
{
  "success": false,
  "message": "A user with this email already exists",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2025-10-30T12:00:00.000Z",
  "path": "/api/v1/marts/uuid-here/managers"
}
```

### Mart Not Found
**Status Code**: `404 Not Found`

```json
{
  "success": false,
  "message": "Mart not found",
  "errorCode": "NOT_FOUND",
  "timestamp": "2025-10-30T12:00:00.000Z",
  "path": "/api/v1/marts/invalid-uuid/managers"
}
```

### Inactive Mart Error
**Status Code**: `400 Bad Request`

```json
{
  "success": false,
  "message": "Cannot add managers to an inactive mart",
  "errorCode": "INTERNAL_ERROR",
  "timestamp": "2025-10-30T12:00:00.000Z",
  "path": "/api/v1/marts/uuid-here/managers"
}
```

### Unauthorized Error
**Status Code**: `401 Unauthorized`

```json
{
  "success": false,
  "message": "No token provided",
  "errorCode": "AUTHENTICATION_ERROR",
  "timestamp": "2025-10-30T12:00:00.000Z",
  "path": "/api/v1/marts/uuid-here/managers"
}
```

### Forbidden Error (Not Admin)
**Status Code**: `403 Forbidden`

```json
{
  "success": false,
  "message": "You do not have permission to perform this action",
  "errorCode": "AUTHORIZATION_ERROR",
  "timestamp": "2025-10-30T12:00:00.000Z",
  "path": "/api/v1/marts/uuid-here/managers"
}
```

## Example Usage

### cURL Example

```bash
curl -X POST http://localhost:3000/api/v1/marts/123e4567-e89b-12d3-a456-426614174000/managers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -d '{
    "fullName": "John Doe",
    "email": "john.manager@example.com",
    "phone": "9876543210",
    "password": "SecurePass123!",
    "isActive": true
  }'
```

### JavaScript (Axios) Example

```javascript
const axios = require('axios');

async function addManager(martId, managerData) {
  try {
    const response = await axios.post(
      `http://localhost:3000/api/v1/marts/${martId}/managers`,
      {
        fullName: 'John Doe',
        email: 'john.manager@example.com',
        phone: '9876543210',
        password: 'SecurePass123!',
        isActive: true
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${YOUR_JWT_TOKEN}`
        }
      }
    );

    console.log('Manager added:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error adding manager:', error.response.data);
    throw error;
  }
}

// Usage
addManager('123e4567-e89b-12d3-a456-426614174000', managerData);
```

### Python Example

```python
import requests
import json

def add_manager(mart_id, manager_data, token):
    url = f"http://localhost:3000/api/v1/marts/{mart_id}/managers"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    
    payload = {
        "fullName": "John Doe",
        "email": "john.manager@example.com",
        "phone": "9876543210",
        "password": "SecurePass123!",
        "isActive": True
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code == 201:
        print("Manager added successfully!")
        return response.json()
    else:
        print(f"Error: {response.json()}")
        return None

# Usage
mart_id = "123e4567-e89b-12d3-a456-426614174000"
jwt_token = "your_jwt_token_here"
result = add_manager(mart_id, manager_data, jwt_token)
```

## Business Logic

1. **Mart Validation**:
   - Verifies mart exists
   - Checks if mart is active
   - Throws error if mart is inactive or not found

2. **Email Uniqueness**:
   - Checks if email is already registered
   - Email must be unique across all users

3. **Password Security**:
   - Password is hashed using bcrypt (10 rounds)
   - Original password is never stored

4. **Role Assignment**:
   - Role is automatically set to 'manager'
   - Cannot be changed via this endpoint

5. **Mart Association**:
   - User is automatically associated with the specified mart
   - Mart ID is taken from URL parameter

## Database Changes

This endpoint creates a new record in the `users` table with the following data:

```sql
INSERT INTO users (
  user_id,
  mart_id,
  full_name,
  email,
  phone,
  password,
  role,
  is_active,
  created_at,
  updated_at
) VALUES (
  uuid_generate_v4(),
  'mart-uuid',
  'John Doe',
  'john.manager@example.com',
  '9876543210',
  '$2b$10$hashed_password_here',
  'manager',
  true,
  NOW(),
  NOW()
);
```

## Security Considerations

1. **Authentication Required**: Must provide valid JWT token
2. **Authorization**: Only users with 'admin' role can add managers
3. **Password Hashing**: Passwords are hashed with bcrypt before storage
4. **Input Validation**: All inputs are validated using Joi schemas
5. **SQL Injection Prevention**: Prisma ORM handles parameterization

## Differences from `/api/v1/marts/users` Endpoint

| Feature | `/marts/users` | `/marts/:martId/managers` |
|---------|---------------|---------------------------|
| Mart ID location | Request body | URL parameter |
| Role specification | Required in body (can be admin/manager/staff) | Automatically set to 'manager' |
| Use case | Add any type of user | Specifically add managers |
| Simplicity | More flexible | More convenient |

## Related Endpoints

- **POST** `/api/v1/marts/register` - Register a new mart with owner
- **POST** `/api/v1/marts/users` - Add any user (admin/manager/staff) to mart
- **GET** `/api/v1/marts/:martId/users` - Get all users of a mart
- **GET** `/api/v1/marts/:martId` - Get mart details

## Notes

- The manager account is created as active by default (`isActive: true`)
- Password must be at least 8 characters long
- Phone number must be a valid 10-digit Indian mobile number (starting with 6-9)
- Email must be unique across the entire system
- The endpoint returns the created manager data with mart details but excludes the password

## Testing

To test this endpoint:

1. First, register a mart using `/api/v1/marts/register`
2. Login as admin to get JWT token
3. Use the JWT token to call this endpoint
4. Verify the manager was created in the database
5. Test login with the manager credentials

```bash
# Step 1: Register mart (returns martId)
# Step 2: Login as admin (returns JWT token)
# Step 3: Add manager
curl -X POST http://localhost:3000/api/v1/marts/{MART_ID}/managers \
  -H "Authorization: Bearer {ADMIN_JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

