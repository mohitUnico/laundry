# Phase 3: Assignment engine (pickup first, built generic for drop)

**Size:** L  **Depends on:** 2  **Migration:** `v2_p03_assignment_engine`

## Goal

Replace the old "offer to everyone, 120 s, retry twice" worker with the spec's expanding-ring search, one timeout, first-accept-wins, and manager force-assign **only after timeout**. Pickup is wired now; the engine takes `deliveryType` so Phase 8 only adds the drop trigger.

Spec: Part 2 (P2.1, P2.6, P2.7), diagrams 4.1, 5.3, 5.4.

## Design

```
onOrderPlaced / dropTrigger
   -> engine.startSearch({ orderId, deliveryType })
        creates ONE DeliveryAssignmentRequest (status pending, expires_at = now + timeout)
        notifies ring 1, schedules slice 2 ... slice N and a timeout job
   slice i  : radius_i = i / N * MAX_RANGE_KM; notify on-shift staff within radius_i
              who are not already recipients of this request
   accept   : conditional update delivery.staff_id IS NULL (first writer wins), stop all jobs
   timeout  : request -> expired, pending recipients -> expired, SSE "assignment_expired"
              manager Assign becomes enabled (derived, see below)
   force    : directAssignDelivery allowed only when request expired and delivery unassigned
```

Derived "assign state" (no new column): `searching` while the latest request is `pending`; `enabled` when the latest request is `expired` and the delivery is unassigned; `assigned` otherwise. Phase 8 adds `available_from` for scheduled drops.

Distance: `distance.provider.js` interface `distanceKm(from, to)`; default implementation is haversine in SQL/JS. A road-distance provider can replace it later.

Staff considered for rings: `is_active`, `is_verified_by_admin`, active shift, known `current_latitude/longitude` (A4). Staff already on another job still qualify (A3).

## Schema changes

```prisma
model DeliveryAssignmentRequest {
  slice_count    Int       @default(5)
  current_slice  Int       @default(0)
  max_range_km   Decimal   @db.Decimal(8,2)
  next_slice_at  DateTime?
  ended_reason   String?   @db.VarChar(30)  // accepted | timeout | cancelled | forced
}
model DeliveryAssignmentRecipient {
  slice_index    Int?
  distance_km    Decimal?  @db.Decimal(8,2)  // at the moment of offer
}
```

`DeliveryAssignmentStatus.expired` is reused for "timed out".

## Tasks

1. `src/services/assignment/`:
   - `assignment-engine.service.js`: `startSearch`, `advanceSlice(requestId)`, `finishTimeout(requestId)`, `stopSearch(orderId, deliveryType, reason)`, `getAssignState(orderId, deliveryType)`.
   - `ring-candidates.js`: SQL for on-shift staff within radius and not already recipients; returns `staffId, distanceKm`.
   - `distance.provider.js` (haversine now).
   - `assignment.queue.js`: new BullMQ queue `delivery-assignment`; deterministic job ids `assign:{requestId}:slice:{i}` and `assign:{requestId}:timeout`; delayed `start` job id `assign-start:{orderId}:{type}`.
   - `assignment.worker.js`: handlers call the engine; every handler **re-reads DB state and no-ops** if the request is no longer `pending` or the delivery is already assigned (idempotent).
   - `assignment-catchup.job.js` (every 60 s): (a) `placed` orders with an unassigned pickup leg, no pending request, and (instant or `pickup_time_from <= now`) -> start; (b) `pending` requests whose `next_slice_at` has passed -> advance; (c) `pending` requests past `expires_at` -> time out. This is the Redis-loss safety net (A11).
2. `assignment-trigger.js` (stub from Phase 2 becomes real): `onOrderPlaced`: instant or Express -> start now; scheduled -> delayed `start` job at `pickup_time_from` (delay 0 if already past).
3. Offer delivery: reuse `DeliveryStaffNotification` + SSE `notification` event + FCM. Add SSE event `assignment_expired` (closes overlay) and `forced_assignment` for manager assign.
4. Accept (`respondToAssignmentRequest`): keep first-writer conditional update; add `order.order_status === 'placed'` check for pickup (fixes F5); on success call `assertTransition`, write `pickup_assigned`, cancel remaining recipients, remove pending jobs for the request, set `ended_reason = accepted`. Reject stays as "decline this offer" (it does not unassign anyone).
5. Force-assign (`directAssignDelivery`): add guard `assignState === 'enabled'` else 409 `ASSIGNMENT_NOT_ENABLED` including `{ state, endsAt }`; set `ended_reason = forced`; no reject path exists afterwards (spec: cannot reject).
6. Manager staff list: `GET /api/v1/staff-app/collection-manager/orders/:orderId/assignable-staff` returns all verified active delivery staff, on-shift first, with `onShift`, `distanceKm` (haversine to pickup address, `null` if unknown), `lastLocationAt`. (Decision: any verified staff after timeout.)
7. CM routes: remove `POST /orders/:orderId/assign-pickup` (manual start) and `createPickupAssignment`. Keep `assign-pickup-direct` with the new guard.
8. Customer tracking gate: `GET /orders/:orderId/tracking` returns `{ trackingAvailable: false }` while `placed`; real data from `pickup_assigned` on (full DTO in Phase 10).
9. Delete: old `pickup-assignment.worker.js`, `pickup-assignment.queue.js`, `pickup-assignment-catchup.job.js`, `config/delivery-assignment.config.js`, env flags `PICKUP_ASSIGNMENT_*`, `sendToAll`, two-retry logic. `server.js` always starts the new worker and catch-up job (A11).
10. Read all timing from the Phase 1 config service.

## API contract

| Method | Path | Notes |
|---|---|---|
| GET | `/staff-app/collection-manager/orders/:orderId/assignable-staff` | **new** |
| POST | `/staff-app/collection-manager/orders/:orderId/assign-pickup-direct` | guarded (after timeout only) |
| POST | `/staff-app/collection-manager/orders/:orderId/assign-pickup` | **removed** |
| POST | `/delivery-staff/assignment-requests/:id/accept` | now checks order is `placed` |
| GET | `/orders/:id/tracking` | `trackingAvailable:false` until assigned |
| SSE | `assignment_expired`, `forced_assignment` | **new events** |

## Tests

- Rings: with the 4 fixture staff at 1/3/6/12 km and MAX 10 km, 5 slices -> slice 1 (2 km) offers only the 1 km staff, slice 2 (4 km) adds the 3 km staff, slice 3 (6 km) adds the 6 km staff, the 12 km staff is never offered. Nobody is offered twice.
- Off-shift staff never offered; unverified/inactive never offered; staff with no location skipped.
- First accept wins; parallel accepts -> exactly one 200 and one 409; other recipients cancelled.
- Accept after timeout -> 409 expired.
- Timeout: request `expired`, assign state `enabled`; force-assign works; force-assign before timeout -> 409 `ASSIGNMENT_NOT_ENABLED`.
- Zero staff on shift: timeout still fires; `assignable-staff` lists off-shift verified staff.
- Instant/Express starts immediately; scheduled starts at `pickup_time_from` (test by calling the delayed handler); catch-up job restarts a lost search.
- Engine handlers are idempotent (call `advanceSlice` twice).
- Test clock: handlers take an injected `now`; `ASSIGNMENT_TIMEOUT_MINUTES` accepts decimals only under `NODE_ENV=test`.

## Exit checklist

- [ ] Old worker/queue/catch-up/config files and env flags are gone.
- [ ] Ring, race, timeout and force-assign tests green.
- [ ] Manual run: place order -> staff app SSE offer -> accept -> `pickup_assigned`.
- [ ] Manual run: place order, nobody accepts, CM force-assigns after timeout.
- [ ] Postman folder "Phase 3".
