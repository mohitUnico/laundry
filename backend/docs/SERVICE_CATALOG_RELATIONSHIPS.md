# Service Catalog Relationships (ServiceCategory → Service → ClothesItem)

This document describes how the **service catalog** is modeled in the Laundry App database, using these tables:

- `service_categories` (Prisma model: `ServiceCategory`)
- `services` (Prisma model: `Service`)
- `clothes_items` (Prisma model: `ClothesItem`)

## API Endpoints (CRUD)

All endpoints below are mounted under:

- Base: `/api/v1/clothes`

Auth:
- Requires `Authorization: Bearer <JWT>`
- Role: `admin` or `manager`

### Service Categories

- **POST** `/api/v1/clothes/service-categories`
- **GET** `/api/v1/clothes/service-categories`
- **GET** `/api/v1/clothes/service-categories/:categoryId`
- **PUT** `/api/v1/clothes/service-categories/:categoryId`
- **DELETE** `/api/v1/clothes/service-categories/:categoryId`

### Services

- **POST** `/api/v1/clothes/services`
- **GET** `/api/v1/clothes/services`
- **GET** `/api/v1/clothes/services/:serviceId`
- **PUT** `/api/v1/clothes/services/:serviceId`
- **DELETE** `/api/v1/clothes/services/:serviceId`

### Clothes Items

- **POST** `/api/v1/clothes/clothes-items`
- **GET** `/api/v1/clothes/clothes-items`
- **GET** `/api/v1/clothes/clothes-items/:clothId`
- **PUT** `/api/v1/clothes/clothes-items/:clothId`
- **DELETE** `/api/v1/clothes/clothes-items/:clothId`

Backward compatibility:
- **POST** `/api/v1/clothes` (alias of **POST** `/api/v1/clothes/clothes-items`)

## Request Formats (JSON)

### ServiceCategory

#### Create (POST `/service-categories`)

```json
{
  "categoryName": "Regular Wash",
  "description": "Everyday washing services",
  "iconUrl": "https://.../icon.png",
  "displayOrder": 0,
  "isActive": true
}
```

#### Update (PUT `/service-categories/:categoryId`)

At least one field is required:

```json
{
  "categoryName": "Regular Wash (Updated)",
  "description": "Updated description",
  "iconUrl": "https://.../new-icon.png",
  "displayOrder": 1,
  "isActive": false
}
```

#### List (GET `/service-categories`)

Optional query params:
- `isActive` (boolean)

Example:
- `/api/v1/clothes/service-categories?isActive=true`

---

### Service

#### Create (POST `/services`)

`categoryId` is **required** and must reference an existing `service_categories.category_id`.

```json
{
  "categoryId": "uuid-of-category",
  "serviceName": "Wash & Iron",
  "description": "Washing + ironing",
  "basePrice": 99,
  "perKgPrice": 120,
  "estimatedHours": 24,
  "iconUrl": "https://.../service-icon.png",
  "isActive": true,
  "displayOrder": 0
}
```

#### Update (PUT `/services/:serviceId`)

At least one field is required. If `categoryId` is provided, it must reference an existing category.

```json
{
  "serviceName": "Wash & Iron (Updated)",
  "basePrice": 109,
  "isActive": true
}
```

#### List (GET `/services`)

Optional query params:
- `categoryId` (uuid)
- `isActive` (boolean)

Examples:
- `/api/v1/clothes/services?categoryId=uuid-of-category`
- `/api/v1/clothes/services?isActive=true`

---

### ClothesItem

#### Create (POST `/clothes-items`)

`serviceId` is **required** and must reference an existing `services.service_id`.

```json
{
  "serviceId": "uuid-of-service",
  "itemName": "Shirt",
  "perUnitPrice": 40,
  "iconUrl": "https://.../shirt.png",
  "isActive": true,
  "displayOrder": 0
}
```

#### Update (PUT `/clothes-items/:clothId`)

At least one field is required. If `serviceId` is provided, it must reference an existing service.

```json
{
  "itemName": "Shirt (Updated)",
  "perUnitPrice": 45,
  "isActive": true
}
```

#### List (GET `/clothes-items`)

Optional query params:
- `serviceId` (uuid)
- `isActive` (boolean)

Examples:
- `/api/v1/clothes/clothes-items?serviceId=uuid-of-service`
- `/api/v1/clothes/clothes-items?isActive=true`

## Relationship Overview

### 1) ServiceCategory → Service (1 : many)

- **Primary Key**: `service_categories.category_id`
- **Foreign Key**: `services.category_id` → `service_categories.category_id`
- **Meaning**: A single **Service Category** can contain many **Services**.

**Insertion rule**:
- To insert into `services`, you must provide a valid `category_id` that exists in `service_categories`.

### 2) Service → ClothesItem (1 : many)

- **Primary Key**: `services.service_id`
- **Foreign Key**: `clothes_items.service_id` → `services.service_id`
- **Meaning**: A single **Service** can contain many **Clothes Items**.

**Insertion rule**:
- To insert into `clothes_items`, you must provide a valid `service_id` that exists in `services`.

## Key Constraints

### Unique constraint on clothes items within a service

In `clothes_items`:
- `@@unique([service_id, item_name])`

Meaning:
- You cannot create two clothes items with the same `item_name` under the same `service_id`.

## Diagram (ERD-style)

```
ServiceCategory (service_categories)
  category_id (PK)
        |
        | 1-to-many (FK: services.category_id)
        v
Service (services)
  service_id (PK)
  category_id (FK)
        |
        | 1-to-many (FK: clothes_items.service_id)
        v
ClothesItem (clothes_items)
  cloth_id (PK)
  service_id (FK)
```

## Notes

- All three tables include `is_active`, enabling soft “catalog toggling” without deleting records.  
- If you choose to hard-delete categories/services/items, ensure there are no dependent records referencing them (foreign-key constraints will prevent unsafe deletes).


