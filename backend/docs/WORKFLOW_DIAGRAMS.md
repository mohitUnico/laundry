# Laundry App - Workflow Diagrams

**Version**: 2.0  
**Last Updated**: December 19, 2025

---

## Table of Contents

1. [Order Lifecycle Flow](#order-lifecycle-flow)
2. [Customer Journey](#customer-journey)
3. [Collection Manager Workflow](#collection-manager-workflow)
4. [Service Man Workflow](#service-man-workflow)
5. [Distribution Manager Workflow](#distribution-manager-workflow)
6. [Delivery Partner Workflow](#delivery-partner-workflow)
7. [Cart to Order Flow](#cart-to-order-flow)
8. [Service Queue Flow](#service-queue-flow)

---

## Order Lifecycle Flow

### Complete 12-Stage Order Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ORDER LIFECYCLE                                   │
└─────────────────────────────────────────────────────────────────────────┘

    CUSTOMER                  COLLECTION MANAGER         SERVICE MAN         DISTRIBUTION MANAGER        DELIVERY PARTNER
       │                              │                      │                        │                          │
       │   1. Place Order             │                      │                        │                          │
       │   (from Cart)                │                      │                        │                          │
       ├─────────────►                │                      │                        │                          │
       │                              │                      │                        │                          │
       │                   2. Assign Pickup                  │                        │                          │
       │                   (Auto/Manual)                     │                        │                          │
       │                              ├──────────────────────┼────────────────────────┼─────────►                │
       │                              │                      │                        │            3. Pickup     │
       │   ◄──────────────────────────┼──────────────────────┼────────────────────────┼───────────┤             │
       │   (Photo Proof)              │                      │                        │                          │
       │                              │                      │                        │                          │
       │                   4. Mark Received                  │                        │                          │
       │                              │                      │                        │                          │
       │                   5. Submit to Services             │                        │                          │
       │                              ├─────────────────────►│                        │                          │
       │                              │                      │                        │                          │
       │                              │           6. Process Items                    │                          │
       │                              │           (FIFO Queue)                        │                          │
       │                              │                      │                        │                          │
       │                              │           7. Complete Items                   │                          │
       │                              │                      ├───────────────────────►│                          │
       │                              │                      │                        │                          │
       │                              │                      │             8. Assign Delivery                   │
       │                              │                      │                        ├─────────────────────────►│
       │                              │                      │                        │                          │
       │                              │                      │                        │            9. Deliver    │
       │   ◄──────────────────────────┼──────────────────────┼────────────────────────┼───────────┤             │
       │   (Photo Proof)              │                      │                        │                          │
       │                              │                      │                        │                          │
       │   10. Confirm Payment        │                      │                        │                          │
       ├──────────────────────────────┼──────────────────────┼────────────────────────┼─────────►                │
       │                              │                      │                        │                          │
       │   11. Order Delivered & Closed                      │                        │                          │
       │                              │                      │                        │                          │
```

### Status Progression

```
┌──────────────┐     ┌─────────────────┐     ┌────────────┐     ┌─────────────────────┐
│   PLACED     │────►│ PICKUP_ASSIGNED │────►│ PICKED_UP  │────►│ RECEIVED_BY_        │
│              │     │                 │     │            │     │ COLLECTION          │
└──────────────┘     └─────────────────┘     └────────────┘     └─────────────────────┘
                                                                          │
                                                                          ▼
┌──────────────┐     ┌─────────────────┐     ┌─────────────────────────────┐
│   CLOSED     │◄────│    DELIVERED    │◄────│     PAYMENT_PENDING         │
│              │     │                 │     │                             │
└──────────────┘     └─────────────────┘     └─────────────────────────────┘
       ▲                      ▲                            ▲
       │                      │                            │
       │                      └────────────┐               │
       │                                   │               │
┌──────────────────┐     ┌─────────────────┐     ┌────────────────────┐
│ OUT_FOR_DELIVERY │◄────│ DISPATCH_       │◄────│ SERVICES_          │
│                  │     │ ASSIGNED        │     │ COMPLETED          │
└──────────────────┘     └─────────────────┘     └────────────────────┘
                                                          ▲
                                                          │
                         ┌─────────────────────────────────┤
                         │                                 │
                ┌────────────────────┐     ┌──────────────────────┐
                │ SERVICES_IN_       │◄────│ SUBMITTED_TO_        │
                │ PROGRESS           │     │ SERVICES             │
                └────────────────────┘     └──────────────────────┘
```

---

## Customer Journey

### Cart to Order Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                         CUSTOMER JOURNEY                                │
└────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   Browse    │
    │  Services   │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │   Select    │
    │  Service    │
    └──────┬──────┘
           │
           ▼
    ┌─────────────────────┐
    │ Choose Pricing Type │
    │  - Per Piece        │
    │  - Per Kg           │
    └──────┬──────────────┘
           │
           ├────────────────┬─────────────────┐
           │                │                 │
           ▼                ▼                 ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │ Select Items │ │ Enter Weight │ │              │
    │ & Quantities │ │   (Per Kg)   │ │              │
    └──────┬───────┘ └──────┬───────┘ └──────────────┘
           │                │
           └────────┬───────┘
                    │
                    ▼
    ┌─────────────────────────────┐
    │      Add to Cart            │
    │  (Can add multiple services)│
    └──────────┬──────────────────┘
               │
               ▼
    ┌─────────────────┐
    │  View Cart      │
    │  - Edit items   │
    │  - Remove items │
    │  - See total    │
    └──────┬──────────┘
           │
           ▼
    ┌─────────────────┐
    │   Checkout      │
    └──────┬──────────┘
           │
           ▼
    ┌─────────────────────────────┐
    │  Select Addresses           │
    │  - Pickup Address           │
    │  - Delivery Address         │
    └──────┬──────────────────────┘
           │
           ▼
    ┌─────────────────────────────┐
    │  Schedule Dates             │
    │  - Pickup Date & Time       │
    │  - Delivery Date & Time     │
    └──────┬──────────────────────┘
           │
           ▼
    ┌─────────────────────────────┐
    │  Review & Confirm Order     │
    │  - Total Amount             │
    │  - Service Details          │
    │  - Addresses                │
    └──────┬──────────────────────┘
           │
           ▼
    ┌─────────────────────────────┐
    │    Order Placed             │
    │  (Status: PLACED)           │
    └─────────────────────────────┘
```

---

## Collection Manager Workflow

### Three-Stage Dashboard

```
┌────────────────────────────────────────────────────────────────────────┐
│                    COLLECTION MANAGER WORKFLOW                          │
└────────────────────────────────────────────────────────────────────────┘

╔══════════════════════════════════════════════════════════════════════╗
║                        INCOMING ORDERS                                ║
║  (Status: PLACED)                                                     ║
╚══════════════════════════════════════════════════════════════════════╝
    │
    │   Order #1234 - Customer: John Doe
    │   Items: 5 items | Pickup: 123 Main St | Date: Tomorrow 10 AM
    │
    │   ┌─────────────────────────────────────────┐
    │   │ Auto-Assignment (2 min countdown)       │
    │   │ ⏰ 01:45 remaining                      │
    │   │                                         │
    │   │ OR                                      │
    │   │                                         │
    │   │ [Assign Manually] ▼ Select Partner     │
    │   └─────────────────────────────────────────┘
    │
    ▼
╔══════════════════════════════════════════════════════════════════════╗
║                        ORDERS RECEIVED                                ║
║  (Status: PICKED_UP → RECEIVED_BY_COLLECTION)                        ║
╚══════════════════════════════════════════════════════════════════════╝
    │
    │   Order #1234 - Picked up by: Mike (Delivery Partner)
    │   Arrived at: 10:30 AM
    │
    │   ┌─────────────────────────────────────────┐
    │   │ [Mark as Received]                      │
    │   │                                         │
    │   │ After receiving:                        │
    │   │ [Assign to Service Men]                 │
    │   └─────────────────────────────────────────┘
    │
    ▼
╔══════════════════════════════════════════════════════════════════════╗
║                       ORDERS SUBMITTED                                ║
║  (Status: SUBMITTED_TO_SERVICES)                                     ║
╚══════════════════════════════════════════════════════════════════════╝
    │
    │   Order #1234 - Submitted at: 10:35 AM
    │   Services:
    │     - Wash + Fold (3 items) → In Queue
    │     - Dry Clean (2 items) → In Queue
    │
    │   Track progress by service
    │
    ▼
    (Moves to Service Men queues)
```

### Auto-Assignment Logic

```
┌─────────────────────────────────────────────────────────────────────┐
│                   AUTO-ASSIGNMENT ALGORITHM                          │
└─────────────────────────────────────────────────────────────────────┘

    Order Placed (Status: PLACED)
           │
           ▼
    ┌─────────────────┐
    │ Start 2-minute  │
    │    Timer        │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────────────────┐
    │ Search Nearby Delivery      │
    │ Partners (by distance)      │
    └────────┬────────────────────┘
             │
             ├─────────Yes────────► ┌──────────────────┐
             │ Partner Found?      │ Assign Partner   │
             │                     │ (Status: PICKUP_ │
             │                     │  ASSIGNED)       │
             │                     └──────────────────┘
             │
             └─────────No─────────► ┌──────────────────┐
               2 min elapsed?       │ Collection       │
                                   │ Manager can      │
                                   │ Manually Assign  │
                                   └──────────────────┘
```

---

## Service Man Workflow

### FIFO Queue Processing

```
┌────────────────────────────────────────────────────────────────────────┐
│                       SERVICE MAN WORKFLOW                              │
│                      (Example: Wash + Fold)                            │
└────────────────────────────────────────────────────────────────────────┘

╔══════════════════════════════════════════════════════════════════════╗
║                         PENDING ITEMS (FIFO)                          ║
╚══════════════════════════════════════════════════════════════════════╝

    Priority 1 (First)
    ┌──────────────────────────────────────────┐
    │ Order #1234                              │
    │ Customer: John Doe                       │
    │ Items: Shirt (2), Pants (1)             │
    │ Status: Pending                          │
    │                                          │
    │ [Start Work]                             │
    └──────────────────────────────────────────┘

    Priority 2
    ┌──────────────────────────────────────────┐
    │ Order #1235                              │
    │ Customer: Jane Smith                     │
    │ Items: Bedsheet (1), Pillow Cover (4)   │
    │ Status: Pending                          │
    │                                          │
    │ [Start Work]                             │
    └──────────────────────────────────────────┘

    Priority 3
    ┌──────────────────────────────────────────┐
    │ Order #1236                              │
    │ Customer: Bob Johnson                    │
    │ Items: Towel (2)                         │
    │ Status: Pending                          │
    │                                          │
    │ [Start Work]                             │
    └──────────────────────────────────────────┘

           │
           │ Service Man clicks [Start Work] on Priority 1
           ▼

╔══════════════════════════════════════════════════════════════════════╗
║                       IN PROGRESS                                     ║
╚══════════════════════════════════════════════════════════════════════╝

    ┌──────────────────────────────────────────┐
    │ Order #1234                              │
    │ Started at: 11:00 AM                     │
    │                                          │
    │ Items:                                   │
    │  □ Shirt × 2                             │
    │  □ Pants × 1                             │
    │                                          │
    │ [Add Comment]                            │
    │ [Mark Complete]                          │
    └──────────────────────────────────────────┘

           │
           │ Service Man clicks [Mark Complete]
           ▼

╔══════════════════════════════════════════════════════════════════════╗
║                         COMPLETED                                     ║
╚══════════════════════════════════════════════════════════════════════╝

    ┌──────────────────────────────────────────┐
    │ Order #1234                              │
    │ Completed at: 11:30 AM                   │
    │ Duration: 30 minutes                     │
    │                                          │
    │ ✓ All items completed                    │
    └──────────────────────────────────────────┘

           │
           │ Automatically moves to Distribution Manager
           ▼
```

---

## Distribution Manager Workflow

### Three-Stage Dashboard

```
┌────────────────────────────────────────────────────────────────────────┐
│                   DISTRIBUTION MANAGER WORKFLOW                         │
└────────────────────────────────────────────────────────────────────────┘

╔══════════════════════════════════════════════════════════════════════╗
║                     SERVICES COMPLETED                                ║
║  (Cross-order view of completed services)                            ║
╚══════════════════════════════════════════════════════════════════════╝
    │
    │   Service: Wash + Fold
    │     - Order #1234 (John Doe) - Completed: 11:30 AM
    │     - Order #1237 (Alice) - Completed: 12:00 PM
    │
    │   Service: Dry Clean
    │     - Order #1234 (John Doe) - Completed: 12:15 PM
    │
    ▼
╔══════════════════════════════════════════════════════════════════════╗
║                      ORDERS COMPLETED                                 ║
║  (All services of order finished - Ready for dispatch)               ║
╚══════════════════════════════════════════════════════════════════════╝
    │
    │   Order #1234 - Customer: John Doe
    │   All Services Completed: 12:15 PM
    │   Services: Wash + Fold ✓, Dry Clean ✓
    │
    │   ┌─────────────────────────────────────────┐
    │   │ [Assign Delivery Partner] ▼             │
    │   │                                         │
    │   │ [Dispatch to Customer]                  │
    │   └─────────────────────────────────────────┘
    │
    ▼
╔══════════════════════════════════════════════════════════════════════╗
║                      ORDERS DISPATCHED                                ║
║  (Status: OUT_FOR_DELIVERY)                                          ║
╚══════════════════════════════════════════════════════════════════════╝
    │
    │   Order #1234 - Customer: John Doe
    │   Dispatched at: 12:30 PM
    │   Delivery Partner: Mike
    │   Expected Delivery: 2:00 PM
    │
    │   Track delivery status 🚚
    │
    ▼
    (Delivery in progress)
```

---

## Delivery Partner Workflow

### Registration and Verification

```
┌────────────────────────────────────────────────────────────────────────┐
│                    DELIVERY PARTNER REGISTRATION                        │
└────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   Sign Up   │
    │  with Email │
    └──────┬──────┘
           │
           ▼
    ┌─────────────────┐
    │  Enter Details  │
    │  - Full Name    │
    │  - Phone        │
    │  - Vehicle Info │
    └──────┬──────────┘
           │
           ▼
    ┌─────────────────┐
    │ Upload Docs     │
    │ - License       │
    │ - ID Proof      │
    │ - Vehicle Reg   │
    └──────┬──────────┘
           │
           ▼
    ┌──────────────────────┐
    │ Status: PENDING      │
    │ Awaiting Admin       │
    │ Verification         │
    └──────┬───────────────┘
           │
           ▼
    ┌──────────────────────┐
    │ Admin Reviews        │
    │ Documents            │
    └──────┬───────────────┘
           │
           ├────────Approved────────► ┌────────────────┐
           │                          │ Status:        │
           │                          │ VERIFIED       │
           │                          │ Can Accept     │
           │                          │ Deliveries     │
           │                          └────────────────┘
           │
           └────────Rejected────────► ┌────────────────┐
                                     │ Status:        │
                                     │ REJECTED       │
                                     │ Re-upload Docs │
                                     └────────────────┘
```

### Pickup and Delivery Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                    DELIVERY PARTNER - PICKUP FLOW                       │
└────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────┐
    │ Receive Pickup       │
    │ Request              │
    │                      │
    │ Order #1234          │
    │ 📍 123 Main St       │
    │ Distance: 2.3 km     │
    │ ⚖️  Weight Machine: YES│
    └──────┬───────────────┘
           │
           ├───[Accept]─────► ┌────────────────┐
           │                  │ Navigate to    │
           │                  │ Customer       │
           │                  └────────┬───────┘
           │                           │
           ▼                           ▼
    ┌──────────────┐         ┌────────────────┐
    │   Decline    │         │ Reach Customer │
    │   (Available │         │ - Update GPS   │
    │    for       │         │ - Notify       │
    │    others)   │         └────────┬───────┘
    └──────────────┘                  │
                                     ▼
                            ┌────────────────┐
                            │ Collect Items  │
                            │ - Verify items │
                            │ - Weigh (if ⚖️) │
                            └────────┬───────┘
                                     │
                                     ▼
                            ┌────────────────┐
                            │ Take Photo     │
                            │ Proof          │
                            │ (Mandatory)    │
                            └────────┬───────┘
                                     │
                                     ▼
                            ┌────────────────┐
                            │ Mark Pickup    │
                            │ Complete       │
                            └────────┬───────┘
                                     │
                                     ▼
                            ┌────────────────┐
                            │ Navigate to    │
                            │ Collection     │
                            │ Center         │
                            └────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                   DELIVERY PARTNER - DELIVERY FLOW                      │
└────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────┐
    │ Receive Delivery     │
    │ Request              │
    │                      │
    │ Order #1234          │
    │ 📍 123 Main St       │
    │ Distance: 2.3 km     │
    └──────┬───────────────┘
           │
           ├───[Accept]─────► ┌────────────────┐
           │                  │ Pick up from   │
           │                  │ Distribution   │
           │                  │ Center         │
           │                  └────────┬───────┘
           │                           │
           ▼                           ▼
    ┌──────────────┐         ┌────────────────┐
    │   Decline    │         │ Navigate to    │
    └──────────────┘         │ Customer       │
                             └────────┬───────┘
                                      │
                                      ▼
                             ┌────────────────┐
                             │ Deliver Items  │
                             └────────┬───────┘
                                      │
                                      ▼
                             ┌────────────────┐
                             │ Take Photo     │
                             │ Proof          │
                             │ (Mandatory)    │
                             └────────┬───────┘
                                      │
                                      ▼
                             ┌────────────────────┐
                             │ Check Payment      │
                             │ Status             │
                             └────────┬───────────┘
                                      │
                      ┌───────────────┼───────────────┐
                      │               │               │
                  Paid          Not Paid         
                      │               │               
                      ▼               ▼               
            ┌────────────────┐ ┌──────────────────┐
            │ Mark Delivered │ │ Collect Payment  │
            │ & Closed       │ │ - Cash/Card/UPI  │
            └────────────────┘ │ - Confirm        │
                               │ - Mark Delivered │
                               └──────────────────┘
```

---

## Cart to Order Flow

### Detailed Cart Checkout Process

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CART TO ORDER FLOW                               │
└────────────────────────────────────────────────────────────────────────┘

    CART
    ┌──────────────────────────────────────────┐
    │ Service Category: Regular Wash           │
    │   ├─ Wash + Fold (Per Piece)            │
    │   │   ├─ Shirt × 3 @ ₹40 = ₹120         │
    │   │   └─ Pants × 2 @ ₹50 = ₹100         │
    │   │                                      │
    │   └─ Dry Clean (Per Kg)                 │
    │       └─ 5 kg @ ₹100/kg = ₹500          │
    │                                          │
    │ Service Category: Home Linens            │
    │   └─ Bedsheet (Per Piece)               │
    │       └─ Bedsheet × 1 @ ₹80 = ₹80       │
    │                                          │
    │ Subtotal: ₹800                           │
    └──────────────────────────────────────────┘
           │
           │ Customer clicks [Checkout]
           ▼
    ┌──────────────────────────────────────────┐
    │ SELECT ADDRESSES                         │
    │                                          │
    │ Pickup Address:                          │
    │ ▼ Home - 123 Main St                     │
    │                                          │
    │ Delivery Address:                        │
    │ ▼ Home - 123 Main St                     │
    │   (or different)                         │
    └──────────────────────────────────────────┘
           │
           ▼
    ┌──────────────────────────────────────────┐
    │ SCHEDULE DATES                           │
    │                                          │
    │ Pickup:                                  │
    │ 📅 Tomorrow | ⏰ 10:00 AM                 │
    │                                          │
    │ Delivery:                                │
    │ 📅 2 days later | ⏰ 2:00 PM              │
    └──────────────────────────────────────────┘
           │
           ▼
    ┌──────────────────────────────────────────┐
    │ REVIEW & CONFIRM                         │
    │                                          │
    │ Subtotal: ₹800                           │
    │ Delivery Fee: ₹50                        │
    │ Tax (5%): ₹42.50                         │
    │ ────────────────                         │
    │ Total: ₹892.50                           │
    │                                          │
    │ [Confirm Order]                          │
    └──────────────────────────────────────────┘
           │
           │ Backend Process:
           │ 1. Create Order
           │ 2. Create OrderItems from CartItems
           │ 3. Create Bill
           │ 4. Clear Cart
           │ 5. Notify Collection Manager
           ▼
    ┌──────────────────────────────────────────┐
    │ ORDER PLACED                             │
    │                                          │
    │ Order #1234                              │
    │ Status: PLACED                           │
    │                                          │
    │ Track your order →                       │
    └──────────────────────────────────────────┘
```

---

## Service Queue Flow

### Distribution to Service Queues

```
┌────────────────────────────────────────────────────────────────────────┐
│                   SERVICE QUEUE DISTRIBUTION                            │
└────────────────────────────────────────────────────────────────────────┘

    ORDER #1234 (Submitted to Services)
    ┌──────────────────────────────────────────┐
    │ Items:                                   │
    │  - Wash + Fold: Shirt (3), Pants (2)    │
    │  - Dry Clean: 5 kg                       │
    │  - Bedsheet: 1                           │
    └──────────────────────┬───────────────────┘
                           │
                           │ System distributes to service-specific queues
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐   ┌──────────┐
    │ Wash +   │    │   Dry    │   │ Bedsheet │
    │  Fold    │    │  Clean   │   │ Service  │
    │  Queue   │    │  Queue   │   │  Queue   │
    └────┬─────┘    └────┬─────┘   └────┬─────┘
         │               │              │
         │               │              │
         ▼               ▼              ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │ Priority 1  │ │ Priority 1  │ │ Priority 1  │
    │ Order #1234 │ │ Order #1234 │ │ Order #1234 │
    │ Shirt (3)   │ │ 5 kg        │ │ Bedsheet(1) │
    │ Pants (2)   │ │             │ │             │
    └─────────────┘ └─────────────┘ └─────────────┘
         │               │              │
         │               │              │
         ▼               ▼              ▼
    Service Man A   Service Man B   Service Man C
    processes       processes       processes
    in order        in order        in order
    (FIFO)          (FIFO)          (FIFO)
```

### FIFO Processing Example

```
Wash + Fold Queue (Service Man A)

Time: 10:00 AM
┌──────────────────────────────────────────┐
│ Priority 1 (First In)                    │
│ Order #1200 - Shirt (2)                  │
│ Status: In Progress                      │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ Priority 2                               │
│ Order #1210 - Pants (3), Shirt (1)       │
│ Status: Pending                          │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ Priority 3                               │
│ Order #1234 - Shirt (3), Pants (2)       │
│ Status: Pending                          │
└──────────────────────────────────────────┘

Time: 10:30 AM (Order #1200 completed)
┌──────────────────────────────────────────┐
│ Priority 1 (Now processing)              │
│ Order #1210 - Pants (3), Shirt (1)       │
│ Status: In Progress                      │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ Priority 2 (Waiting)                     │
│ Order #1234 - Shirt (3), Pants (2)       │
│ Status: Pending                          │
└──────────────────────────────────────────┘

Time: 11:00 AM (Order #1210 completed)
┌──────────────────────────────────────────┐
│ Priority 1 (Now processing)              │
│ Order #1234 - Shirt (3), Pants (2)       │
│ Status: In Progress                      │
└──────────────────────────────────────────┘
```

---

## Summary

This document provides visual representations of all key workflows in the Laundry App Architecture v2.0:

- ✅ **12-stage order lifecycle** with role handoffs
- ✅ **Cart to order** conversion process
- ✅ **FIFO service queues** for efficient processing
- ✅ **Role-specific workflows** for all 6 user types
- ✅ **Auto-assignment logic** with manual fallback
- ✅ **Verification process** for delivery partners
- ✅ **Payment confirmation** on delivery

These diagrams should be used alongside the [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md) for complete system understanding.

---

**Related Documentation:**
- [NEW_ARCHITECTURE_OVERVIEW.md](NEW_ARCHITECTURE_OVERVIEW.md) - Complete architecture details
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration instructions
- [API Documentation] - API endpoint references

