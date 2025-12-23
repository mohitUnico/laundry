# Migration Guide - Architecture v2.0

**From**: Single-stage order workflow with 2 user roles  
**To**: Multi-stage order workflow with 6 user roles  
**Date**: December 19, 2025

---

## Overview

This migration guide covers the transition from the previous architecture to the new 6-user role system with cart functionality and service queue management.

---

## Breaking Changes

### 1. Database Schema Changes

#### New Tables
- `CollectionManager`
- `ServiceMan`
- `DistributionManager`
- `Cart`
- `CartItem`
- `CartItemSelection`
- `ServiceQueueItem`

#### Modified Tables

**Order:**
- Added: `received_by_collection_manager_id`
- Added: `received_at`
- Added: `submitted_to_services_at`
- Added: `dispatched_by_distribution_manager_id`
- Added: `dispatched_at`
- Added: `payment_confirmed_at`

**OrderItem:**
- Added: `item_status` (enum: pending, in_progress, completed)
- Added: `assigned_at`
- Added: `completed_at`

**DeliveryStaff:**
- Added: `id_proof_type`
- Added: `id_proof_url`
- Added: `is_verified_by_admin`
- Modified: `verification_status` (now enum: pending, verified, rejected)

**Delivery:**
- Added: `needs_weight_machine`
- Added: `delivery_type` (enum: pickup, drop)

**Service:**
- Added: One-to-one relationship with `ServiceMan`

**Customer:**
- Added: One-to-many relationship with `Cart`

**User:**
- Modified: `role` is now enum (admin, owner)

#### New Enums

```prisma
enum UserRole {
  admin
  owner
}

enum VerificationStatus {
  pending
  verified
  rejected
}

enum OrderStatus {
  placed
  pickup_assigned
  picked_up
  received_by_collection
  submitted_to_services
  services_in_progress
  services_completed
  dispatch_assigned
  out_for_delivery
  payment_pending
  delivered
  closed
  cancelled
}

enum OrderItemStatus {
  pending
  in_progress
  completed
}

enum QueueStatus {
  pending
  in_progress
  completed
}

enum PaymentStatus {
  pending
  completed
  failed
  refunded
}

enum DeliveryType {
  pickup
  drop
}
```

### 2. API Changes

#### New Endpoints

**Cart Management:**
```
POST   /api/v1/cart/add-item
GET    /api/v1/cart
PUT    /api/v1/cart/update-item/:cartItemId
DELETE /api/v1/cart/remove-item/:cartItemId
POST   /api/v1/cart/checkout
DELETE /api/v1/cart/clear
```

**Collection Manager:**
```
GET    /api/v1/collection/incoming-orders
GET    /api/v1/collection/orders-received
GET    /api/v1/collection/orders-submitted
POST   /api/v1/collection/orders/:orderId/assign-pickup
POST   /api/v1/collection/orders/:orderId/mark-received
POST   /api/v1/collection/orders/:orderId/submit-to-services
```

**Service Man:**
```
GET    /api/v1/service-queue/pending
GET    /api/v1/service-queue/in-progress
GET    /api/v1/service-queue/completed
POST   /api/v1/service-queue/:queueItemId/start
POST   /api/v1/service-queue/:queueItemId/complete
POST   /api/v1/service-queue/:queueItemId/comment
```

**Distribution Manager:**
```
GET    /api/v1/distribution/services-completed
GET    /api/v1/distribution/orders-completed
GET    /api/v1/distribution/orders-dispatched
POST   /api/v1/distribution/orders/:orderId/assign-delivery
POST   /api/v1/distribution/orders/:orderId/dispatch
```

**Admin:**
```
POST   /api/v1/auth/collection-manager/complete-registration   (Owner/Admin only)
POST   /api/v1/auth/service-man/complete-registration          (Owner/Admin only; requires serviceId/serviceType)
POST   /api/v1/auth/distribution-manager/complete-registration (Owner/Admin only)
GET    /api/v1/admin/delivery-partners/pending-verification
POST   /api/v1/admin/delivery-partners/:staffId/verify
POST   /api/v1/admin/delivery-partners/:staffId/reject
```

**Delivery Partner:**
```
POST   /api/v1/delivery/register
POST   /api/v1/delivery/:deliveryId/confirm-payment
```

#### Modified Endpoints

**Order Creation:**
- **Old**: `POST /api/v1/orders`
- **New**: `POST /api/v1/cart/checkout` (creates order from cart)

**Order Status:**
- **Old**: Limited statuses (pending, in_progress, delivered)
- **New**: 12 detailed statuses (see OrderStatus enum)

### 3. Authentication Changes

#### New User Types
- `collection_manager`
- `service_man`
- `distribution_manager`

#### Updated Authentication Flow

**Collection Manager, Service Man, Distribution Manager:**
1. Account starts with email OTP verification (`send-otp` → `verify-otp`)
2. If new (`isNewUser: true`), profile creation is completed by Owner/Admin via:
   - `POST /api/v1/auth/collection-manager/complete-registration`
   - `POST /api/v1/auth/service-man/complete-registration` (requires serviceId/serviceType; 1 service man per service)
   - `POST /api/v1/auth/distribution-manager/complete-registration`
3. After profile exists, login is OTP-only (no owner/admin token required)

**Delivery Partner:**
1. Self-registration with email
2. Admin verification required
3. Access granted only after verification

---

## Migration Steps

### Step 1: Backup Database

```bash
# Create backup
pg_dump -U your_user -d laundry_db > backup_before_migration.sql
```

### Step 2: Update Dependencies

```bash
cd backend
npm install
```

### Step 3: Run Database Migration

```bash
# Generate Prisma client with new schema
npx prisma generate

# Create migration
npx prisma migrate dev --name architecture_v2_six_user_roles

# Verify migration
npx prisma migrate status
```

### Step 4: Seed Initial Data

```bash
# Run seed script to create initial staff accounts
npx prisma db seed
```

**Sample Seed Data:**

```javascript
// prisma/seed.js

// Create Collection Manager
await prisma.collectionManager.create({
  data: {
    mart_id: "existing-mart-id",
    full_name: "John Collection",
    email: "collection@laundrymart.com",
    phone: "+1234567890"
  }
});

// Create Distribution Manager
await prisma.distributionManager.create({
  data: {
    mart_id: "existing-mart-id",
    full_name: "Jane Distribution",
    email: "distribution@laundrymart.com",
    phone: "+1234567891"
  }
});

// Create Service Men (one per service)
const services = await prisma.service.findMany();
for (const service of services) {
  await prisma.serviceMan.create({
    data: {
      service_id: service.service_id,
      full_name: `${service.service_name} Service Man`,
      email: `${service.service_name.toLowerCase().replace(/\s/g, '')}@laundrymart.com`,
      phone: "+1234567892"
    }
  });
}
```

### Step 5: Update Existing Orders

```javascript
// scripts/migrate-existing-orders.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function migrateOrders() {
  // Update old order statuses to new statuses
  const statusMapping = {
    'pending': 'placed',
    'pickup_assigned': 'pickup_assigned',
    'picked_up': 'picked_up',
    'in_progress': 'services_in_progress',
    'wash_completed': 'services_completed',
    'out_for_delivery': 'out_for_delivery',
    'delivered': 'delivered',
    'cancelled': 'cancelled'
  };

  for (const [oldStatus, newStatus] of Object.entries(statusMapping)) {
    await prisma.order.updateMany({
      where: { order_status: oldStatus },
      data: { order_status: newStatus }
    });
    console.log(`Updated orders with status ${oldStatus} to ${newStatus}`);
  }

  // Set default item_status for existing order items
  await prisma.orderItem.updateMany({
    where: { item_status: null },
    data: { item_status: 'pending' }
  });

  console.log('Order migration completed');
}

migrateOrders()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
```

Run migration:
```bash
node scripts/migrate-existing-orders.js
```

### Step 6: Update Backend Services

#### Create New Services

**1. Cart Service** (`src/services/cart.service.js`):
```javascript
class CartService {
  async addItemToCart(customerId, cartItemData) { }
  async getCart(customerId) { }
  async updateCartItem(cartItemId, updateData) { }
  async removeCartItem(cartItemId) { }
  async checkout(customerId, checkoutData) { }
  async clearCart(customerId) { }
}
```

**2. Collection Service** (`src/services/collection.service.js`):
```javascript
class CollectionService {
  async getIncomingOrders(managerId) { }
  async assignPickupDelivery(orderId, staffId) { }
  async markOrderReceived(orderId, managerId) { }
  async submitToServices(orderId) { }
}
```

**3. Service Queue Service** (`src/services/service-queue.service.js`):
```javascript
class ServiceQueueService {
  async getPendingItems(serviceManId) { }
  async startItem(queueItemId) { }
  async completeItem(queueItemId) { }
  async addComment(queueItemId, comment) { }
}
```

**4. Distribution Service** (`src/services/distribution.service.js`):
```javascript
class DistributionService {
  async getCompletedServices() { }
  async getCompletedOrders() { }
  async assignDelivery(orderId, staffId) { }
  async dispatchOrder(orderId, managerId) { }
}
```

**5. Verification Service** (`src/services/verification.service.js`):
```javascript
class VerificationService {
  async getPendingDeliveryPartners() { }
  async verifyDeliveryPartner(staffId, adminId) { }
  async rejectDeliveryPartner(staffId, reason) { }
}
```

#### Update Existing Services

**Order Service** (`src/services/order.service.js`):
- Update `createOrder` to support cart checkout
- Add service queue item creation
- Update status transitions

**Delivery Service** (`src/services/delivery.service.js`):
- Add payment confirmation method
- Add weight machine requirement check
- Update delivery type handling

### Step 7: Create New Controllers

**1. Cart Controller** (`src/controllers/cart.controller.js`)

**2. Collection Manager Controller** (`src/controllers/collection-manager.controller.js`)

**3. Service Man Controller** (`src/controllers/service-man.controller.js`)

**4. Distribution Manager Controller** (`src/controllers/distribution-manager.controller.js`)

**5. Service Queue Controller** (`src/controllers/service-queue.controller.js`)

### Step 8: Update Authentication Middleware

**Role-based Access Control** (`src/middleware/role.middleware.js`):

```javascript
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        message: 'Access denied' 
      });
    }

    next();
  };
};

module.exports = { authorizeRoles };
```

Usage:
```javascript
router.get('/collection/incoming-orders', 
  authenticateJWT,
  authorizeRoles('collection_manager'),
  collectionController.getIncomingOrders
);
```

### Step 9: Update Routes

**Create new route files:**
- `src/routes/cart.routes.js`
- `src/routes/collection.routes.js`
- `src/routes/service-queue.routes.js`
- `src/routes/distribution.routes.js`

**Update index routes** (`src/routes/index.js`):
```javascript
app.use('/api/v1/cart', cartRoutes);
app.use('/api/v1/collection', collectionRoutes);
app.use('/api/v1/service-queue', serviceQueueRoutes);
app.use('/api/v1/distribution', distributionRoutes);
```

### Step 10: Update Frontend Applications

#### Customer App (Flutter)

**New Screens:**
1. Cart Screen
2. Service Selection Screen
3. Enhanced Order Tracking (12 stages)

**Modified Screens:**
- Service Catalog (add to cart functionality)
- Order History (new status labels)

#### Delivery Partner App (Flutter)

**New Screens:**
1. Registration Flow
2. Verification Status Screen
3. Payment Confirmation Screen

**Modified Screens:**
- Delivery Requests (weight machine indicator)
- Profile (verification status)

#### Admin Panel (React)

**New Pages:**
1. Staff Management
   - Collection Managers
   - Service Men
   - Distribution Managers
2. Delivery Partner Verification
3. Service Man Assignment

**New Dashboards:**
4. Collection Manager Dashboard
5. Service Man Dashboard
6. Distribution Manager Dashboard

### Step 11: Environment Variables

**Add to `.env`:**
```env
# New feature flags
ENABLE_CART=true
ENABLE_SERVICE_QUEUE=true
AUTO_ASSIGN_DELIVERY_TIMEOUT_MS=120000  # 2 minutes

# Verification settings
REQUIRE_DELIVERY_PARTNER_VERIFICATION=true
```

### Step 12: Testing

#### Database Testing
```bash
# Test schema
npx prisma validate

# Test migrations
npx prisma migrate dev

# View data
npx prisma studio
```

#### API Testing

**Test Cart Workflow:**
```bash
# Add to cart
curl -X POST http://localhost:3000/api/v1/cart/add-item \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service_id": "service-uuid",
    "pricing_type": "per_unit",
    "items": [
      {"cloth_id": "cloth-uuid", "quantity": 2}
    ]
  }'

# Checkout
curl -X POST http://localhost:3000/api/v1/cart/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pickup_address_id": "address-uuid",
    "delivery_address_id": "address-uuid",
    "pickup_date": "2025-12-20T10:00:00Z",
    "delivery_date": "2025-12-22T14:00:00Z"
  }'
```

**Test Collection Manager Flow:**
```bash
# Get incoming orders
curl -X GET http://localhost:3000/api/v1/collection/incoming-orders \
  -H "Authorization: Bearer $COLLECTION_MANAGER_TOKEN"

# Assign pickup
curl -X POST http://localhost:3000/api/v1/collection/orders/$ORDER_ID/assign-pickup \
  -H "Authorization: Bearer $COLLECTION_MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"staff_id": "delivery-staff-uuid"}'

# Mark received
curl -X POST http://localhost:3000/api/v1/collection/orders/$ORDER_ID/mark-received \
  -H "Authorization: Bearer $COLLECTION_MANAGER_TOKEN"

# Submit to services
curl -X POST http://localhost:3000/api/v1/collection/orders/$ORDER_ID/submit-to-services \
  -H "Authorization: Bearer $COLLECTION_MANAGER_TOKEN"
```

**Test Service Queue:**
```bash
# Get pending items
curl -X GET http://localhost:3000/api/v1/service-queue/pending \
  -H "Authorization: Bearer $SERVICE_MAN_TOKEN"

# Start item
curl -X POST http://localhost:3000/api/v1/service-queue/$QUEUE_ITEM_ID/start \
  -H "Authorization: Bearer $SERVICE_MAN_TOKEN"

# Complete item
curl -X POST http://localhost:3000/api/v1/service-queue/$QUEUE_ITEM_ID/complete \
  -H "Authorization: Bearer $SERVICE_MAN_TOKEN"
```

#### Integration Testing

Create test suite for complete order workflow:
```javascript
// tests/integration/order-workflow-v2.test.js

describe('Order Workflow v2', () => {
  test('Complete order lifecycle', async () => {
    // 1. Customer adds to cart
    // 2. Customer checks out
    // 3. Collection manager assigns pickup
    // 4. Delivery partner picks up
    // 5. Collection manager receives
    // 6. Collection manager submits to services
    // 7. Service man processes items
    // 8. Distribution manager dispatches
    // 9. Delivery partner delivers
    // 10. Payment confirmed
    // 11. Order closed
  });
});
```

### Step 13: Rollback Plan

If migration fails, rollback:

```bash
# Restore database
psql -U your_user -d laundry_db < backup_before_migration.sql

# Checkout previous code version
git checkout <previous-commit-hash>

# Reinstall dependencies
npm install

# Regenerate Prisma client
npx prisma generate
```

---

## Data Migration Checklist

- [ ] Backup database
- [ ] Update dependencies
- [ ] Run Prisma migrations
- [ ] Seed initial staff data
- [ ] Migrate existing orders
- [ ] Update order items with status
- [ ] Verify foreign key relationships
- [ ] Test data integrity

## Backend Migration Checklist

- [ ] Create cart service
- [ ] Create collection service
- [ ] Create service queue service
- [ ] Create distribution service
- [ ] Create verification service
- [ ] Update order service
- [ ] Update delivery service
- [ ] Create new controllers
- [ ] Update authentication middleware
- [ ] Create new routes
- [ ] Update environment variables
- [ ] Write unit tests
- [ ] Write integration tests

## Frontend Migration Checklist

### Customer App
- [ ] Implement cart UI
- [ ] Update service catalog
- [ ] Update order tracking
- [ ] Update order history

### Delivery Partner App
- [ ] Implement registration flow
- [ ] Add verification status screen
- [ ] Add weight machine indicator
- [ ] Add payment confirmation

### Admin Panel
- [ ] Implement staff management
- [ ] Implement verification workflow
- [ ] Create collection manager dashboard
- [ ] Create service man dashboard
- [ ] Create distribution manager dashboard

## Post-Migration Tasks

- [ ] Monitor error logs
- [ ] Check order processing times
- [ ] Verify auto-assignment working
- [ ] Verify FIFO queue ordering
- [ ] Test payment confirmation
- [ ] Test photo proof upload
- [ ] Verify analytics accuracy
- [ ] Update API documentation
- [ ] Update user guides
- [ ] Train staff on new workflows

---

## Troubleshooting

### Common Issues

**1. Migration fails with foreign key errors**
```bash
# Check for orphaned records
SELECT * FROM orders WHERE mart_id NOT IN (SELECT mart_id FROM laundry_mart);

# Clean up orphaned records before migration
DELETE FROM orders WHERE mart_id NOT IN (SELECT mart_id FROM laundry_mart);
```

**2. Existing orders have invalid statuses**
```bash
# Run migration script to update statuses
node scripts/migrate-existing-orders.js
```

**3. Service men not auto-assigned**
```sql
-- Ensure each service has a service man
SELECT s.service_id, s.service_name, sm.service_man_id
FROM services s
LEFT JOIN service_men sm ON s.service_id = sm.service_id
WHERE sm.service_man_id IS NULL;
```

**4. Cart checkout fails**
- Check cart has items
- Verify addresses exist
- Check service availability
- Verify pricing calculations

---

## Support

For migration support:
- Review [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md)
- Check backend logs: `backend/logs/`
- Review Prisma migrations: `backend/prisma/migrations/`
- Contact development team

---

**Migration Status**: Ready for Testing  
**Estimated Time**: 4-6 hours  
**Recommended**: Perform during low-traffic hours

