# Phase 7: Plant queue (one queue and one service man per service)

**Size:** M  **Depends on:** 6  **Migration:** `v2_p07_service_queue`

## Goal

Every service has **its own queue** and exactly one service man (existing rule: `Staff.service_id` is unique). CM submits the order to services; each service's queue is a plain polled list ordered Express first then oldest first. The service man starts or finishes work; the distribution manager sees everything in the plant.

Spec: Part 4 (P4.3 to P4.9), Part 7 (queue band), diagrams 4.4, 5.8.

Because admins can add or change services at any time ([Phase 7A](phase-07a-admin-catalogue.md)), the queue **belongs to the service**, not to the person. The service man sees the queue of `staff.service_id`; `ServiceQueueItem.service_man_id` records who the item was issued to / handled by.

## Schema changes

```prisma
model ServiceQueueItem {
  is_express  Boolean   @default(false)
  // assigned_at already exists; it becomes the FIFO sort key (set when CM submits to services)
  @@index([service_id, queue_status, is_express, assigned_at])   // replaces the priority-based index
}
```

`priority` stays until Phase 12 (unused). Existing fields used as is: `service_id`, `service_man_id`, `queue_status` (`pending|in_progress|completed`), `started_at`, `completed_at`, `quantity`, `weight_kg`, `item_name`.

## Tasks

1. **Submit to services** (`collection-manager-app.service.js`, only from `received_by_collection`):
   - **Preflight before creating anything:** for every `OrderItem`, the service must have an active service man (`Staff.role = service_man`, `is_active`, `service_id = service`). If any is missing -> 409 `NO_SERVICE_MAN` naming those services; nothing is created and the order stays `received_by_collection`.
   - Create one `ServiceQueueItem` per `OrderItem` with `service_id`, `service_man_id` (the current man), `is_express = order.is_express`, `assigned_at = now`, `quantity`/`weight_kg`/`item_name` copied from the door count.
   - Order -> `submitted_to_services` (via the guard).
2. **Service queue** (`GET /staff-app/service-man/queue`):
   - Items where `service_id = <caller's service_id>` and status `pending` or `in_progress`, ordered `is_express DESC, assigned_at ASC`. (Keyed by service, so replacing the service man needs no data move.)
   - Response meta: `serviceId`, `serviceName`, `pollSeconds` from config. The app polls; remove the queue SSE events for new items.
   - Each row: order id, service, express badge, pricing type, quantity or weight recorded at the door.
3. **Actions** (`PATCH /staff-app/service-man/queue/:id/status`): only `in_progress` and `completed`.
   - Ownership check changes from `service_man_id === staffId` to `item.service_id === staff.service_id` (the old check at `service-man-app.service.js` would block a replacement man).
   - `pending -> in_progress`, `in_progress -> completed`, **and `pending -> completed`** directly (A12).
   - Several `in_progress` items at once are allowed; set `service_man_id` to the acting staff on start/complete so history shows who did the work.
   - **Remove `mark_for_later`** and the re-queue/priority code.
   - On first `in_progress` for an order: order -> `services_in_progress`.
   - On `completed`: `OrderItem.item_status = completed`, `completed_at`.
   - After each completion run `allServicesDone(order)`; when true, order -> `services_completed` in the same transaction, then call `dropTrigger.evaluate(orderId)` (no-op stub until Phase 8).
4. **Completed history** for the service man (`.../queue/history`): filter by `service_id` as well.
5. **Distribution Manager `in-plant` list** (`GET /staff-app/distribution-manager/orders/in-plant`): every order in `submitted_to_services`, `services_in_progress` or `services_completed`; per-service rows with status, service name and service man name; Express first. The whole-order expand is the same payload.
6. Remove the DM verify flow and any `services_completed -> dispatch_assigned` code (full DM removal in Phase 8).

## API contract

| Method | Path | Notes |
|---|---|---|
| POST | `/staff-app/collection-manager/orders/:orderId/submit-to-services` | preflight: every service has an active service man |
| GET | `/staff-app/service-man/queue` | the caller's **service** queue; `is_express DESC, assigned_at ASC`; `pollSeconds` |
| PATCH | `/staff-app/service-man/queue/:id/status` | `in_progress` or `completed` only |
| GET | `/staff-app/distribution-manager/orders/in-plant` | **new** |

## Tests

- Queue order: Express (later) vs ordinary (earlier) -> Express first; within each, oldest first.
- Queues are isolated: a mixed order creates one item in each service's queue; each service man sees only their service's items.
- Order moves to `services_in_progress` on first start and to `services_completed` only after the last service completes.
- `pending -> completed` directly works; `mark_for_later` -> 400.
- Parallel completion of the last two services leads to exactly one `services_completed` transition and one trigger call.
- Missing/inactive service man -> 409 `NO_SERVICE_MAN`, nothing partially created.
- Replacement: deactivate the old service man, register a new one for the same service; the new man sees all pending items and can act on them without any data migration.
- DM `in-plant` content and ordering.

## Exit checklist

- [ ] End-to-end up to `services_completed` on a reset test DB.
- [ ] Queue is per service and survives a service-man replacement.
- [ ] No `mark_for_later`, no queue SSE.
- [ ] Postman folder "Phase 7".
