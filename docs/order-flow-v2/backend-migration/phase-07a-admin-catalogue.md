# Phase 7A: Admin-managed catalogue (categories, services, cloth items, prices, service men)

**Size:** M  **Depends on:** 7  **Migration:** `v2_p07a_catalogue_rules` (small, additive; catalogue rows untouched)

## Goal

The admin can add, edit, deactivate and re-price **categories, services and cloth items** at any time, and the rest of the system keeps working: the customer catalogue updates immediately, new services get their own queue and service man, price changes never rewrite old bills, and nothing in use can be deleted by accident.

The CRUD endpoints already exist (`routes/clothes.routes.js`, roles `admin` and `manager`). This phase **hardens** them for v2; it does not rebuild them.

## What exists today

| Area | Today |
|---|---|
| CRUD | `/service-categories`, `/services`, `/clothes-items` (create, read, update, delete) |
| One queue per service | `ServiceQueueItem.service_id`; one service man per service enforced by `Staff.service_id @unique` |
| Service man creation | OTP registration by admin, requires `serviceId`, rejects a second man for the same service (`otp.service.js`) |
| Delete rules | Category blocked while services exist; service blocked while clothes, cart items, queue items or staff reference it |

## Gaps this phase closes

1. **Delete safety:** `deleteService` does not check `OrderItem` (a service with order history would hit a database FK error); clothes-item delete must also check `OrderItemSelection` and cart selections. Rule: anything referenced by an order is **deactivated, never deleted**; the API returns 409 `IN_USE_DEACTIVATE_INSTEAD`.
2. **Bookable vs plant-ready:** a new service is bookable as soon as the admin adds it (active + pricing type available). It may have no service man yet; Phase 7 `submit-to-services` then returns 409 `NO_SERVICE_MAN`. The shared `isServiceBookable(service)` rule is used by the cart, the catalogue and admin screens. `hasServiceMan` is informational only.
3. **Replacing a service man:** `Staff.service_id` is unique, so the old man must be released before the new one registers.
4. **Price edits:** must affect only future bookings.
5. **New fields:** `includes` and `excludes` (Phase 10) must be accepted by the admin validators.

## Bookable rule (shared helper `src/services/catalogue-rules.js`)

A service can be put in a cart only if **all** hold:
- `service.is_active` and its `category.is_active`;
- for `per_kg`: `per_kg_price` is set and > 0;
- for `per_unit`: at least one active `ClothesItem` with price > 0.
- A service man is **not** required to book.

The helper returns `{ bookable, perKgAvailable, perUnitAvailable, reasons[] }`. Phase 2 (cart) calls it from day one; Phase 10 exposes it as `bookable`/`unavailableReason` in `GET /catalog/pricing`.

## Tasks

1. **Delete vs deactivate**
   - `deleteServiceCategory`: unchanged rule plus 409 if any of its services were ever ordered.
   - `deleteService`: add `OrderItem` count check; keep existing checks; on any reference, 409 `IN_USE_DEACTIVATE_INSTEAD`.
   - `deleteClothesItem`: add `OrderItemSelection` and `CartItemSelection` (if still present) checks.
   - Deactivation (`isActive: false`) is always allowed and is the supported way to retire catalogue entries.
2. **Service man lifecycle** (admin only)
   - `POST /api/v1/admin/services/:serviceId/service-man/release`: sets the current man `is_active = false` and `service_id = null`. Pending queue items stay with the service (queue is per service). The service **stays bookable**. `submit-to-services` for orders needing it returns 409 `NO_SERVICE_MAN` until a new man registers (CM sees which service).
   - New man registers through the existing OTP flow with `serviceId` (now allowed because the unique slot is free).
   - `GET /api/v1/admin/services` (list) returns for each service: category, prices, `isActive`, `serviceMan { staffId, name, isActive } | null`, `bookable`, `reasons`, `pendingQueueCount`.
3. **Price edits**
   - No retroactive effect: bills and lines use the Phase 5 snapshots (`OrderItem.unit_price`, `OrderItemSelection.unit_price`, bill fees).
   - Default: the price used is the one **at Mark-as-picked-up time** (the bill is written there, spec: no bill at place). Customer cart/pricing screens show current prices as "estimate". *(Open gap below.)*
   - Updates write `updated_at`; no price history table in this phase.
4. **Validators/controllers:** accept `includes[]` and `excludes[]` on create/update service; validate `per_kg_price >= 0`, `per_unit_price > 0`, unique `(service_id, item_name)` (already in schema) with a friendly 409.
5. **Visibility:** the customer catalogue reads live from the database (no cache), so a new category/service/cloth appears immediately and a deactivated one disappears from **new** carts. Carts already containing a now-unbookable service: `GET /carts` flags the line `available:false`, and `create_order` rejects with 409 `SERVICE_UNAVAILABLE` listing the lines.
6. **In-flight orders are never broken by catalogue edits:** deactivating a service, category or cloth item does not touch existing orders, queue items or bills. Queue and door-count screens read names and prices from the snapshots on the order, not the live catalogue.
7. **Audit:** log (`logger.info`) who changed a price or deactivated an entry (`user_id`, old value, new value). A table is out of scope.

## API contract

| Method | Path | Change |
|---|---|---|
| POST/PUT | `/services`, `/service-categories`, `/clothes-items` | validators accept new fields; friendly duplicate errors |
| DELETE | same | 409 `IN_USE_DEACTIVATE_INSTEAD` when referenced by any order/cart |
| GET | `/admin/services` | **new**: `serviceMan`, `bookable`, `reasons`, `pendingQueueCount` |
| POST | `/admin/services/:serviceId/service-man/release` | **new** |
| GET | `/carts` | lines carry `available` |
| POST | `/orders/create_order` | 409 `SERVICE_UNAVAILABLE` |

## Tests

- Create category -> service (no service man) -> still bookable if the pricing type is available; `hasServiceMan` is false. Add first cloth -> `per_unit` becomes available. Register a service man -> `hasServiceMan` true; booking unchanged.
- Add a new service end to end: appears in the customer catalogue, an order with it reaches its own queue and is served by its own man.
- Deactivate service / category / last cloth item: removed from new carts; existing orders, queues and bills unchanged.
- Delete a service with order history -> 409 `IN_USE_DEACTIVATE_INSTEAD` (not a 500); delete an unused service works.
- Change `per_kg_price` after pickup -> existing bill unchanged; a later order uses the new price.
- Release service man with pending items; register a new one; the new man sees the existing queue; submit-to-services in the gap returns `NO_SERVICE_MAN` with nothing created.
- Cart line becomes unavailable after deactivation -> `create_order` 409 `SERVICE_UNAVAILABLE`.
- Authorisation: customer and non-admin staff get 403 on write routes.

## Open gaps (defaults chosen)

- **Price timing:** bill uses the price at Mark-as-picked-up. *(Alternative: lock the per-kg price at booking time; costs one more column.)*
- **`Service.base_price`:** v2 pricing is per kg or per unit only, so `base_price` is ignored by pricing but **kept** (catalogue data is retained); hide it in the new admin UI.
- **Service man replacement** is two steps (release, then register); a one-call "swap" is not built.

## Exit checklist

- [ ] No delete path can produce a database FK error.
- [ ] `bookable` rule used by cart, create-order, catalogue and admin list.
- [ ] Service-man release/replace tested with a live queue.
- [ ] Catalogue row counts unchanged by the migration (`verify-catalogue`).
- [ ] Postman folder "Phase 7A".
