# Service Management API Documentation

**Last Updated**: December 2024  
**Version**: 1.0

---

## Overview

The Service Management API allows mart owners and managers to manage their service catalog. When a new mart is registered, default services are automatically created for all service categories. Mart owners can then add, update, or delete additional services as needed.

---

## Table of Contents

1. [Service Categories](#service-categories)
2. [Default Services](#default-services)
3. [API Endpoints](#api-endpoints)
4. [Request/Response Formats](#requestresponse-formats)
5. [Error Handling](#error-handling)
6. [Examples](#examples)

---

## Service Categories

Service categories are common across all laundry marts and are seeded during database initialization. The following categories are available:

1. **Regular Wash** (display_order: 1)
   - Description: Fast & Fresh Laundry

2. **Pro Clean** (display_order: 2)
   - Description: Expert dry cleaning

3. **Home Linens** (display_order: 3)
   - Description: Household items

4. **Luxury Care** (display_order: 4)
   - Description: Delicate fabric treatment

5. **Add-On Services** (display_order: 5)
   - Description: Additional premium services

---

## Default Services

When a new mart is registered, the following default services are automatically created:

### Regular Wash Category
1. **Wash and Fold**
   - Description: Professional washing and folding service
   - Base Price: $0.00
   - Per Kg Price: $4.00
   - Estimated Hours: 4
   - Display Order: 1

2. **Wash and Iron**
   - Description: Professional washing and Ironing service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 2

3. **Stain Removal**
   - Description: Professional Handwash Service
   - Base Price: $0.00
   - Per Kg Price: $8.00
   - Estimated Hours: 9
   - Display Order: 3

### Pro Clean Category
1. **Stain Removal**
   - Description: Professional Stain removal service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 1

2. **Dry Clean**
   - Description: Professional Dry cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 2

3. **Shoe Cleaning**
   - Description: Professional Shoe Cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 3

4. **Winter Wear**
   - Description: Professional winter wear cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 4

### Luxury Care Category
1. **Steam Press**
   - Description: Professional Steam Press service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 1

2. **Designer Wear**
   - Description: Professional designer wear washing service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 2

### Home Linens Category
1. **Carpet**
   - Description: Professional Carpet Cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 1

2. **Curtains**
   - Description: Professional Curtains Cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 1

3. **Blankets**
   - Description: Professional Blankets Cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 2

4. **Bedsheets**
   - Description: Professional Bedsheets Cleaning service
   - Base Price: $0.00
   - Per Kg Price: $5.00
   - Estimated Hours: 6
   - Display Order: 1

### Add-On Services Category
1. **Express**
   - Description: Express service for same day delivery(4-6 hours)
   - Base Price: $10.00
   - Per Kg Price: $0.00
   - Estimated Hours: 6
   - Display Order: 1

---

## API Endpoints

### Base URL
```
/api/v1/services
```

### Authentication
All endpoints (except `/categories`) require JWT authentication with `admin` or `manager` role.

---

### 1. Get Service Categories

**GET** `/api/v1/services/categories`

Get all active service categories. This endpoint is public (no authentication required).

#### Response
```json
{
  "success": true,
  "data": [
    {
      "category_id": "uuid",
      "category_name": "Regular Wash",
      "description": "Fast & Fresh Laundry",
      "icon_url": "https://picsum.photos/seed/regular-wash/200/200",
      "display_order": 1,
      "is_active": true,
      "created_at": "2024-12-01T00:00:00.000Z",
      "updated_at": "2024-12-01T00:00:00.000Z"
    }
  ]
}
```

---

### 2. Get Mart Services

**GET** `/api/v1/services`

Get all services for the authenticated mart owner's mart.

#### Query Parameters
- `categoryId` (optional): Filter by category ID (UUID)
- `isActive` (optional): Filter by active status (`true` or `false`)

#### Headers
```
Authorization: Bearer <jwt_token>
```

#### Response
```json
{
  "success": true,
  "data": [
    {
      "service_id": "uuid",
      "category_id": "uuid",
      "mart_id": "uuid",
      "service_name": "Wash and Fold",
      "description": "Professional washing and folding service",
      "base_price": "0.00",
      "per_kg_price": "4.00",
      "estimated_hours": 4,
      "icon_url": "https://picsum.photos/seed/wash-fold/200/200",
      "is_active": true,
      "display_order": 1,
      "created_at": "2024-12-01T00:00:00.000Z",
      "updated_at": "2024-12-01T00:00:00.000Z",
      "category": {
        "category_id": "uuid",
        "category_name": "Regular Wash",
        "description": "Fast & Fresh Laundry",
        "icon_url": "https://picsum.photos/seed/regular-wash/200/200"
      }
    }
  ]
}
```

---

### 3. Add Service

**POST** `/api/v1/services`

Add a new service to the authenticated mart owner's mart.

#### Headers
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

#### Request Body
```json
{
  "categoryId": "uuid",
  "serviceName": "Premium Wash",
  "description": "Premium washing service with fabric softener",
  "basePrice": 5.00,
  "perKgPrice": 6.00,
  "estimatedHours": 8,
  "iconUrl": "https://picsum.photos/seed/premium-wash/200/200",
  "isActive": true,
  "displayOrder": 4
}
```

#### Field Descriptions
- `categoryId` (required): UUID of the service category
- `serviceName` (required): Name of the service (2-255 characters)
- `description` (optional): Service description (max 1000 characters)
- `basePrice` (optional): Base price in dollars (default: 0.00, min: 0)
- `perKgPrice` (optional): Price per kilogram (default: null, min: 0)
- `estimatedHours` (required): Estimated hours to complete (min: 1)
- `iconUrl` (optional): URL to service icon image (max 500 characters, must be valid URL)
- `isActive` (optional): Whether service is active (default: true)
- `displayOrder` (optional): Display order within category (default: 0, min: 0)

#### Response
```json
{
  "success": true,
  "data": {
    "service_id": "uuid",
    "category_id": "uuid",
    "mart_id": "uuid",
    "service_name": "Premium Wash",
    "description": "Premium washing service with fabric softener",
    "base_price": "5.00",
    "per_kg_price": "6.00",
    "estimated_hours": 8,
    "icon_url": "https://picsum.photos/seed/premium-wash/200/200",
    "is_active": true,
    "display_order": 4,
    "created_at": "2024-12-01T00:00:00.000Z",
    "updated_at": "2024-12-01T00:00:00.000Z",
    "category": {
      "category_id": "uuid",
      "category_name": "Regular Wash",
      "description": "Fast & Fresh Laundry"
    }
  },
  "message": "Service added successfully"
}
```

---

### 4. Update Service

**PATCH** `/api/v1/services/:serviceId`

Update an existing service. Only services belonging to the authenticated mart owner's mart can be updated.

#### Headers
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

#### Request Body
```json
{
  "serviceName": "Updated Service Name",
  "description": "Updated description",
  "basePrice": 10.00,
  "perKgPrice": 7.00,
  "estimatedHours": 10,
  "iconUrl": "https://picsum.photos/seed/updated/200/200",
  "isActive": false,
  "displayOrder": 5
}
```

All fields are optional. At least one field must be provided.

#### Response
```json
{
  "success": true,
  "data": {
    "service_id": "uuid",
    "category_id": "uuid",
    "mart_id": "uuid",
    "service_name": "Updated Service Name",
    "description": "Updated description",
    "base_price": "10.00",
    "per_kg_price": "7.00",
    "estimated_hours": 10,
    "icon_url": "https://picsum.photos/seed/updated/200/200",
    "is_active": false,
    "display_order": 5,
    "created_at": "2024-12-01T00:00:00.000Z",
    "updated_at": "2024-12-01T00:00:00.000Z",
    "category": {
      "category_id": "uuid",
      "category_name": "Regular Wash",
      "description": "Fast & Fresh Laundry"
    }
  },
  "message": "Service updated successfully"
}
```

---

### 5. Delete Service

**DELETE** `/api/v1/services/:serviceId`

Soft delete a service by setting `is_active` to `false`. Only services belonging to the authenticated mart owner's mart can be deleted.

#### Headers
```
Authorization: Bearer <jwt_token>
```

#### Response
```json
{
  "success": true,
  "message": "Service deleted successfully"
}
```

---

## Error Handling

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes

#### 400 Bad Request
- `VALIDATION_ERROR`: Request validation failed
- `INVALID_CATEGORY`: Category ID is invalid or category is inactive

#### 403 Forbidden
- `UNAUTHORIZED`: Service does not belong to your mart

#### 404 Not Found
- `MART_NOT_FOUND`: Mart not found
- `SERVICE_NOT_FOUND`: Service not found
- `CATEGORY_NOT_FOUND`: Service category not found

#### 409 Conflict
- `DUPLICATE_SERVICE`: A service with this name already exists in this category for your mart

#### 500 Internal Server Error
- `INTERNAL_ERROR`: Unexpected server error

---

## Examples

### Example 1: Get All Service Categories

```bash
curl -X GET http://localhost:5000/api/v1/services/categories
```

### Example 2: Get All Services for a Mart

```bash
curl -X GET \
  http://localhost:5000/api/v1/services \
  -H "Authorization: Bearer <jwt_token>"
```

### Example 3: Get Services by Category

```bash
curl -X GET \
  "http://localhost:5000/api/v1/services?categoryId=<category_uuid>" \
  -H "Authorization: Bearer <jwt_token>"
```

### Example 4: Add a New Service

```bash
curl -X POST \
  http://localhost:5000/api/v1/services \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "categoryId": "uuid-of-regular-wash-category",
    "serviceName": "Premium Wash",
    "description": "Premium washing service with fabric softener",
    "basePrice": 5.00,
    "perKgPrice": 6.00,
    "estimatedHours": 8,
    "iconUrl": "https://picsum.photos/seed/premium-wash/200/200",
    "isActive": true,
    "displayOrder": 4
  }'
```

### Example 5: Update a Service

```bash
curl -X PATCH \
  http://localhost:5000/api/v1/services/<service_id> \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceName": "Updated Service Name",
    "basePrice": 10.00,
    "isActive": false
  }'
```

### Example 6: Delete a Service

```bash
curl -X DELETE \
  http://localhost:5000/api/v1/services/<service_id> \
  -H "Authorization: Bearer <jwt_token>"
```

---

## JavaScript/TypeScript Examples

### Fetch Service Categories

```javascript
const response = await fetch('http://localhost:5000/api/v1/services/categories');
const data = await response.json();
console.log(data.data); // Array of categories
```

### Add a New Service

```javascript
const response = await fetch('http://localhost:5000/api/v1/services', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    categoryId: 'uuid-of-category',
    serviceName: 'Premium Wash',
    description: 'Premium washing service',
    basePrice: 5.00,
    perKgPrice: 6.00,
    estimatedHours: 8,
    iconUrl: 'https://picsum.photos/seed/premium-wash/200/200',
    isActive: true,
    displayOrder: 4
  })
});

const data = await response.json();
if (data.success) {
  console.log('Service added:', data.data);
}
```

### Get Mart Services

```javascript
const response = await fetch('http://localhost:5000/api/v1/services', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const data = await response.json();
console.log(data.data); // Array of services
```

---

## Notes

1. **Automatic Service Creation**: Default services are automatically created when a new mart is registered. This happens asynchronously and does not block the registration process.

2. **Service Uniqueness**: Service names must be unique within a category for each mart. You can have the same service name in different categories.

3. **Soft Delete**: Deleting a service sets `is_active` to `false` but does not remove it from the database. This preserves order history and allows reactivation.

4. **Category Validation**: Services can only be added to active categories. Inactive categories cannot receive new services.

5. **Mart Isolation**: Each mart can only manage its own services. Services are automatically filtered by the `mart_id` from the JWT token.

---

**Documentation Version**: 1.0  
**Last Updated**: December 2024

