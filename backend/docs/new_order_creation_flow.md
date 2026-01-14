# New Order Creation Flow

**Version**: 2.0  
**Last Updated**: January 2025  
**Status**: Active  
**Related Documents**: [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md), [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Key Changes](#key-changes)
3. [Order Creation Flow](#order-creation-flow)
4. [Database Schema Changes](#database-schema-changes)
5. [API Endpoints](#api-endpoints)
6. [Request/Response Formats](#requestresponse-formats)
7. [Error Handling](#error-handling)
8. [Examples](#examples)
9. [Best Practices](#best-practices)
10. [Migration Notes](#migration-notes)

---

## Overview

The order creation system has been redesigned to use a **cart-based approach** where orders are created directly from active customer carts. This change provides:

- **Better data integrity**: Orders are created from validated cart data
- **Preserved item details**: Individual cloth item selections are stored in `OrderItemSelection`
- **Unified pricing model**: Single `OrderItem` table handles both `per_unit` and `per_kg` pricing
- **Simplified API**: Frontend only needs to send `cart_id` instead of complex item arrays
- **Automatic cart cleanup**: Cart is marked inactive and items are deleted after order creation

### Before vs After

**Before (v1.0):**
- Orders created with direct `items` array
- Separate `OrderItem` and `OrderItemKg` tables
- No cart integration
- Item selections not preserved

**After (v2.0):**
- Orders created from active cart (`cart_id`)
- Unified `OrderItem` table with `pricing_type` field
- `OrderItemSelection` table preserves individual cloth items
- Cart automatically cleaned up after order creation

---

## Key Changes

### 1. Database Schema

#### Removed Models
- ❌ `OrderItemKg` - Removed (consolidated into `OrderItem`)

#### Enhanced Models

**`OrderItem`** - Now handles both pricing types:
```prisma
model OrderItem {
  item_id      String          @id @default(uuid())
  order_id     String
  service_id   String          // NEW: Links to service
  pricing_type PricingModel    // NEW: 'per_unit' or 'per_kg'
  clothes_id   String?         // Optional: null for per_kg items
  quantity     Int?            // Optional: null for per_kg items
  weight_kg    Decimal?        // NEW: For per_kg pricing
  unit_price   Decimal         // Price per unit or per kg
  subtotal     Decimal
  item_status  OrderItemStatus @default(pending)
  // ... timestamps
  item_selections OrderItemSelection[] // NEW: Individual cloth items
}
```

**`OrderItemSelection`** - NEW model:
```prisma
model OrderItemSelection {
  selection_id String      @id @default(uuid())
  order_item_id String
  cloth_id     String
  quantity     Int
  created_at   DateTime    @default(now())
  order_item   OrderItem   @relation(...)
  cloth_item   ClothesItem @relation(...)
}
```

#### Updated Relations
- `Service` now has `order_items` relation
- `ClothesItem` now has `order_item_selections` relation
- `Order` removed `order_items_kg` relation

### 2. API Changes

**Request Payload:**
- ❌ Removed: `items` array, `pricing_model`
- ✅ Added: `cart_id` (required)
- ✅ Kept: `pickup_address_id`, `delivery_address_id`, `order_type`, optional dates/instructions

**Response:**
- Returns order details with `items_count` and `total_amount`
- Cart is automatically marked inactive

### 3. Service Logic

The order service now:
1. Validates active cart exists and belongs to customer
2. Fetches cart with all items and selections
3. Validates all services and cloth items are active
4. Converts cart items to order items (handles both pricing types)
5. Creates `OrderItemSelection` records for per-unit items
6. Calculates total amount
7. Creates order
8. Marks cart inactive and deletes cart items

---

## Order Creation Flow

### High-Level Flow

```
┌─────────────────┐
│   Customer      │
│   (Frontend)    │
└────────┬────────┘
         │
         │ 1. Add items to cart
         │    POST /api/v1/cart/items
         ▼
┌─────────────────┐
│   Active Cart   │
│   (Database)    │
└────────┬────────┘
         │
         │ 2. Create order from cart
         │    POST /api/v1/orders/create_order
         │    { cart_id, addresses, order_type }
         ▼
┌─────────────────┐
│  Order Service  │
│  (Backend)      │
└────────┬────────┘
         │
         │ 3. Validate cart & items
         │ 4. Convert cart → order items
         │ 5. Calculate totals
         │ 6. Create order
         │ 7. Create order items
         │ 8. Create order item selections
         │ 9. Mark cart inactive
         │ 10. Delete cart items
         ▼
┌─────────────────┐
│   Order Created │
│   (Database)    │
└─────────────────┘
```

### Detailed Step-by-Step Process

#### Step 1: Customer Adds Items to Cart
```javascript
// Customer adds items to active cart
POST /api/v1/cart/items
{
  "items": [
    {
      "service_id": "service-uuid-1",
      "pricing_type": "per_unit",
      "selections": [
        { "cloth_id": "cloth-uuid-1", "quantity": 3 },
        { "cloth_id": "cloth-uuid-2", "quantity": 2 }
      ]
    },
    {
      "service_id": "service-uuid-2",
      "pricing_type": "per_kg",
      "weight_kg": 5.5
    }
  ]
}
```

#### Step 2: Customer Creates Order from Cart
```javascript
// Customer creates order from active cart
POST /api/v1/orders/create_order
{
  "cart_id": "cart-uuid",
  "pickup_address_id": "address-uuid-1",
  "delivery_address_id": "address-uuid-2",
  "order_type": "both",
  "pickup_date": "2025-01-15T10:00:00Z",
  "delivery_date": "2025-01-16T14:00:00Z",
  "special_instructions": "Handle with care"
}
```

#### Step 3: Backend Processing (Transaction)

1. **Validate Customer**
   - Check customer exists
   - Verify customer owns the cart

2. **Validate Addresses**
   - Verify pickup and delivery addresses belong to customer
   - Check addresses are valid UUIDs

3. **Fetch and Validate Cart**
   - Load active cart with all items and selections
   - Verify cart belongs to customer
   - Check cart is not empty
   - Validate all services are active
   - Validate all cloth items are active (for per_unit items)

4. **Determine Pricing Model**
   - If all cart items are `per_unit` → `pricing_model: 'per_unit'`
   - If all cart items are `per_kg` → `pricing_model: 'per_kg'`
   - If mixed → defaults to `'per_unit'` (can be configured)

5. **Convert Cart Items to Order Items**

   **For Per-Unit Items:**
   - Calculate total quantity from all selections
   - Calculate subtotal: sum of (quantity × unit_price) for each selection
   - Create `OrderItem` with `pricing_type: 'per_unit'`
   - Create `OrderItemSelection` records for each cloth item

   **For Per-Kg Items:**
   - Validate service has `per_kg_price`
   - Calculate subtotal: `weight_kg × per_kg_price`
   - Create `OrderItem` with `pricing_type: 'per_kg'`
   - No `OrderItemSelection` records needed

6. **Calculate Order Total**
   - Sum all order item subtotals
   - Store in `Order.total_amount`

7. **Create Order**
   - Insert order record with status `'placed'`
   - Set dates, addresses, instructions

8. **Create Order Items**
   - Insert all `OrderItem` records
   - Link to order and service

9. **Create Order Item Selections**
   - Insert `OrderItemSelection` records for per-unit items
   - Preserves individual cloth item quantities

10. **Cleanup Cart**
    - Mark cart as `is_active: false`
    - Delete all cart items (cascade deletes selections)

#### Step 4: Response
```json
{
  "success": true,
  "data": {
    "order_id": "order-uuid",
    "pickup_address_id": "address-uuid-1",
    "delivery_address_id": "address-uuid-2",
    "pricing_model": "per_unit",
    "order_type": "both",
    "total_amount": "450.00",
    "items_count": 2
  },
  "message": "Order created successfully"
}
```

---

## Database Schema Changes

### OrderItem Model (Enhanced)

```prisma
model OrderItem {
  item_id      String          @id @default(uuid())
  order_id     String
  service_id   String          // NEW: Links to service
  pricing_type PricingModel    // NEW: 'per_unit' or 'per_kg'
  
  // For per_unit pricing
  clothes_id   String?         // Reference to first cloth item (optional)
  quantity     Int?            // Total quantity (sum of selections)
  
  // For per_kg pricing
  weight_kg    Decimal?        @db.Decimal(10, 2)
  
  // Common fields
  unit_price   Decimal         @db.Decimal(10, 2) // Price per unit or per kg
  subtotal     Decimal         @db.Decimal(10, 2)
  item_status  OrderItemStatus @default(pending)
  assigned_at  DateTime?
  completed_at DateTime?
  created_at   DateTime        @default(now())
  updated_at   DateTime        @updatedAt
  
  // Relations
  clothes      ClothesItem?    @relation(fields: [clothes_id], references: [cloth_id])
  service      Service         @relation(fields: [service_id], references: [service_id])
  order        Order           @relation(fields: [order_id], references: [order_id], onDelete: Cascade)
  item_selections OrderItemSelection[]

  @@index([order_id])
  @@index([service_id])
  @@index([item_status])
  @@index([pricing_type])
  @@map("order_items")
}
```

### OrderItemSelection Model (New)

```prisma
model OrderItemSelection {
  selection_id String      @id @default(uuid())
  order_item_id String
  cloth_id     String
  quantity     Int
  created_at   DateTime    @default(now())
  order_item   OrderItem   @relation(fields: [order_item_id], references: [item_id], onDelete: Cascade)
  cloth_item   ClothesItem @relation(fields: [cloth_id], references: [cloth_id])

  @@index([order_item_id])
  @@index([cloth_id])
  @@map("order_item_selections")
}
```

### Order Model (Updated)

```prisma
model Order {
  // ... existing fields ...
  order_items  OrderItem[]  // Updated: removed order_items_kg
  // ... rest of model ...
}
```

### Service Model (Updated)

```prisma
model Service {
  // ... existing fields ...
  order_items OrderItem[]  // NEW: Links to order items
  // ... rest of model ...
}
```

### ClothesItem Model (Updated)

```prisma
model ClothesItem {
  // ... existing fields ...
  order_item_selections OrderItemSelection[]  // NEW: Links to order selections
  // ... rest of model ...
}
```

---

## API Endpoints

### Create Order from Cart

**Endpoint:** `POST /api/v1/orders/create_order`

**Authentication:** Required (JWT Bearer token)

**Authorization:** Customer role only

**Description:** Creates an order from the customer's active cart. The cart is automatically marked inactive and its items are deleted after successful order creation.

---

## Request/Response Formats

### Request

**Headers:**
```http
POST /api/v1/orders/create_order HTTP/1.1
Host: api.laundryapp.com
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Body:**
```json
{
  "cart_id": "550e8400-e29b-41d4-a716-446655440000",
  "pickup_address_id": "660e8400-e29b-41d4-a716-446655440001",
  "delivery_address_id": "770e8400-e29b-41d4-a716-446655440002",
  "order_type": "both",
  "pickup_date": "2025-01-15T10:00:00Z",
  "delivery_date": "2025-01-16T14:00:00Z",
  "special_instructions": "Handle with care, fragile items"
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `cart_id` | `string (UUID)` | ✅ Yes | Active cart ID to convert to order |
| `pickup_address_id` | `string (UUID)` | ✅ Yes | Customer address ID for pickup |
| `delivery_address_id` | `string (UUID)` | ✅ Yes | Customer address ID for delivery |
| `order_type` | `string` | ✅ Yes | One of: `pickup_only`, `drop_only`, `both`, `express_delivery` |
| `pickup_date` | `string (ISO 8601)` | ❌ No | Scheduled pickup date/time (defaults to current date) |
| `delivery_date` | `string (ISO 8601)` | ❌ No | Scheduled delivery date/time (defaults to pickup_date) |
| `special_instructions` | `string` | ❌ No | Special handling instructions for the order |

### Success Response

**Status Code:** `201 Created`

**Body:**
```json
{
  "success": true,
  "data": {
    "order_id": "880e8400-e29b-41d4-a716-446655440003",
    "pickup_address_id": "660e8400-e29b-41d4-a716-446655440001",
    "delivery_address_id": "770e8400-e29b-41d4-a716-446655440002",
    "pricing_model": "per_unit",
    "order_type": "both",
    "total_amount": "450.00",
    "items_count": 2
  },
  "message": "Order created successfully"
}
```

**Response Field Descriptions:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | `boolean` | Always `true` for successful requests |
| `data.order_id` | `string (UUID)` | Created order ID |
| `data.pickup_address_id` | `string (UUID)` | Pickup address ID |
| `data.delivery_address_id` | `string (UUID)` | Delivery address ID |
| `data.pricing_model` | `string` | Derived from cart items: `per_unit` or `per_kg` |
| `data.order_type` | `string` | Order type as provided |
| `data.total_amount` | `string` | Total order amount (decimal as string) |
| `data.items_count` | `number` | Number of order items created |
| `message` | `string` | Success message |

---

## Error Handling

### Error Response Format

All errors follow this structure:

```json
{
  "success": false,
  "message": "Error message description",
  "errorCode": "ERROR_CODE",
  "errors": [
    {
      "field": "field_name",
      "message": "Field-specific error message"
    }
  ],
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

### Common Error Scenarios

#### 1. Validation Errors (400 Bad Request)

**Invalid Cart ID:**
```json
{
  "success": false,
  "message": "Invalid order payload",
  "errorCode": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "cart_id",
      "message": "cart_id must be a valid UUID"
    }
  ]
}
```

**Missing Required Fields:**
```json
{
  "success": false,
  "message": "Invalid order payload",
  "errorCode": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "pickup_address_id",
      "message": "pickup_address_id is required"
    }
  ]
}
```

#### 2. Not Found Errors (404 Not Found)

**Cart Not Found:**
```json
{
  "success": false,
  "message": "Active cart not found",
  "errorCode": "NOT_FOUND",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

**Customer Not Found:**
```json
{
  "success": false,
  "message": "Customer not found",
  "errorCode": "NOT_FOUND",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

#### 3. Business Logic Errors (400 Bad Request)

**Empty Cart:**
```json
{
  "success": false,
  "message": "Cart is empty. Add items to cart before creating an order",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

**Inactive Service:**
```json
{
  "success": false,
  "message": "One or more services in cart are inactive",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

**Invalid Address:**
```json
{
  "success": false,
  "message": "Invalid pickup or delivery address",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

**Per-Kg Service Missing Price:**
```json
{
  "success": false,
  "message": "Service abc-123 does not support per_kg pricing",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

#### 4. Authorization Errors (401/403)

**Unauthorized (No Token):**
```json
{
  "success": false,
  "message": "No token provided",
  "errorCode": "UNAUTHORIZED",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

**Forbidden (Wrong Role):**
```json
{
  "success": false,
  "message": "Only customers can create orders",
  "errorCode": "FORBIDDEN",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

#### 5. Server Errors (500 Internal Server Error)

```json
{
  "success": false,
  "message": "Internal server error",
  "errorCode": "INTERNAL_ERROR",
  "timestamp": "2025-01-15T10:00:00Z",
  "path": "/api/v1/orders/create_order"
}
```

---

## Examples

### Example 1: Per-Unit Order

**Cart Contents:**
- Service: "Regular Wash"
  - Shirt × 3 (₹40 each)
  - Pants × 2 (₹50 each)

**Request:**
```json
{
  "cart_id": "cart-uuid-123",
  "pickup_address_id": "addr-uuid-1",
  "delivery_address_id": "addr-uuid-2",
  "order_type": "both"
}
```

**Processing:**
1. Cart item with `pricing_type: 'per_unit'`
2. Selections: Shirt (3), Pants (2)
3. Subtotal: (3 × ₹40) + (2 × ₹50) = ₹220

**Result:**
- 1 `OrderItem` with `pricing_type: 'per_unit'`, `quantity: 5`, `subtotal: ₹220`
- 2 `OrderItemSelection` records:
  - Shirt: quantity 3
  - Pants: quantity 2

### Example 2: Per-Kg Order

**Cart Contents:**
- Service: "Bulk Wash"
  - Mixed items: 5.5 kg (₹100 per kg)

**Request:**
```json
{
  "cart_id": "cart-uuid-456",
  "pickup_address_id": "addr-uuid-1",
  "delivery_address_id": "addr-uuid-2",
  "order_type": "both"
}
```

**Processing:**
1. Cart item with `pricing_type: 'per_kg'`
2. Weight: 5.5 kg
3. Price per kg: ₹100
4. Subtotal: 5.5 × ₹100 = ₹550

**Result:**
- 1 `OrderItem` with `pricing_type: 'per_kg'`, `weight_kg: 5.5`, `subtotal: ₹550`
- 0 `OrderItemSelection` records (not needed for per-kg)

### Example 3: Mixed Order (Per-Unit + Per-Kg)

**Cart Contents:**
- Service A: "Regular Wash" (per_unit)
  - Shirt × 2 (₹40 each)
- Service B: "Bulk Wash" (per_kg)
  - Mixed items: 3 kg (₹100 per kg)

**Request:**
```json
{
  "cart_id": "cart-uuid-789",
  "pickup_address_id": "addr-uuid-1",
  "delivery_address_id": "addr-uuid-2",
  "order_type": "both"
}
```

**Processing:**
1. Cart item 1: `per_unit` → Subtotal: ₹80
2. Cart item 2: `per_kg` → Subtotal: ₹300
3. Total: ₹380
4. Pricing model: `'per_unit'` (default for mixed)

**Result:**
- 2 `OrderItem` records:
  - Item 1: `pricing_type: 'per_unit'`, `quantity: 2`, `subtotal: ₹80`
  - Item 2: `pricing_type: 'per_kg'`, `weight_kg: 3`, `subtotal: ₹300`
- 1 `OrderItemSelection` record (for item 1 only):
  - Shirt: quantity 2

### Example 4: Complete Request Flow

**Step 1: Add Items to Cart**
```bash
POST /api/v1/cart/items
Authorization: Bearer <customer-token>
Content-Type: application/json

{
  "items": [
    {
      "service_id": "service-uuid-1",
      "pricing_type": "per_unit",
      "selections": [
        { "cloth_id": "cloth-uuid-1", "quantity": 3 },
        { "cloth_id": "cloth-uuid-2", "quantity": 2 }
      ]
    }
  ]
}

# Response:
{
  "success": true,
  "data": {
    "cart_id": "cart-uuid-123",
    "added_cart_item_ids": ["cart-item-uuid-1"]
  }
}
```

**Step 2: Create Order from Cart**
```bash
POST /api/v1/orders/create_order
Authorization: Bearer <customer-token>
Content-Type: application/json

{
  "cart_id": "cart-uuid-123",
  "pickup_address_id": "addr-uuid-1",
  "delivery_address_id": "addr-uuid-2",
  "order_type": "both",
  "pickup_date": "2025-01-15T10:00:00Z",
  "delivery_date": "2025-01-16T14:00:00Z"
}

# Response:
{
  "success": true,
  "data": {
    "order_id": "order-uuid-456",
    "pickup_address_id": "addr-uuid-1",
    "delivery_address_id": "addr-uuid-2",
    "pricing_model": "per_unit",
    "order_type": "both",
    "total_amount": "220.00",
    "items_count": 1
  },
  "message": "Order created successfully"
}
```

**Step 3: Verify Cart is Inactive**
```bash
GET /api/v1/cart
Authorization: Bearer <customer-token>

# Response: Cart with is_active: false (or not returned if filtering active carts)
```

---

## Best Practices

### Frontend Implementation

1. **Cart Management**
   - Always create/update cart before order creation
   - Validate cart has items before showing "Checkout" button
   - Handle cart expiration gracefully

2. **Order Creation**
   - Show loading state during order creation
   - Handle errors gracefully with user-friendly messages
   - Redirect to order tracking page after successful creation
   - Clear cart UI after successful order

3. **Error Handling**
   - Check for empty cart before order creation
   - Validate addresses are selected
   - Handle inactive services/cloth items
   - Show appropriate error messages

4. **User Experience**
   - Allow order creation only when cart is not empty
   - Show order summary before final confirmation
   - Display total amount clearly
   - Provide order confirmation with order ID

### Backend Implementation

1. **Validation**
   - Always validate cart belongs to customer
   - Check all services and items are active
   - Validate addresses belong to customer
   - Ensure cart is not empty

2. **Transaction Management**
   - Use database transactions for order creation
   - Rollback on any error
   - Ensure atomicity of cart cleanup

3. **Error Messages**
   - Provide clear, actionable error messages
   - Include field-level validation errors
   - Log errors for debugging

4. **Performance**
   - Use efficient queries with proper indexes
   - Batch create operations where possible
   - Consider caching for frequently accessed data

### Database Considerations

1. **Indexes**
   - Ensure indexes on `cart_id`, `customer_id`, `order_id`
   - Index `pricing_type` for filtering
   - Index `service_id` for service-based queries

2. **Data Integrity**
   - Use foreign key constraints
   - Cascade deletes appropriately
   - Validate data at database level

3. **Queries**
   - Use `include` for related data
   - Avoid N+1 queries
   - Use transactions for multi-step operations

---

## Migration Notes

### Database Migration

1. **Run Prisma Migration:**
   ```bash
   npx prisma migrate dev --name unify_order_items_and_add_selections
   ```

2. **Data Migration (if needed):**
   - Existing `OrderItemKg` records need to be migrated
   - Create migration script to convert:
     ```sql
     -- Example migration SQL
     INSERT INTO order_items (
       item_id, order_id, service_id, pricing_type,
       clothes_id, quantity, weight_kg, unit_price, subtotal,
       item_status, created_at, updated_at
     )
     SELECT 
       gen_random_uuid(),
       order_id,
       -- service_id needs to be derived from order context
       'per_kg',
       NULL,
       NULL,
       weight_kg,
       price_per_kg,
       subtotal,
       'pending',
       created_at,
       updated_at
     FROM order_items_kg;
     ```

3. **Cleanup:**
   - Drop `order_items_kg` table after migration
   - Update any queries referencing `OrderItemKg`

### API Migration

1. **Frontend Changes:**
   - Update order creation to use `cart_id` instead of `items`
   - Remove `pricing_model` from request (now derived)
   - Update error handling for new error codes

2. **Backend Changes:**
   - Update any services that create orders directly
   - Update tests to use cart-based approach
   - Update API documentation

3. **Testing:**
   - Test order creation with per-unit items
   - Test order creation with per-kg items
   - Test order creation with mixed items
   - Test error scenarios
   - Test cart cleanup after order creation

### Breaking Changes

1. **API Request Format:**
   - ❌ Removed: `items` array
   - ❌ Removed: `pricing_model` field
   - ✅ Added: `cart_id` field (required)

2. **Database Schema:**
   - ❌ Removed: `OrderItemKg` table
   - ✅ Added: `OrderItemSelection` table
   - ✅ Modified: `OrderItem` table structure

3. **Response Format:**
   - ✅ Added: `items_count` field
   - ✅ Changed: `total_amount` format (string)

---

## Related Documentation

- [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md) - Complete architecture overview
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration from v1.0 to v2.0
- [WORKFLOW_DIAGRAMS.md](WORKFLOW_DIAGRAMS.md) - Visual workflow diagrams
- [SERVICE_CATALOG_RELATIONSHIPS.md](SERVICE_CATALOG_RELATIONSHIPS.md) - Service catalog structure

---

## Changelog

### Version 2.0 (January 2025)
- ✅ Unified `OrderItem` table for both pricing types
- ✅ Added `OrderItemSelection` for preserving item details
- ✅ Cart-based order creation
- ✅ Automatic cart cleanup after order creation
- ✅ Removed `OrderItemKg` table
- ✅ Enhanced validation and error handling

### Version 1.0 (Previous)
- Direct order creation with items array
- Separate `OrderItem` and `OrderItemKg` tables
- No cart integration
- Item selections not preserved

---

**Last Updated:** January 2025  
**Maintained By:** Backend Team  
**Questions?** Contact the development team or refer to [README.md](README.md)

