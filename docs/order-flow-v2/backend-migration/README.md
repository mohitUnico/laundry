# WashBee order flow v2: backend migration plan

**Scope:** backend only (`backend/`). Flutter apps and `mart-admin` are out of scope until the backend is finished and tested.
**Source of truth for behaviour:** [../order-flow-spec.md](../order-flow-spec.md) and [../diagrams/](../diagrams/00-overview-pack.md). This plan only says *how and in what order* to get the current backend there.
**How to use:** do one phase at a time. Each phase file has its own scope, schema change, API contract, tests and exit checklist. Do not start phase N+1 until phase N's exit checklist is ticked.

---

## 1. Decisions locked (from your answers)

| Topic | Decision |
|---|---|
| Existing data | **Keep the catalogue: `ServiceCategory`, `Service`, `ClothesItem` (all rows, ids and prices).** Order and customer data need not be kept (carts, orders, deliveries, bills, payments, queues, assignments, notifications are cleared). **`migrate reset` is never run on the dev/prod database**; only the separate test database is reset. Migrations are written so catalogue rows survive untouched (the only catalogue change is additive: `Service.includes/excludes`, default empty). No backfill work is needed. |
| API compatibility | **Break `/api/v1` in place.** Flutter apps are updated after the backend is done and tested. Every phase therefore ends with an "API contract" table so the frontend work can be derived from it later. |
| Payment provider (PSP) | Not chosen yet. Build a **provider interface + mock provider** first. The real PSP is a drop-in later (see Phase 9). |
| Config storage | **DB table with env fallback + small admin API** (Phase 1). Admin UI comes later. |
| Maps | Flutter already has Google Maps. Backend uses **straight-line (haversine) distance** for ring search and for the km shown on manager lists. The route polyline and "refresh Directions every 2 min if off-route" are **client** concerns. A road-distance provider can be plugged in later behind an interface. This replaces spec §2.6 "Google Maps (road)" and is recorded in Phase 13. |
| No staff on shift at timeout | After timeout the manager may assign **any verified, active** delivery staff (on-shift or not). Rings still notify on-shift staff only. |
| Old docs | Remove/rewrite **only docs about the old order/delivery/billing flow**. Auth, email, WhatsApp, Redis setup guides stay (Phase 13). |

## 2. Assumptions I will proceed with (tell me if any is wrong)

| # | Assumption | Why |
|---|---|---|
| A1 | Cart has **one line per service**; the customer switches that line between per kg and per unit. | Spec: "for each service: per kg OR per unit". Today a service can appear twice in a cart. |
| A2 | "Delivery date >= pickup date + `PICKUP_DELIVERY_BUFFER_DAYS`" compares **calendar dates in Asia/Kolkata**, not 48 hours. | Spec says "date". |
| A3 | Offers go to every on-shift staff in the ring **even if they already have an active job**. | Spec is silent; no capacity rule exists. |
| A4 | Staff with **no known location** are skipped by rings (cannot compute distance) but appear in the manager list with "distance unknown". | Needed to make rings deterministic. |
| A5 | Add `includes` / `excludes` string arrays on `Service` for the Pricing tab; editable via the existing service admin API. No CMS. | Spec P8: "Includes bullets: yes", no field exists today. |
| A6 | Photos keep using the existing **Cloudinary** upload service (spec text says S3, code uses Cloudinary). | Reuse, nothing to build. |
| A7 | `DELIVERY_FEE` is a **flat** admin value. `LaundryConfig.service_radius_km` tiers are no longer used for billing. `Bill.tax_amount` stays 0. | Spec: "delivery fee = admin variable". |
| A8 | Coupon rules (percent/fixed, `max_discount`, `min_order_value` vs bill subtotal, validity window, `usage_limit`, `usage_per_user`) are enforced at apply time. Usage is counted from **paid bills** carrying the `coupon_id`. Discount is capped so `final_amount >= 1.00`. | Spec only says "one existing coupon"; `Coupon` has no redemption table, a `coupon_id` on `Bill` is enough. |
| A9 | Cash is **strictly** a fallback: the captain can only record cash if the bill is unpaid **and** at least one UPI attempt has failed. | Spec P3.9 #16. If you want the captain to always be able to take cash, it is a one-line change. |
| A10 | `order_type` stays in the DB as a constant `both` until the cleanup phase, then is removed. | Lowers blast radius in early phases. |
| A11 | Redis is **required in every environment** (the `PICKUP_ASSIGNMENT_USE_QUEUE` flag is removed). A 60 s catch-up job covers lost Redis jobs. | The assignment engine is core, not optional. |
| A12 | A service-man may mark a row Completed directly from pending (today's behaviour) as well as from In progress. | Spec lists only the two actions. |
| A13 | **Each service has its own queue and at most one service man.** The queue belongs to the service. The admin manages categories, services, cloth items and prices at any time. **A service is bookable as soon as the admin has added it and left it active** — a service man is not required at booking. Submit-to-services (Phase 7) still fails with `NO_SERVICE_MAN` if none is assigned yet. | Your requirement. |
| A14 | Price edits never change existing bills (snapshots). The bill uses the price at Mark-as-picked-up time. Catalogue entries used by any order are deactivated, never deleted. `Service.base_price` is kept but ignored by v2 pricing. | Keeps retained catalogue data valid; open gaps listed in Phase 7A. |

## 3. Findings from reviewing the current backend

These are the concrete code facts that drive the phases.

| # | Finding | Where | Phase |
|---|---|---|---|
| F1 | Order create requires cloth selections for per-unit, writes a Bill at place for per-unit, accepts `order_type` pickup_only/drop_only, and has a dead `confirmOrder` draft path. | `services/order.service.js`, `middleware/order.middleware.js` | 2 |
| F2 | Cart stores `CartItemSelection` and `weight_kg`; a service can be in the cart twice. | `services/cart.service.js`, schema | 2 |
| F3 | Pickup assignment: one BullMQ job at `pickup_time_from`, offers to **all** active staff (cap 100), 120 s expiry, **2 auto-retries**, no instant mode, no drop twin, env flag gates the whole thing. | `workers/pickup-assignment.worker.js`, `queues/`, `config/delivery-assignment.config.js` | 3 |
| F4 | Stale delivery statuses `en_route` / `reached` are checked by the worker and catch-up job but never written; real values are `unassigned / assigned / in_progress / completed / cancelled` (free-text column). | worker, catch-up job, schema | 3 |
| F5 | `respondToAssignmentRequest` sets `dispatch_assigned` for drop and **does not check the order is still `placed`** (cancel/accept race). | `services/delivery-operations.service.js` | 3, 4 |
| F6 | `directAssignDelivery` has no "only after timeout" guard and lets staff be force-assigned while the search is still running. | same | 3, 8 |
| F7 | Pickup staff weight API updates **existing** per-kg lines only; one `pickup_proof` URL per delivery; no per-service photo; no item picker. | `services/delivery-staff-app.service.js` | 5 |
| F8 | `OrderItem.unit_price` / `subtotal` are non-null; `OrderItemSelection` has **no price snapshot**, so a later catalogue price change would alter an old invoice. | schema | 5 |
| F9 | `submitted_to_cm` action **completes the pickup delivery** and moves it to the Completed tab at once. | `delivery-staff-app.service.js` `updateAcceptedOrderStatus` | 6 |
| F10 | CM `markOrderReceived` accepts `placed / pickup_assigned / picked_up / submitted_to_cm`; CM has `generateInvoice` and a weights API; CM can start its own pickup assignment. | `services/collection-manager-app.service.js` | 5, 6 |
| F11 | Service queue orders by `priority ASC, assigned_at ASC`, supports `mark_for_later`, has no express band. | `services/service-man-app.service.js`, `collection-manager-app.service.js` | 7 |
| F12 | DM must **verify** then **dispatch**; dispatch sets `dispatch_assigned`; `submitToCustomer` exists for pickup_only walk-ins. | `services/distribution-manager-app.service.js` | 8 |
| F13 | Captain flow is `start_delivery` -> `picked_up` -> `dropped`; `dropped` sets `delivered` **without checking payment**. | `delivery-staff-app.service.js` | 8, 9 |
| F14 | **Security hole:** the customer can mark their own bill `completed` via `processPayment` (any method, any status). | `services/payment.service.js` | 5 (disable), 9 (replace) |
| F15 | No payment attempt record, no PSP code, no coupon redemption link on `Bill`. | schema, payment service | 9 |
| F16 | Admin status override, validators, FCM/WhatsApp text, dashboards and daily metrics still reference `draft`, `dispatch_assigned`, `closed`, `payment_pending`. A DB migration also installs **daily-metrics triggers**. | `admin-order-management.*`, `fcm.service.js`, `whatsapp.service.js`, `daily-metrics.service.js`, `migrations/20260123090000_daily_metrics_triggers` | 11, 12 |
| F17 | SSE hub is in-memory (single instance). Fine for now; noted as a scaling limit. | `services/realtime.service.js` | none |
| F18 | Only `tests/health.test.js` exists. | `backend/tests` | 0 |
| F19 | No Google Maps code or key in backend; ring-style nearby search already exists as SQL haversine on `delivery_staffs.current_latitude/longitude` + active shift. | `delivery-operations.service.js` | 3 |

## 4. Phase map

Size is relative (S/M/L), not days. "Demo" is what you can show and test at the end of the phase.

| Phase | Name | Size | Depends on | Demo at the end |
|---|---|---|---|---|
| [0](phase-00-foundation.md) | Foundation: branch, test harness, fixtures, status guard module | S | none | `npm test` green, seeded personas, tokens script |
| [1](phase-01-config.md) | Config service (DB + env) and admin config API | S | 0 | Change a fee/timeout via API, value is picked up |
| [2](phase-02-booking.md) | Booking: SKU-less cart, place order (modes, Express), no bill | M | 1 | Place ordinary / mixed / Express orders |
| [3](phase-03-assignment-engine-pickup.md) | Assignment engine for pickup (rings, timeout, first-accept, force-assign) | L | 2 | Order placed -> staff offered in rings -> accept or CM force-assign after timeout |
| [4](phase-04-cancel-reschedule.md) | Cancel and reschedule (only while `placed`) | S | 3 | Cancel stops the search; reschedule restarts it |
| [5](phase-05-door-count-and-bill.md) | Door count: drafts, per-service photo, Mark as picked up, bill | L | 3 | Draft survives restart; confirm writes the bill; customer can view, not pay |
| [6](phase-06-cm-handshake.md) | Submit request to CM and Verified & Received | S | 5 | One-button states; row leaves pickup list on CM receive |
| [7](phase-07-plant-queue.md) | Plant: send to services, one queue per service with Express band, DM in-plant | M | 6 | Express jumps ordinary but not older Express; each service has its own queue; DM sees whole order |
| [7A](phase-07a-admin-catalogue.md) | Admin-managed catalogue: add/alter categories, services, cloth items, prices; service-man lifecycle; safe deletes | M | 7 | Admin adds a service + service man, it is bookable with its own queue; price edit leaves old bills unchanged |
| [8](phase-08-drop-assignment-and-dm.md) | Drop engine, DM lists, assign states, out for delivery | L | 3, 7 | Last item done -> drop search per mode -> `out_for_delivery` |
| [9](phase-09-payment-and-delivered.md) | Payment: coupon, UPI intent (mock PSP), cash fallback, delivered gate | L | 5, 8 | Full order from place to delivered, paid by UPI or cash |
| [10](phase-10-customer-read-apis.md) | Customer read APIs: tracker steps, detail, history, Pricing catalogue | M | 9 | App-ready DTOs for every screen |
| [11](phase-11-notifications-admin-metrics.md) | Notifications, admin order management, metrics, dashboards | M | 9 | Pushes match the matrix; admin and metrics agree with new statuses |
| [12](phase-12-cleanup-contract.md) | Contract: drop old columns/enums/code, E2E suites, perf pass | M | 10, 11 | Zero references to dead statuses; E2E green |
| [13](phase-13-docs.md) | Docs: rip out old, write new, update spec and rules | M | 12 | One coherent doc set |

Phases 10 and 11 can run in either order after 9. Everything else is strictly sequential.

## 5. Progress tracker

- [x] Phase 0
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [x] Phase 5
- [x] Phase 6
- [x] Phase 7
- [x] Phase 7A
- [x] Phase 8
- [x] Phase 9
- [x] Phase 10
- [x] Phase 11
- [x] Phase 12
- [x] Phase 13

## 6. Working agreement for every phase

1. Work on branch `feat/order-flow-v2-backend`; one commit (or a few) per phase, message `feat(v2): phase N <name>`.
2. Pattern is **expand -> switch -> contract**. Phases 2 to 11 add the new behaviour and stop using the old one; old columns and dead code are only physically removed in Phase 12. Exception: security-relevant removals (F14) happen immediately.
3. Every state change goes through the transition guard from Phase 0 (`src/constants/order-flow.js`). No ad-hoc `order.update({ order_status })` in new code.
4. Every phase adds Jest + Supertest tests and updates the Postman collection folder for that phase.
5. Prisma migration per phase (`prisma migrate dev --name v2_pNN_<topic>`). Test on a freshly reset **test** DB (`laundry_test`) and on a copy of the real DB with the catalogue (verify catalogue row counts before and after). Never reset the real DB.
6. The phase is done only when its **Exit checklist** is fully ticked and the progress tracker above is updated.

## 7. Spec gaps still open (non-blocking, defaults chosen)

These do not stop any phase. The default in brackets is what will be built unless you change it.

1. Cash fallback strictness (A9). [strict]
2. Whether staff with an active job should still get offers (A3). [yes]
3. `ASSIGNMENT_MAX_RANGE_KM` and `DELIVERY_FEE` / `EXPRESS_FEE` starting values. [seed 10 km, 0, 0; you set real values via admin config]
4. Whether to reject orders placed far outside the laundry's service area. Spec says nothing. [no check]
5. A coupon that makes the bill zero (100% off). [discount capped so the bill is at least 1.00]
6. `how-we-work.md` has 7 steps but the spec locks 6 (merge steps 4 and 5). Frontend-only, noted for later.
