# Status catalogue

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 7. Status catalogue

### 7.1 Order status

| DB status | Set by / when | Customer tracker | Visible to | Allowed actions | Next |
|---|---|---|---|---|---|
| `placed` | Customer confirms. No Bill. | No tracking. Orders: Partner not assigned | Customer; CM Incoming (yet to pick up) | Customer: cancel, reschedule. CM: force-assign after timeout | pickup_assigned / cancelled |
| `pickup_assigned` | First accept or CM force-assign | Out for pickup (map, name, photo) | Customer; pickup boy; CM Incoming | Boy: draft, Mark as picked up. Cancel and reschedule hidden | picked_up |
| `picked_up` | Mark as picked up. Bill written. | Pickup done. View bill (no pay) | Customer; pickup boy; CM Incoming | Boy: Submit request to CM. No edit | submitted_to_cm |
| `submitted_to_cm` | Boy taps Submit request | In Process (customer unchanged from Pickup done is OK; spec: not a visible step) | Pickup boy (Waiting, inactive); CM Incoming | CM: Verified and Received. No cancel of request | received_by_collection |
| `received_by_collection` | CM verified | In Process | CM Received; row gone from boy on pull-to-refresh | CM: Send to service queue | submitted_to_services |
| `submitted_to_services` | CM sends. Queue rows created. | In Process | CM History; service men queues | SM: start any row | services_in_progress |
| `services_in_progress` | First item In progress; stays until last done | In Process | SM; DM In-plant (when any item completed) | SM: complete. DM: expand only | services_completed |
| `services_completed` | Last item completed | Ready | DM Ready to dispatch | Auto drop search per mode. DM Assign disabled until timeout or Available from time | out_for_delivery |
| `out_for_delivery` | Captain accepts or DM force-assign (immediately) | Out for delivery: map, path, name, phone, photo; Pay unlocked | Customer; captain; DM History (not delivered yet) | Customer: coupon plus UPI. Captain: Paid in cash if UPI fails, then photo, delivered | delivered |
| `delivered` | Payment completed plus one drop photo | Delivered | History everywhere | — | end |
| `cancelled` | Customer cancel only while placed | History: Cancelled | Customer history; CM/boy lists drop it | — | end |
| `dispatch_assigned`, `payment_pending`, `closed`, `draft` | [UNUSED] exist in enum; not part of the locked flow. Do not set them. |  |  |  |  |

### 7.2 Other status fields

| Entity | Values | Meaning in this flow |
|---|---|---|
| `ServiceQueueItem.queue_status` | pending · in_progress · completed | One row per service item. Multiple in_progress OK. No mark-for-later. |
| `OrderItem.item_status` | pending · in_progress · completed | Mirrors the queue row. DM uses it to grey pending lines. |
| `Bill.payment_status` | pending · completed · failed · refunded | pending until UPI or cash. completed shows everywhere. refunded unused (no prepay). |
| `Bill.payment_method` | upi · cod | cod only as boy-recorded fallback after UPI fail. card and wallet not used. |
| `DeliveryAssignmentRequest.status` | pending · accepted · rejected · expired · cancelled | Offer lifecycle. Manager assign cancels pending offers. |
| `Delivery.delivery_status` | assigned · in_progress · completed · cancelled | Pickup completes on CM receive. Drop completes on delivered. |
| `pickup_mode / delivery_mode` [NEW] | instant · scheduled | Express forces both to instant. |
| `is_express` [NEW] | true · false | Chip on every card; queue band; EXPRESS_FEE. |
| `items_confirmed_at` [NEW] | null · timestamp | null = draft at door; set on Mark as picked up. |

### 7.3 Which list shows which status

| List | Statuses shown | Remove when |
|---|---|---|
| Customer Orders / Active | placed … out_for_delivery | delivered or cancelled → History |
| Pickup boy jobs | pickup_assigned · picked_up · submitted_to_cm | received_by_collection (pull-to-refresh) |
| CM Incoming | placed · pickup_assigned · picked_up · submitted_to_cm | received_by_collection |
| CM Received | received_by_collection | Send to service queue → History |
| Service man queue | queue rows pending · in_progress | completed → Completed tab |
| DM In-plant | services_in_progress with ≥1 item completed | all done → Ready |
| DM Ready to dispatch | services_completed, no captain | captain assigned → History |
| DM History | out_for_delivery · delivered | — |
| Captain jobs | drop assigned → out_for_delivery | delivered |
