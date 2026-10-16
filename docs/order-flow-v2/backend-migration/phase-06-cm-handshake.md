# Phase 6: Collection Manager handshake

**Size:** S  **Depends on:** 5  **Migration:** none

## Goal

The one-button handshake: partner taps **Submit to Collection Manager** (`picked_up -> submitted_to_cm`); the CM taps **Mark received** (`submitted_to_cm -> received_by_collection`) and only then is the pickup leg completed.

Spec: Part 3 (P3.5 to P3.9), Part 4 (P4.1, P4.2), diagrams 4.3, 5.7.

## Tasks

1. **Submit:** `POST /delivery-staff-app/orders/:orderId/submit-to-cm`
   - Only the pickup leg owner; only from `picked_up`; `assertTransition` -> `submitted_to_cm`.
   - Does **not** complete the pickup leg (leg stays `in_progress`).
   - Notifies the CM (SSE + FCM) "Order X is on its way".
   - Idempotent when already `submitted_to_cm` (200 with current state).
2. **Receive:** rewrite `markReceived` in `collection-manager.service.js`
   - Allowed only from `submitted_to_cm` (409 otherwise, including `picked_up`: the CM cannot skip the partner submit).
   - Single transaction: order -> `received_by_collection`, pickup `Delivery` -> `completed` with `completed_at`.
   - Customer push "received at the plant".
3. **CM incoming list** (`GET /staff-app/collection-manager/orders/incoming`): returns everything not yet received and not cancelled, with a `phase` and flags:
   - `placed` (searching / assign enabled), `pickup_assigned`, `picked_up`, `submitted_to_cm` (with `canMarkReceived = true`), `received_by_collection` (ready to submit to plant).
   - Each row: `is_express`, pickup mode/time, partner name/phone (when assigned), `assign: { state }` from the engine, bill total once known.
   - Express orders sort first, then by `created_at`.
4. **Partner order list:** add `primaryAction` derived from order + leg state (`MARK_PICKED_UP`, `SUBMIT_TO_CM`, `WAITING_FOR_CM`, `NONE`) so the Flutter app never decides the next step itself.
5. Remove: old partner `submit-to-collection` path that completed the leg, any CM path that moves `picked_up -> received_by_collection`.

## API contract

| Method | Path | Notes |
|---|---|---|
| POST | `/delivery-staff-app/orders/:orderId/submit-to-cm` | **new** |
| POST | `/staff-app/collection-manager/orders/:orderId/mark-received` | only from `submitted_to_cm` |
| GET | `/staff-app/collection-manager/orders/incoming` | new fields: `phase`, `canMarkReceived`, `assign.state`, `is_express` |

## Tests

- Full chain: accept -> confirm -> submit -> receive; assert each status and that the pickup leg completes only at receive.
- CM mark-received at `picked_up` -> 409; partner submit before confirm -> 409; double submit idempotent; double receive -> 409/idempotent per rule.
- Wrong staff (another partner, other role) -> 403.
- Incoming list shows `canMarkReceived` only at `submitted_to_cm`; cancelled orders excluded; Express first.
- `primaryAction` correct at each state.

## Exit checklist

- [ ] Handshake chain test green.
- [ ] No endpoint can jump `picked_up -> received_by_collection`.
- [ ] Postman folder "Phase 6".
