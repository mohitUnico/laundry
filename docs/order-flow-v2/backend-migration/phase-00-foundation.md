# Phase 0: Foundation

**Size:** S  **Depends on:** none  **Migration:** none

## Goal

Make the backend safe to change: a test harness, deterministic fixtures, and one central place that knows which order statuses and transitions are legal. No behaviour change yet.

## Scope

In:
- Branch, baseline tag, catalogue backup, clearing of order/customer data (catalogue is **kept**), docker compose (Postgres + Redis).
- Jest + Supertest integration setup against a separate test database.
- Seed fixtures covering every persona.
- `src/constants/order-flow.js`: status list, allowed transitions, helper `assertTransition(from, to)`.
- A script that prints a JWT per persona for Postman/curl.
- Postman collection: add a new top-level folder `v2` with empty sub-folders per phase.

Out: any endpoint or schema change.

## Tasks

1. `git tag pre-v2-backend` on the current commit; create branch `feat/order-flow-v2-backend`.
2. Commit the untracked `docs/order-flow-v2/` pack (it is the spec for this work).
3. Test infra in `backend/tests/`:
   - `.env.test` (separate DB name `laundry_test`, Redis db index 1, `NODE_ENV=test`).
   - `tests/helpers/app.js` (build the Express app without `listen`), `tests/helpers/db.js` (reset + migrate), `tests/helpers/factories.js`, `tests/helpers/auth.js` (sign JWTs using `utils/jwt.js`).
   - `npm run test:int` runs Jest with `--runInBand`.
4. **Catalogue safety (new):**
   - `scripts/backup-catalogue.js` exports `ServiceCategory`, `Service`, `ClothesItem` (and the service-man `Staff` rows linked by `service_id`) to `.tmp/catalogue-backup.json`. Also take a `pg_dump` of the whole DB. Run both before any migration.
   - `scripts/clear-transactional-data.js` deletes only transactional tables in FK order: cart items/carts, order items/selections, orders, deliveries, assignment requests/recipients, bills/payments/transactions, service queue items, notifications, customer addresses and customers. It never touches the catalogue, `LaundryConfig`, `Coupon`, or admin/staff accounts. It prints row counts before and after and refuses to run unless `--confirm` is passed.
   - `scripts/verify-catalogue.js` prints catalogue row counts and a checksum; run it before and after every migration and compare.
5. Seed (`prisma/seed.js`), idempotent and deterministic. **It must never overwrite or delete catalogue rows:** it upserts by natural key and only creates catalogue data when the tables are empty (i.e. in the test database). Against the real DB it adds only missing personas and config.
   - `LaundryConfig` (one active), admin user.
   - Test DB only: categories, services with `per_kg_price` and clothes items. Real DB: existing catalogue is used as is. **Exactly one `service_man` Staff per service** (needed in Phase 7); on the real DB the seed only creates the missing ones and reports services without one.
   - Staff: 1 collection manager, 1 distribution manager.
   - 4 verified `DeliveryStaff` with known coordinates at 1 km, 3 km, 6 km, 12 km from the laundry, each with an active shift and `current_latitude/longitude`.
   - 1 customer with 2 addresses; coupons (percentage, fixed, expired, capped).
6. `src/constants/order-flow.js`:
   - `ORDER_STATUS` (only the 11 live values for new code: `placed`, `pickup_assigned`, `picked_up`, `submitted_to_cm`, `received_by_collection`, `submitted_to_services`, `services_in_progress`, `services_completed`, `out_for_delivery`, `delivered`, `cancelled`).
   - `TRANSITIONS` map matching [04-state-machines.md](../diagrams/04-state-machines.md) section 5.1 (note `services_in_progress -> services_in_progress` is allowed).
   - `DELIVERY_STATUS` constants for the free-text column: `unassigned`, `assigned`, `in_progress`, `completed`, `cancelled` (removes F4 ambiguity).
   - `assertTransition(from, to)` throws `ConflictError` with code `INVALID_STATUS_TRANSITION`.
7. `backend/scripts/dev-tokens.js`: prints a bearer token per persona (customer, pickup staff x4, CM, DM, SM per service, admin).
8. Verify: `docker compose up -d postgres redis`; on the **real** DB run backup, `verify-catalogue`, `clear-transactional-data --confirm`, `verify-catalogue` again (counts must match), then `npm run prisma:seed`. On the **test** DB only: `npx prisma migrate reset --force` then seed.

## Tests

- Unit: every transition in the state diagram is allowed; every other pair is rejected; unused enum values (`draft`, `dispatch_assigned`, `closed`) are rejected.
- Integration smoke: `GET /health` still passes with the new harness.
- Seed test: after seed, each service has exactly one service man; 4 staff have active shifts.
- Catalogue safety: with a catalogue loaded, run `clear-transactional-data --confirm` and the seed twice; catalogue row counts and checksum are identical before and after; running without `--confirm` deletes nothing.

## Exit checklist

- [ ] Tag and branch exist; docs pack committed.
- [ ] Catalogue backup (`.tmp/catalogue-backup.json` + `pg_dump`) taken; catalogue counts identical after clearing order data.
- [ ] `npm run test:int` green on a clean DB.
- [ ] `node scripts/dev-tokens.js` prints all persona tokens.
- [ ] Transition table unit test passes and matches the diagram.
- [ ] Postman `v2` folder skeleton added.
