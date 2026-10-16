# Phase 4: Cancel and reschedule

**Size:** S  **Depends on:** 3  **Migration:** none (columns added in Phase 2)

## Goal

Real customer cancel (with reason) and reschedule, both allowed **only while `placed`** (before any pickup partner is assigned).

Spec: Part 6, diagram 3.4 and sequence 4.7.

## Tasks

1. `POST /orders/:orderId/cancel` body `{ reason }` (required, trimmed, 3 to 500 chars).
   - One transaction: conditional `updateMany where order_id, customer_id, order_status = 'placed'`. Count 0 -> 409 `CANCEL_NOT_ALLOWED` (covers "accept won the race" and "already assigned").
   - Set `order_status = cancelled`, `cancel_reason`, `cancelled_at`; set both `Delivery` legs `delivery_status = cancelled`.
   - After commit: `engine.stopSearch(orderId, 'pickup', 'cancelled')` (cancel pending request and recipients, remove delayed jobs, SSE `assignment_cancelled` to offered staff). Push to the customer.
2. `PATCH /orders/:orderId/schedule` body `{ pickup_mode, pickup_time_from, pickup_time_to, delivery_mode, delivery_time_from, delivery_time_to }` (any subset).
   - Allowed only when `placed` and **not Express** (409 `RESCHEDULE_NOT_ALLOWED`).
   - Same validation as booking via `schedule-rules.js` (buffer, past times).
   - No reason field. Update order and leg preferred windows.
   - Stop the current search, then apply the same trigger logic as booking: instant or time already reached -> start now; otherwise delayed start at the new `pickup_time_from`.
3. Accept path (Phase 3) already requires `placed`; verify the pair of conditional updates cannot both succeed.
4. Lists: customer `GET /orders?bucket=active|history` (full DTO in Phase 10): cancelled orders appear only in history. CM incoming and pickup lists already exclude `cancelled`.

## API contract

| Method | Path | Body | Errors |
|---|---|---|---|
| POST | `/orders/:orderId/cancel` | `{ reason }` | 400 no reason, 409 not `placed` |
| PATCH | `/orders/:orderId/schedule` | times/modes | 409 not `placed` or Express, 400 buffer |

## Tests

- Cancel with and without reason; cancel after `pickup_assigned` -> 409; cancel twice -> second 409.
- Cancel while a search is running: request `cancelled`, jobs removed (verify queue), offered staff get `assignment_cancelled`, accept afterwards -> 409.
- Cancel vs accept race (parallel): exactly one wins; final state consistent (either `cancelled` with no assignee, or `pickup_assigned` with cancel 409).
- Reschedule: scheduled -> later scheduled (search stopped, delayed start moved); scheduled -> instant (search starts now); buffer violation 400; Express 409; after assignment 409.
- Cancelled order disappears from CM incoming and active customer list; appears in history.

## Exit checklist

- [ ] Both endpoints implemented with transactional guards.
- [ ] Race test green (run it 20 times in a loop locally).
- [ ] Postman folder "Phase 4".
