# State machines

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 5. UML state diagrams

### 5.1 Order status (customer-visible lifecycle)

```mermaid
stateDiagram-v2
[*] --> placed: Confirm order
placed --> cancelled: Customer cancel with reason
placed --> placed: Reschedule stops and restarts search
placed --> pickup_assigned: Accept or CM force-assign
pickup_assigned --> picked_up: Mark as picked up plus Bill
picked_up --> submitted_to_cm: Submit request to CM
submitted_to_cm --> received_by_collection: CM Verified and Received
received_by_collection --> submitted_to_services: CM Send to service queue
submitted_to_services --> services_in_progress: First item In progress
services_in_progress --> services_in_progress: More items start or finish
services_in_progress --> services_completed: Last item completed
services_completed --> out_for_delivery: Captain accepts or DM force-assign
out_for_delivery --> delivered: Payment completed plus photo plus Mark delivered
cancelled --> [*]
delivered --> [*]

```

> Not used on the new path: `dispatch_assigned`, `payment_pending`, `closed` (enum values exist; spec never sets them).

### 5.2 Service queue item

```mermaid
stateDiagram-v2
[*] --> pending: Send to service queue sets assigned_at
pending --> in_progress: Service man starts any row
in_progress --> completed: Service man completes
completed --> [*]
note right of pending
  Several rows may be in_progress at once.
  No mark for later.
  Order by is_express then assigned_at.
end note

```

### 5.3 Pickup search / drop search engine

```mermaid
stateDiagram-v2
[*] --> Idle
Idle --> Waiting: scheduled and time not reached
Waiting --> Searching: time reached
Idle --> Searching: instant or Express or services_completed late
state Searching {
  [*] --> Slice1
  Slice1 --> Slice2: no accept
  Slice2 --> Slice3: no accept
  Slice3 --> Slice4: no accept
  Slice4 --> Slice5: no accept
}
Searching --> Assigned: first accept wins
Searching --> TimedOut: timeout no accept
TimedOut --> ManagerAssigned: CM pickup or DM drop assigns
Searching --> Stopped: customer cancels or reschedules
Assigned --> [*]
ManagerAssigned --> [*]
Stopped --> Idle: reschedule restarts

```

### 5.4 Assignment request and recipient (today enums)

```mermaid
stateDiagram-v2
[*] --> pending: request offered
pending --> accepted: staff accepts first
pending --> expired: window ended
pending --> cancelled: superseded or cancelled or manager assigned
pending --> rejected: staff rejects via offer
accepted --> [*]
expired --> [*]
cancelled --> [*]
rejected --> [*]
note right of pending
  Manager force-assign: staff cannot reject.
  Race: DB first writer wins.
end note

```

### 5.5 Bill and payment

```mermaid
stateDiagram-v2
[*] --> NoBill: order placed
NoBill --> BillPending: Mark as picked up writes Bill
NoBill --> [*]: cancelled before pickup
BillPending --> BillPending: coupon applied or UPI failed
BillPending --> PaidUPI: UPI success webhook
BillPending --> PaidCash: captain Paid in cash after UPI fail
PaidUPI --> [*]
PaidCash --> [*]
note right of BillPending
  Customer view only until out_for_delivery.
  Delivered is blocked until paid.
end note

```

### 5.6 Pickup boy one button

```mermaid
stateDiagram-v2
[*] --> MarkAsPickedUp: pickup_assigned
MarkAsPickedUp --> DraftSaved: autosave each service
DraftSaved --> MarkAsPickedUp: still unfinished
MarkAsPickedUp --> SubmitRequest: all services filled and bill written
SubmitRequest --> Waiting: request sent
Waiting --> [*]: CM verified and received
note right of Waiting
  Button label: Waiting for CM verification.
  Inactive. No cancel. No edit.
end note

```

### 5.7 Delivery leg row

```mermaid
stateDiagram-v2
state PickupLeg {
  [*] --> p_assigned
  p_assigned --> p_in_progress: boy works the job
  p_in_progress --> p_completed: CM Verified and Received
}
state DropLeg {
  [*] --> d_assigned
  d_assigned --> d_out: assigned equals out for delivery
  d_out --> d_completed: paid then photo then delivered
}
[*] --> PickupLeg
PickupLeg --> DropLeg: later after plant
DropLeg --> [*]

```
