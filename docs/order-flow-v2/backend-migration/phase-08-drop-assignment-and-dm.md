# Phase 8: Drop assignment and distribution manager

**Size:** M  **Depends on:** 3, 7  **Migration:** none (the engine already supports `deliveryType`)

## Goal

When all services complete, the drop search starts automatically according to the delivery mode; the DM sees ready-to-dispatch orders and history; accepting (or force-assigning) a drop moves the order to `out_for_delivery`.

Spec: Part 5 (P5.1 to P5.9), Part 2, diagrams 4.5, 5.9.

## Tasks

1. `src/services/assignment/drop-trigger.service.js`: `evaluate(orderId)` called after `services_completed`:
   - `is_express` or `delivery_mode = instant` -> `engine.startSearch({ deliveryType: 'drop' })` now.
   - `scheduled`: if `delivery_time_from <= now` (ready late) -> start now; otherwise enqueue the delayed `assign-start:{orderId}:drop` job at `delivery_time_from`. The catch-up job (Phase 3) also covers drop legs.
   - Never starts for a cancelled order or an order that already has a drop assignee.
2. Engine for drop: origin = customer drop address coordinates (spec: nearest to the customer; pickup uses the customer pickup address). Accept path for drop: conditional update, `assertTransition(services_completed -> out_for_delivery)`, drop leg `assigned`, customer push "out for delivery". **There is no `dispatch_assigned` state.**
3. Force-assign for drop: `POST /staff-app/distribution-manager/orders/:orderId/assign-drop` allowed only when assign state is `enabled`; same 409 `ASSIGNMENT_NOT_ENABLED` response shape. Also `GET .../assignable-staff` (same payload as the CM one, distance to the drop address).
4. **DM lists**
   - `GET .../distribution-manager/orders/ready-to-dispatch`: `services_completed` orders with `assign: { state: searching | available_from | enabled, availableFrom? }`. `available_from` when scheduled and the delivery window has not started yet. Express first.
   - `GET .../distribution-manager/orders/history`: orders that left the plant (`out_for_delivery`, `delivered`), newest first, paginated.
   - `GET .../in-plant` (Phase 7) unchanged.
5. **Customer tracking after drop assignment:** captain name, phone, photo, last known location, status text (full DTO in Phase 10).
6. **Remove** DM verify (`verify-order`), `dispatch`, `submit-to-customer`, manual drop assign-start, `dispatch_assigned` writers, and the `closed` writers. Remove `payment_pending` and `dropped` writes (Phase 9 owns payment/delivered).

## API contract

| Method | Path | Notes |
|---|---|---|
| GET | `/staff-app/distribution-manager/orders/ready-to-dispatch` | **new** with `assign.state` |
| GET | `/staff-app/distribution-manager/orders/history` | **new** |
| GET | `/staff-app/distribution-manager/orders/:orderId/assignable-staff` | **new** |
| POST | `/staff-app/distribution-manager/orders/:orderId/assign-drop` | after timeout only |
| POST | `/delivery-staff/assignment-requests/:id/accept` | drop accept -> `out_for_delivery` |
| POST | verify / dispatch / submit-to-customer | **removed** |

## Tests

- Instant and Express: search starts exactly when the last service completes.
- Scheduled, future window: no search at completion, state `available_from`, delayed job exists; running the delayed handler starts the search; ready late -> starts immediately.
- Accept -> `out_for_delivery` and customer notified; second accept -> 409.
- Timeout -> state `enabled` -> force-assign works; before timeout -> 409.
- Drop radius is measured from the customer drop address (fixture staff at different distances).
- Cancelled or already assigned orders do not start a drop search.
- DM lists filter correctly; Express first.

## Exit checklist

- [ ] Order reaches `out_for_delivery` end to end for instant and scheduled drops.
- [ ] Old DM endpoints deleted.
- [ ] Postman folder "Phase 8".
