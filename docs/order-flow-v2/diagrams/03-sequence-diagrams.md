# Sequence diagrams

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 4. UML sequence diagrams (messages and side effects)

### 4.1 Place order and pickup assignment

```mermaid
sequenceDiagram
autonumber
actor C as Customer
participant CA as Customer app
participant API as Backend API
participant DB as PostgreSQL
participant W as BullMQ worker
participant GM as Google Maps
participant PA as Pickup boy app
actor CM as Collection manager
C->>CA: confirm cart plus modes or Express
CA->>API: POST order services pricing_type modes is_express
API->>DB: insert Order placed no Bill
API-->>CA: order placed
alt instant or Express
  API->>W: start pickup search now
else scheduled
  API->>W: schedule at pickup_time_from
end
loop slice 1 to 5 over ASSIGNMENT_TIMEOUT
  W->>DB: load on-shift staff and last location
  W->>GM: road distance to pickup
  W->>PA: SSE offer to staff in ring not yet pinged
  opt a staff accepts
    PA->>API: accept offer
    API->>DB: first writer wins pickup_assigned
    API-->>CA: status push and tracking unlocked
  end
end
opt timeout and nobody accepted
  W->>CM: overdue pickup Assign enabled
  CM->>API: direct assign staff
  API->>DB: pickup_assigned
  API->>PA: SSE assigned to you cannot reject
  API-->>CA: tracking unlocked
end

```

### 4.2 Door count, draft, bill

```mermaid
sequenceDiagram
autonumber
actor P as Pickup boy
participant PA as Pickup app
participant API as Backend API
participant DB as PostgreSQL
participant ST as Object storage
actor C as Customer
P->>PA: open assigned order
PA->>API: GET booked services with per kg or per unit
loop each booked service
  P->>PA: expand service
  alt per unit
    P->>PA: set counts from that service catalogue
  else per kg
    P->>PA: enter ONE weight
  end
  P->>PA: add ONE photo camera or gallery
  PA->>ST: upload image
  PA->>API: PATCH service lines items_confirmed false
  API->>DB: upsert draft rows
end
Note over PA,API: app killed: reopen GET draft from DB
P->>PA: Mark as picked up
PA->>API: POST confirm pickup
API->>DB: validate all services filled
API->>DB: compute Bill lines plus DELIVERY_FEE plus EXPRESS_FEE
API->>DB: items_confirmed true and Order picked_up
API-->>C: push Pickup done and View bill
API-->>PA: button becomes Submit request to CM

```

### 4.3 Submit request to CM and Verified and Received

```mermaid
sequenceDiagram
autonumber
actor P as Pickup boy
participant PA as Pickup app
participant API as Backend API
participant DB as PostgreSQL
participant MA as Management app
actor CM as Collection manager
P->>PA: tap Submit request to CM
PA->>API: POST submit request
API->>DB: Order submitted_to_cm
API-->>PA: button Waiting for CM verification inactive
Note over PA: cannot cancel request or edit items
CM->>MA: open Incoming list
MA->>API: GET incoming placed pickup_assigned picked_up submitted_to_cm
CM->>MA: tap Verified and Received
MA->>API: POST receive only if submitted_to_cm
API->>DB: Order received_by_collection and pickup Delivery completed
P->>PA: pull to refresh
PA->>API: GET my jobs
API-->>PA: row gone

```

### 4.4 Plant queue

```mermaid
sequenceDiagram
autonumber
actor CM as Collection manager
participant MA as Management app
participant API as Backend API
participant DB as PostgreSQL
actor SM as Service man
actor DM as Distribution manager
actor C as Customer
CM->>MA: tap Send to service queue
MA->>API: POST send to services
API->>DB: one ServiceQueueItem per OrderItem with assigned_at and is_express
API->>DB: Order submitted_to_services
API-->>MA: order leaves received list into history
API-->>C: status push In Process
loop every 2 min while queue screen visible
  SM->>API: GET queue ORDER BY is_express DESC assigned_at ASC
  API-->>SM: rows with status and assigned_at
end
SM->>API: PATCH in_progress any row
API->>DB: row in_progress and Order services_in_progress
SM->>API: PATCH completed
API->>DB: row completed
opt any item completed
  DM->>API: GET in-plant list
  API-->>DM: whole order with completed and pending items
end
opt last item completed
  API->>DB: Order services_completed
  API-->>C: status push Ready
  API->>API: evaluate drop search trigger
end

```

### 4.5 Drop assignment

```mermaid
sequenceDiagram
autonumber
participant API as Backend API
participant W as BullMQ worker
participant GM as Google Maps
participant KA as Captain app
actor DM as Distribution manager
participant DB as PostgreSQL
actor C as Customer
API->>API: services_completed
alt Express or delivery instant
  API->>W: start drop search now
else scheduled and time reached or already past
  API->>W: start drop search now
else scheduled and still in future
  API-->>DM: Assign disabled Available from time
  Note over W: no search until delivery_time_from
end
loop slice 1 to 5
  W->>GM: distance to drop address
  W->>KA: SSE drop offer for staff in ring
  opt captain accepts
    KA->>API: accept drop offer
    API->>DB: first writer wins
  end
end
opt timeout no accept
  API-->>DM: Assign enabled
  DM->>API: direct assign captain
  API->>KA: SSE assigned cannot reject
end
API->>DB: Order out_for_delivery
API-->>C: Out for delivery plus name phone photo
API-->>C: map path once plus live pin
loop captain GPS ticks
  KA->>API: update live location
  API-->>C: pin moves
end
opt pin off path
  API->>GM: refresh Directions at most every 2 min
end

```

### 4.6 Payment and delivered

```mermaid
sequenceDiagram
autonumber
actor C as Customer
participant CA as Customer app
participant API as Backend API
participant PSP as PSP UPI
participant UPI as UPI app
participant DB as PostgreSQL
actor K as Captain
participant KA as Captain app
Note over C,CA: pay unlocks when out_for_delivery
C->>CA: optional enter coupon code
CA->>API: apply one existing Coupon
API->>DB: Bill discount and final_amount
C->>CA: Pay with UPI
CA->>API: create payment
API->>PSP: create UPI intent for final_amount
CA->>UPI: open UPI intent
UPI->>PSP: pay
alt success
  PSP->>API: webhook success
  API->>DB: payment_status completed method upi
  API-->>CA: paid everywhere customer staff admin
  API-->>KA: bill shows paid
else failure
  PSP->>API: webhook failed
  API-->>CA: retry UPI allowed
  K->>KA: UPI failed so tap Paid in cash
  KA->>API: record cash
  API->>DB: payment_status completed method cod
  API-->>CA: payment completed
end
K->>KA: take ONE drop photo
KA->>API: Mark as delivered only if payment completed
API->>DB: drop_proof plus Order delivered plus Delivery completed
API-->>CA: Delivered

```

### 4.7 Cancel and reschedule

```mermaid
sequenceDiagram
autonumber
actor C as Customer
participant CA as Customer app
participant API as Backend API
participant DB as PostgreSQL
participant W as BullMQ worker
C->>CA: open placed order
alt Cancel
  C->>CA: enter reason then Confirm
  CA->>API: POST cancel with reason
  API->>DB: check status placed else reject
  API->>W: cancel pickup job and offers
  API->>DB: cancelled plus cancel_reason
  API-->>CA: history Cancelled
else Reschedule
  C->>CA: change pickup and or delivery
  CA->>API: PATCH schedule
  API->>API: delivery at least pickup plus PICKUP_DELIVERY_BUFFER_DAYS
  API->>W: stop current search
  alt new pickup now or reached
    API->>W: start search again
  else future
    API->>W: schedule new pickup_time_from
  end
  API-->>CA: updated order
end
Note over CA,API: after pickup_assigned both actions are hidden and rejected

```
