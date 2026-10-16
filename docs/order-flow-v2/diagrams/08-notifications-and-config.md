# Notifications and config

> Part of the order-flow v2 pack. Source of truth: [`../order-flow-spec.md`](../order-flow-spec.md). Mermaid renders in GitHub / Cursor preview.

## 9. Notifications and realtime

| Moment | Who is told | Channel | Notes |
|---|---|---|---|
| Offer pickup or drop | On-shift staff in ring | SSE + FCM (today) | Overlay; first accept wins |
| Manager force-assign | Assigned staff | SSE | Cannot reject |
| pickup_assigned | Customer | Status push (today) | Tracking appears |
| picked_up | Customer | Status push | Pickup done; View bill. Bill-generated ping to CM/admin: [OUT] |
| submitted_to_cm | CM | List refresh | No live SSE needed |
| received_by_collection | Pickup boy | Pull-to-refresh | No SSE drop |
| submitted_to_services … services_completed | Customer | Status push | In Process → Ready |
| New queue rows | Service man | Poll 1–2 min | No SSE. No Redis for SM. |
| out_for_delivery | Customer | Status push + map | Name, phone display only, photo |
| Payment completed | Customer, captain, admin | Realtime or next GET | Same bill row everywhere |
| delivered | Customer | Status push | — |
| cancelled | Customer | In-app history | No boy to notify (only while placed) |

## 10. Config variables

| Name | Default | Used by |
|---|---|---|
| `ASSIGNMENT_TIMEOUT_MINUTES` | 5 (10 / 20 allowed) | Pickup and drop search window |
| `ASSIGNMENT_RANGE_SLICES` | 5 | Ring steps |
| `ASSIGNMENT_MAX_RANGE_KM` | admin/env | Outer radius |
| `PICKUP_DELIVERY_BUFFER_DAYS` | 2 | Booking + reschedule validation (one constant) |
| `DELIVERY_FEE` | admin-editable | Bill at Mark as picked up |
| `EXPRESS_FEE` | admin-editable | Bill when is_express |
| `SERVICE_QUEUE_POLL_SECONDS` | 120 (60 allowed) | Service man queue poll |
| Directions refresh interval | 2 min max | Map re-route when off path (name TBD) |
