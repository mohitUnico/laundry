# Laundry App - New Architecture Overview

**Version**: 2.0  
**Last Updated**: December 19, 2025  
**Status**: Updated Architecture with 6 User Roles  
**System Type**: Single Laundry Business

---

## Table of Contents

1. [Overview](#overview)
2. [User Roles](#user-roles)
3. [Order Workflow](#order-workflow)
4. [Cart System](#cart-system)
5. [Service Queue Management](#service-queue-management)
6. [Database Schema Changes](#database-schema-changes)
7. [API Endpoints](#api-endpoints)
8. [Frontend Requirements](#frontend-requirements)

---

## Overview

The Laundry App is designed for a **single laundry business** with a comprehensive workflow involving **6 distinct user roles** to manage the complete lifecycle of laundry orders from placement to delivery. This architecture introduces:

- **Single laundry operation** (not multi-tenant)
- **Cart-based ordering** for customers
- **Service-specific queues** with FIFO processing
- **Multi-stage order workflow** with clear handoffs between roles
- **Enhanced tracking and accountability** at each stage
- **Delivery partner verification** by admin
- **Payment confirmation** on delivery

**Important**: This system is designed for ONE laundry business. All staff, customers, and operations belong to a single laundry entity.

---

## User Roles

### 1. Admin (Business Owner)

**Primary Responsibilities:**
- Monitor all operations and analytics for the laundry business
- Create and manage staff accounts (Collection Manager, Distribution Manager, Service Man)
- Verify and approve Delivery Partners
- Configure business settings, services, and pricing
- Generate reports and analytics
- Manage service catalog and clothing items

**Access Level:** Full system access for the single laundry business

**Authentication:** Email-based with OTP verification

**Key Features:**
- Dashboard with comprehensive analytics
- Staff management interface
- Delivery partner verification workflow
- Service and pricing configuration
- Business settings (address, contact info, service radius)
- Report generation and export

**Note:** Single admin account for the laundry business

---

### 2. Customer

**Primary Responsibilities:**
- Browse service catalog
- Add items to cart
- Place orders with pickup and delivery scheduling
- Track order status in real-time
- Provide ratings and feedback

**Access Level:** Own orders and profile only

**Authentication:** Email-based with OTP verification

**Key Features:**
- Cart management with multiple services
- Dual pricing support (per-piece and per-kg)
- Multiple saved addresses
- Order tracking with detailed status
- Order history and reordering
- Payment options at checkout
- Rating and review system

**Cart Structure:**
```
Cart
├── Service Category 1
│   ├── Service A (Per-Piece)
│   │   ├── Item 1: Shirt × 3
│   │   └── Item 2: Pants × 2
│   └── Service B (Per-Kg)
│       └── Mixed Items: 5 kg
└── Service Category 2
    └── Service C (Per-Piece)
        └── Item 3: Bedsheet × 1
```

---

### 3. Delivery Partner

**Primary Responsibilities:**
- Self-register with vehicle and document details
- Accept/decline pickup and delivery requests
- Pick up orders from customers (with photo proof)
- Deliver orders to collection center
- Deliver completed orders to customers (with photo proof)
- Confirm payment on final delivery

**Access Level:** Own deliveries only

**Authentication:** 
- Email-based registration
- Admin verification required before activation

**Key Features:**
- Real-time pickup/drop requests
- Accept/decline functionality
- Weight machine indicator (for per-kg orders)
- GPS navigation
- Photo proof capture (mandatory)
- Payment confirmation on delivery
- Earnings tracking
- Delivery history

**Verification Process:**
1. Delivery partner creates account with email
2. Provides vehicle details (type, number)
3. Uploads documents (license, ID proof, vehicle registration)
4. Admin reviews and approves/rejects
5. Once verified, can accept delivery requests

---

### 4. Collection Manager

**Primary Responsibilities:**
- Monitor incoming orders (newly placed)
- Assign delivery partners for pickup (auto or manual)
- Receive orders at collection center
- Assign orders to service men
- Track order progress through collection stage

**Access Level:** All orders in collection workflow

**Authentication:** Email-based with OTP verification (created by admin)

**Key Features:**
- Three-stage order view:
  1. **Incoming Orders**: Newly placed, awaiting pickup assignment
  2. **Orders Received**: Picked up and delivered to collection center
  3. **Orders Submitted**: Assigned to service men
- Auto-assignment of delivery partners (2-minute window)
- Manual assignment fallback
- Mark orders as received
- Assign to service men (distributes items to service queues)

**Workflow:**
```
Customer Places Order
        ↓
[Incoming Orders]
- Auto-assign delivery partner (2 min)
- If no assignment → Manual assignment option
        ↓
Delivery Partner Picks Up
        ↓
[Orders Received]
- Collection Manager marks as received
- Assigns to service men
        ↓
[Orders Submitted]
- Items distributed to service queues (FIFO)
```

---

### 5. Service Man

**Primary Responsibilities:**
- Process items in assigned service queue (FIFO)
- Mark items as in-progress or completed
- Add comments on item status
- Maintain quality standards

**Access Level:** Own service queue only

**Authentication:** Email-based with OTP verification (created by admin)

**Key Constraint:** One service man per service (1:1 relationship)

**Key Features:**
- Service-specific item queue (FIFO ordering)
- View pending items grouped by order
- Mark items/sets as "in progress" or "completed"
- Add comments or notes
- Completion history tracking

**Service Assignment:**
```javascript
{
  "service_name": "Wash + Fold",
  "email": "washfold.serviceman@laundrymart.com"
}
```

**Queue View:**
```
Order #1234 (3 items)
- Shirt × 2 [Pending]
- Pants × 1 [Pending]

Order #1235 (5 items)
- Bedsheet × 1 [Pending]
- Pillow Cover × 4 [Pending]

Order #1236 (2 items)
- Towel × 2 [Pending]
```

---

### 6. Distribution Manager

**Primary Responsibilities:**
- Monitor completed services
- Track orders ready for dispatch
- Assign delivery partners for final delivery
- Manage dispatched orders

**Access Level:** All orders in distribution workflow

**Authentication:** Email-based with OTP verification (created by admin)

**Key Features:**
- Three-stage order view:
  1. **Services Completed**: Individual services marked complete (cross-order view)
  2. **Orders Completed**: Orders with all services finished, ready for dispatch
  3. **Orders Dispatched**: Orders sent out for delivery
- Assign delivery partners for final delivery
- Dispatch orders to customers
- Track delivery status

**Workflow:**
```
Service Men Complete Items
        ↓
[Services Completed]
- List of services completed (cross-order)
        ↓
When all services of an order complete
        ↓
[Orders Completed]
- Ready for dispatch to customer
- Assign delivery partner
- Dispatch order
        ↓
[Orders Dispatched]
- Track delivery status
- Monitor delivery completion
```

---

## Order Workflow

### Complete Order Lifecycle

```
1. [PLACED]
   Customer places order from cart
        ↓
2. [PICKUP_ASSIGNED]
   Collection Manager assigns delivery partner
   - Auto-assignment (2-min window)
   - Manual assignment fallback
        ↓
3. [PICKED_UP]
   Delivery partner picks up from customer
   - Photo proof mandatory
   - Weight measurement (if per-kg items)
        ↓
4. [RECEIVED_BY_COLLECTION]
   Collection Manager receives at collection center
   - Marks order as received
        ↓
5. [SUBMITTED_TO_SERVICES]
   Collection Manager assigns to service men
   - Items distributed to service queues (FIFO)
        ↓
6. [SERVICES_IN_PROGRESS]
   Service men working on items
   - Items marked as in-progress
        ↓
7. [SERVICES_COMPLETED]
   All items processed
   - All items marked as completed
        ↓
8. [DISPATCH_ASSIGNED]
   Distribution Manager assigns delivery partner
        ↓
9. [OUT_FOR_DELIVERY]
   Delivery partner on the way to customer
        ↓
10. [PAYMENT_PENDING]
    Delivered to customer, awaiting payment confirmation
        ↓
11. [DELIVERED]
    Payment confirmed by delivery partner
        ↓
12. [CLOSED]
    Order completed and closed
```

### Order Status Transitions

| Status | Triggered By | Action Required |
|--------|-------------|-----------------|
| placed | Customer | Place order from cart |
| pickup_assigned | Collection Manager / System | Assign delivery partner |
| picked_up | Delivery Partner | Pick up with photo proof |
| received_by_collection | Collection Manager | Mark as received |
| submitted_to_services | Collection Manager | Assign to service men |
| services_in_progress | Service Man | Start working on items |
| services_completed | Service Man | Complete all items |
| dispatch_assigned | Distribution Manager | Assign delivery partner |
| out_for_delivery | Delivery Partner | En route to customer |
| payment_pending | Delivery Partner | Deliver order |
| delivered | Delivery Partner | Confirm payment |
| closed | System | Auto-close after delivery |

---

## Cart System

### Cart Structure

**Database Schema:**

```prisma
Cart
├── cart_id
├── customer_id
├── mart_id
└── CartItem[]
    ├── cart_item_id
    ├── service_id
    ├── pricing_type (per_unit / per_kg)
    ├── weight_kg (if per_kg)
    └── CartItemSelection[] (if per_unit)
        ├── cloth_id
        └── quantity
```

### Cart Workflow

1. **Browse Services**
   - Customer views service categories
   - Selects service (e.g., "Wash + Fold")

2. **Choose Pricing Type**
   - Per-Piece: Select individual items with quantities
   - Per-Kg: Enter total weight

3. **Add to Cart**
   - Cart item created with selections
   - Can add multiple services to same cart

4. **Checkout**
   - Select pickup address
   - Select delivery address
   - Choose delivery type (pickup only, drop only, both, express)
   - Schedule pickup and delivery dates
   - Review total amount
   - Confirm order

### Cart API Endpoints

```
POST   /api/v1/cart/add-item
GET    /api/v1/cart
PUT    /api/v1/cart/update-item/:cartItemId
DELETE /api/v1/cart/remove-item/:cartItemId
POST   /api/v1/cart/checkout
DELETE /api/v1/cart/clear
```

---

## Service Queue Management

### FIFO (First In, First Out) Processing

**Concept:**
- When order is submitted to services, items are distributed to service-specific queues
- Each service has its own queue managed by assigned service man
- Items processed in order they were received (FIFO)

**Database Schema:**

```prisma
ServiceQueueItem
├── queue_id
├── order_id
├── service_id
├── service_man_id
├── item_id (reference to OrderItem)
├── item_name
├── quantity
├── queue_status (pending / in_progress / completed)
├── priority (for FIFO ordering, auto-incremented)
├── assigned_at
├── started_at
├── completed_at
└── comments
```

### Queue Processing Workflow

1. **Order Submitted**
   - Collection Manager submits order
   - System identifies services in order
   - Creates queue items for each service

2. **Queue Assignment**
   ```javascript
   // Example: Order with 3 services
   Order #1234
   ├── Wash + Fold (3 items) → Wash+Fold Service Queue
   ├── Dry Clean (2 items) → Dry Clean Service Queue
   └── Shoe Cleaning (1 item) → Shoe Cleaning Service Queue
   ```

3. **Service Man View**
   - Service man logs in
   - Sees items in queue ordered by priority (FIFO)
   - Processes items order by order

4. **Item Processing**
   - Service man marks item as "in progress"
   - Completes work
   - Marks item as "completed"
   - Moves to next item in queue

### Queue API Endpoints

```
GET    /api/v1/service-queue/pending
POST   /api/v1/service-queue/start/:queueItemId
POST   /api/v1/service-queue/complete/:queueItemId
GET    /api/v1/service-queue/completed
POST   /api/v1/service-queue/add-comment/:queueItemId
```

---

## Database Schema Changes

### Important: Single Laundry System

The database schema is designed for a **single laundry business**. There is no `mart_id` foreign key in most tables since there's only one laundry entity.

### New Tables

1. **LaundryConfig** (replaces LaundryMart)
   - config_id (PK)
   - business_name
   - contact_email (unique)
   - contact_phone
   - address, latitude, longitude
   - service_radius_km (JSON)
   - is_active
   - logo_url
   - created_at, updated_at
   - **Note:** Single configuration record for the business

2. **CollectionManager**
   - manager_id (PK)
   - full_name
   - email (unique)
   - phone
   - is_active
   - created_at, updated_at
   - **Note:** No mart_id - single business

3. **ServiceMan**
   - service_man_id (PK)
   - service_id (FK, unique) - One service man per service
   - full_name
   - email (unique)
   - phone
   - is_active
   - created_at, updated_at

4. **DistributionManager**
   - manager_id (PK)
   - full_name
   - email (unique)
   - phone
   - is_active
   - created_at, updated_at
   - **Note:** No mart_id - single business

5. **Cart**
   - cart_id (PK)
   - customer_id (FK)
   - is_active
   - created_at, updated_at
   - **Note:** No mart_id - single business

6. **CartItem**
   - cart_item_id (PK)
   - cart_id (FK)
   - service_id (FK)
   - pricing_type (enum: per_unit, per_kg)
   - weight_kg (nullable)
   - created_at, updated_at

7. **CartItemSelection**
   - selection_id (PK)
   - cart_item_id (FK)
   - cloth_id (FK)
   - quantity
   - created_at

8. **ServiceQueueItem**
   - queue_id (PK)
   - order_id (FK)
   - service_id (FK)
   - service_man_id (FK)
   - item_id (reference to OrderItem)
   - item_name
   - quantity
   - queue_status (enum: pending, in_progress, completed)
   - priority (for FIFO)
   - assigned_at
   - started_at, completed_at
   - comments
   - created_at, updated_at

### Modified Tables

1. **Customer** (Simplified)
   - **Removed:** CustomerMartProfile (not needed for single laundry)
   - Added: total_orders (direct on customer)
   - Added: total_spent (direct on customer)
   - Relationship: One-to-many with Cart

2. **User** (Admin - Simplified)
   - **Removed:** mart_id (FK) - single business, no need for FK
   - role is now enum (admin, owner)

3. **DeliveryStaff** (Updated)
   - **Removed:** mart_id (FK) - single business
   - Added: id_proof_type
   - Added: id_proof_url
   - Added: is_verified_by_admin (boolean)
   - Modified: verification_status (enum: pending, verified, rejected)

4. **Service** (Updated)
   - **Removed:** mart_id (FK) - single business
   - Relationship: One-to-one with ServiceMan

5. **Order** (Enhanced Tracking)
   - **Removed:** mart_id (FK) - single business
   - Added: received_by_collection_manager_id (FK)
   - Added: received_at
   - Added: submitted_to_services_at
   - Added: dispatched_by_distribution_manager_id (FK)
   - Added: dispatched_at
   - Added: payment_confirmed_at

6. **OrderItem** (Status Tracking)
   - Added: item_status (enum: pending, in_progress, completed)
   - Added: assigned_at
   - Added: completed_at

7. **Delivery** (Enhanced)
   - Added: needs_weight_machine (boolean)
   - Added: delivery_type (enum: pickup, drop)

8. **DailyMetrics** (Renamed from MartDailyMetrics)
   - **Removed:** mart_id (FK) - single business
   - Renamed table to reflect single business metrics

9. **OtpSession** (Updated)
   - Changed: mart_email → business_email
   - Changed: mart_email_verified → business_email_verified

### New Enums

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

---

## API Endpoints

### Admin Endpoints

```
POST   /api/v1/admin/collection-manager
POST   /api/v1/admin/service-man
POST   /api/v1/admin/distribution-manager
GET    /api/v1/admin/delivery-partners/pending-verification
POST   /api/v1/admin/delivery-partners/:staffId/verify
POST   /api/v1/admin/delivery-partners/:staffId/reject
GET    /api/v1/admin/analytics
GET    /api/v1/admin/staff
```

### Customer Endpoints

```
POST   /api/v1/cart/add-item
GET    /api/v1/cart
PUT    /api/v1/cart/update-item/:cartItemId
DELETE /api/v1/cart/remove-item/:cartItemId
POST   /api/v1/cart/checkout
GET    /api/v1/orders
GET    /api/v1/orders/:orderId
GET    /api/v1/orders/:orderId/track
POST   /api/v1/orders/:orderId/rate
```

### Delivery Partner Endpoints

```
POST   /api/v1/delivery/register
GET    /api/v1/delivery/requests
POST   /api/v1/delivery/requests/:deliveryId/accept
POST   /api/v1/delivery/requests/:deliveryId/decline
POST   /api/v1/delivery/:deliveryId/pickup-complete
POST   /api/v1/delivery/:deliveryId/delivery-complete
POST   /api/v1/delivery/:deliveryId/confirm-payment
GET    /api/v1/delivery/history
```

### Collection Manager Endpoints

```
GET    /api/v1/collection/incoming-orders
GET    /api/v1/collection/orders-received
GET    /api/v1/collection/orders-submitted
POST   /api/v1/collection/orders/:orderId/assign-pickup
POST   /api/v1/collection/orders/:orderId/mark-received
POST   /api/v1/collection/orders/:orderId/submit-to-services
```

### Service Man Endpoints

```
GET    /api/v1/service-queue/pending
GET    /api/v1/service-queue/in-progress
GET    /api/v1/service-queue/completed
POST   /api/v1/service-queue/:queueItemId/start
POST   /api/v1/service-queue/:queueItemId/complete
POST   /api/v1/service-queue/:queueItemId/comment
```

### Distribution Manager Endpoints

```
GET    /api/v1/distribution/services-completed
GET    /api/v1/distribution/orders-completed
GET    /api/v1/distribution/orders-dispatched
POST   /api/v1/distribution/orders/:orderId/assign-delivery
POST   /api/v1/distribution/orders/:orderId/dispatch
```

---

## Frontend Requirements

### Customer App (Flutter)

**New Screens:**
1. **Cart Screen**
   - List of cart items grouped by service
   - Quantity adjustment
   - Remove items
   - Proceed to checkout

2. **Service Selection Screen**
   - Choose pricing type (per-piece or per-kg)
   - Select items for per-piece
   - Enter weight for per-kg

3. **Enhanced Order Tracking**
   - 12-stage progress indicator
   - Current stage highlight
   - Estimated time for each stage
   - Real-time updates

**Modified Screens:**
- Service catalog with add-to-cart buttons
- Order history with new status labels

### Delivery Partner App (Flutter)

**New Features:**
1. **Registration Flow**
   - Vehicle details entry
   - Document upload (license, ID, vehicle registration)
   - Pending verification screen

2. **Verification Status**
   - Pending/Verified/Rejected indicator
   - Re-upload documents if rejected

3. **Weight Machine Indicator**
   - Show icon if order requires weight machine
   - Alert before accepting delivery

4. **Payment Confirmation**
   - Payment status check
   - Confirm payment received
   - Cannot close delivery without payment confirmation

### Collection Manager Web Panel

**New Screens:**
1. **Incoming Orders Dashboard**
   - List of newly placed orders
   - Auto-assignment status (timer countdown)
   - Manual assignment button
   - Filter by date, status

2. **Orders Received Dashboard**
   - List of picked-up orders
   - Mark as received button
   - Assign to service men button

3. **Orders Submitted Dashboard**
   - List of orders in service queues
   - Track progress by service
   - View service completion status

### Service Man Web/Mobile Interface

**New Screens:**
1. **Service Queue Dashboard**
   - FIFO list of pending items
   - Group by order
   - Priority/order number display

2. **Item Processing Screen**
   - Start work button
   - Complete button
   - Add comments/notes
   - View item details

3. **Completion History**
   - List of completed items
   - Performance metrics

### Distribution Manager Web Panel

**New Screens:**
1. **Services Completed Dashboard**
   - Cross-order view of completed services
   - Filter by service type
   - View order details

2. **Orders Completed Dashboard**
   - List of orders ready for dispatch
   - Assign delivery partner
   - Dispatch button

3. **Orders Dispatched Dashboard**
   - Track dispatched orders
   - Delivery partner location
   - Delivery status updates

### Admin Panel (React)

**New Features:**
1. **Staff Management**
   - Create collection managers
   - Create service men (with service assignment)
   - Create distribution managers
   - View all staff

2. **Delivery Partner Verification**
   - List of pending verifications
   - View documents
   - Approve/reject with reason

3. **Service Man Assignment**
   - Assign service man to service
   - One service man per service validation
   - Reassignment capability

4. **Enhanced Analytics**
   - Service man performance
   - Collection/distribution efficiency
   - Queue processing times
   - Delivery partner ratings

---

## Migration Steps

1. **Database Migration**
   ```bash
   npx prisma migrate dev --name add_new_user_roles_and_cart
   ```

2. **Seed Data**
   - Create sample staff accounts
   - Assign service men to services

3. **Update Services**
   - Implement cart management service
   - Implement service queue service
   - Update order service for new workflow

4. **Update Controllers**
   - Implement new role-specific controllers
   - Update order controller for new statuses

5. **Frontend Updates**
   - Implement cart UI
   - Update order tracking UI
   - Create role-specific dashboards

6. **Testing**
   - Test complete order workflow
   - Test cart operations
   - Test service queue FIFO
   - Test delivery partner verification

---

## Summary

The new architecture introduces:

- ✅ **6 User Roles**: Admin, Customer, Delivery Partner, Collection Manager, Service Man, Distribution Manager
- ✅ **Cart System**: Multi-service cart with dual pricing
- ✅ **Service Queue**: FIFO processing by dedicated service men
- ✅ **Enhanced Workflow**: 12-stage order lifecycle with clear handoffs
- ✅ **Verification**: Admin approval required for delivery partners
- ✅ **Payment Confirmation**: Mandatory on delivery
- ✅ **Photo Proofs**: Mandatory for pickups and deliveries
- ✅ **Accountability**: Tracking at every stage with timestamps and user IDs

This architecture provides complete traceability, efficient workflow management, and clear role separation for optimal laundry operations.

---

**Next Steps:**
1. Review and approve schema changes
2. Run database migrations
3. Implement backend services
4. Update frontend applications
5. Test complete workflow
6. Deploy to staging environment

