# Data model

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 6. Data model (existing tables + proposed fields)

```mermaid
erDiagram
CUSTOMER ||--o{ ORDER : places
ORDER ||--o{ ORDER_ITEM : contains
ORDER_ITEM ||--o{ ORDER_ITEM_SELECTION : counts
ORDER_ITEM ||--o| SERVICE_QUEUE_ITEM : queued_as
ORDER ||--o| BILL : billed_by
ORDER ||--o{ DELIVERY : has_legs
DELIVERY ||--o| PICKUP_FOR_DELIVERY : pickup_detail
DELIVERY ||--o| DROP_FOR_DELIVERY : drop_detail
DELIVERY ||--o{ ASSIGNMENT_REQUEST : offered_via
ASSIGNMENT_REQUEST ||--o{ ASSIGNMENT_RECIPIENT : sent_to
STAFF ||--o{ SERVICE_QUEUE_ITEM : works
SERVICE ||--o| STAFF : one_service_man
SERVICE ||--o{ ORDER_ITEM : booked
SERVICE ||--o{ CLOTHES_ITEM : prices
DELIVERY_STAFF ||--o{ DELIVERY : drives
DELIVERY_STAFF ||--o{ SHIFT : on_shift
COUPON ||--o{ BILL : discounts

ORDER {
  uuid order_id PK
  enum order_status
  enum order_type "always both"
  bool is_express "NEW"
  enum pickup_mode "NEW instant or scheduled"
  enum delivery_mode "NEW instant or scheduled"
  datetime pickup_time_from
  datetime delivery_time_from
  text cancel_reason "NEW"
  datetime cancelled_at "NEW"
  datetime items_confirmed_at "NEW"
  datetime received_at
  datetime submitted_to_services_at
}
ORDER_ITEM {
  uuid item_id PK
  enum pricing_type "per_unit or per_kg"
  decimal weight_kg "one per kg service"
  enum item_status
  text photo_url "NEW one per service"
}
ORDER_ITEM_SELECTION {
  uuid selection_id PK
  int quantity "staff counted"
}
SERVICE_QUEUE_ITEM {
  uuid queue_id PK
  enum queue_status
  datetime assigned_at "FIFO key"
  bool is_express "NEW or join order"
  int priority "unused"
}
BILL {
  uuid bill_id PK
  decimal subtotal
  decimal delivery_fee "admin variable"
  decimal express_fee "NEW"
  decimal discount "one coupon"
  decimal final_amount
  enum payment_status
  string payment_method "upi or cod"
  string transaction_id
}
DELIVERY {
  uuid delivery_id PK
  enum delivery_type "pickup or drop"
  string delivery_status
  datetime completed_at
}
PICKUP_FOR_DELIVERY {
  string pickup_proof "legacy single photo"
}
DROP_FOR_DELIVERY {
  string drop_proof "one photo at delivered"
}
COUPON {
  int id PK
  string code
  string discount_type
  bool is_active
}
STAFF {
  uuid staff_id PK
  enum role "CM SM DM"
  uuid service_id "unique"
}

```
