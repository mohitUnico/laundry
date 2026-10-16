# Phase 12: Cleanup (contract) and end-to-end tests

**Size:** M  **Depends on:** 11  **Migration:** `v2_p12_contract`

## Goal

Delete everything the old flow left behind, so the schema and code contain only v2. Then lock the behaviour with end-to-end suites.

## Schema removals

- Columns: `Order.pricing_model`, `Order.billing_status`, `Order.order_type` (and enum `OrderType`), `Order.pickup_date`, `Order.delivery_date`, `verified_*` fields, `payment_confirmed_at`, `Delivery.needs_weight_machine`, `Delivery.pickup_proof` (replaced by door photos), `ServiceQueueItem.priority`.
- Enum values: `draft`, `dispatch_assigned`, `closed`, `payment_pending` from `OrderStatus` (Postgres requires a create-new-type-and-swap migration; test it on a copy with data).
- Unused tables and enums found by grep after Phase 11 (e.g. `PricingModel`, `BillingStatus`, `CartItemSelection` if still present).
- Unused indexes; add indexes for the new hot paths: `Order(order_status, is_express, created_at)`, `Delivery(order_id, delivery_type)`, `DeliveryAssignmentRequest(delivery_id, status)`, `ServiceQueueItem(service_id, queue_status, is_express, assigned_at)` (already added in Phase 7; keep).

## Code removals

- Dead services/routes/validators/controllers left behind by Phases 2 to 9 (grep for removed route names and imports).
- Env vars: `PICKUP_ASSIGNMENT_*`, anything replaced by `AppConfig`; update `.env.example`, `docker-compose.yml`, deploy scripts.
- Unused npm dependencies.
- Replace the transition guard allow-list with the final table, and make the guard mandatory (lint rule or test that greps for direct `order_status:` writes outside `order-flow.js` helpers).

## End-to-end suites (`tests/e2e/`)

1. **Happy path**: place -> accept -> door -> confirm -> submit -> receive -> services -> drop accept -> pay (mock UPI) -> delivered.
2. **Express** end to end, queue band first, both legs instant, express fee on the bill.
3. **Cancel** before assignment, and cancel-after-accept rejected.
4. **Timeout and force-assign**, pickup and drop.
5. **Scheduled delivery**: not available early, available at window, late-ready starts immediately.
6. **UPI fail -> cash** fallback; webhook-after-cash conflict.
7. **Concurrency**: accept races, parallel confirms, last-two-services completion.
8. **Fresh DB**: `migrate reset` + seed + run the whole suite in CI.

## Final checks

- Postman collection: final v2 folder runs top to bottom with Newman against a seeded dev DB.
- OpenAPI/Swagger regenerated and reviewed.
- Performance sanity: assignment catch-up and queue lists use indexes (`EXPLAIN` on the 5 hot queries).
- Tag `backend-v2-complete`.

## Exit checklist

- [ ] Migration applies to a fresh test DB and to a copy of the Phase 11 DB; catalogue counts and checksum unchanged.
- [ ] `grep` finds no references to removed enums/columns.
- [ ] All e2e suites green in CI.
- [ ] Rollback note: restore the pre-phase DB dump and `git revert` the phase commit; restore from the `pg_dump` taken before the phase. Do not use `migrate reset` on the real DB: the catalogue (categories, services, clothes items) must be kept. Run `verify-catalogue` before and after the migration.
