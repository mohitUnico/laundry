# Phase 2: Booking (SKU-less cart, place order, no bill)

**Size:** M  **Depends on:** 1  **Migration:** `v2_p02_booking`

## Goal

A customer books **services** (per kg or per unit), picks instant or scheduled for each leg (or Express), and the order is created as `placed` with both delivery legs and **no bill**.

Spec: Part 1 section 2.1-2.2, Part 6 (buffer), Part 7 (Express).

## Schema changes

```prisma
enum ScheduleMode { instant scheduled }

model Order {
  // add
  is_express        Boolean       @default(false)
  pickup_mode       ScheduleMode  @default(instant)
  delivery_mode     ScheduleMode  @default(instant)
  cancel_reason     String?
  cancelled_at      DateTime?
  items_confirmed_at DateTime?
  // relax
  total_amount      Decimal       @default(0) @db.Decimal(10,2)
  pricing_model     PricingModel? // deprecated, removed in Phase 12
}

model OrderItem {
  unit_price Decimal? @db.Decimal(10,2)   // was required
  subtotal   Decimal  @default(0) @db.Decimal(10,2)
}

model CartItem {
  // remove: weight_kg, item_selections
  @@unique([cart_id, service_id])          // assumption A1
}
// remove model CartItemSelection
```

`pickup_time_to` / `delivery_time_to` stay (window end). `order_type` stays, always `both` (A10).

## Tasks

1. **Cart** (`services/cart.service.js`, `routes/cart.routes.js`, `validators/cart.validator.js`)
   - `POST /carts/items` accepts `{ items: [{ service_id, pricing_type }] }`; upsert by `(cart, service)`; switching `pricing_type` updates the line.
   - Validate with the shared `isServiceBookable()` rule (introduced here in `src/services/catalogue-rules.js`, extended in [Phase 7A](phase-07a-admin-catalogue.md)): service and category active. A service man is **not** required to book. `per_kg` requires `per_kg_price > 0`; `per_unit` requires at least one active `ClothesItem`. Failures return 409 `SERVICE_UNAVAILABLE` with the reason.
   - New `PATCH /carts/items/:cartItemId` `{ pricing_type }`.
   - Remove selection increment/decrement/quantity routes and code.
   - `GET /carts` returns lines: service, category, pricing_type, price hints (`per_kg_price`), no quantities.
2. **Create order** (`services/order.service.js`, `middleware/order.middleware.js`)
   - New body: `cart_id`, `pickup_address_id`, `delivery_address_id`, `is_express`, `pickup_mode`, `pickup_time_from`, `pickup_time_to`, `delivery_mode`, `delivery_time_from`, `delivery_time_to`, `special_instructions`.
   - Reject legacy fields (`order_type`, `pickup_date`, `delivery_date`, aliases) so mistakes surface.
   - Rules:
     - `is_express = true` -> both modes forced `instant`; any time fields -> 400; buffer does not apply.
     - `scheduled` leg requires `*_time_from` (<= `*_time_to` if given) and not in the past (small grace).
     - Ordinary: `delivery date >= pickup date + PICKUP_DELIVERY_BUFFER_DAYS` (calendar days in Asia/Kolkata; if pickup is instant, pickup date = today).
   - One `OrderItem` per cart line: `service_id`, `pricing_type`, no weight, no quantity, `subtotal = 0`, `item_status = pending`.
   - **No Bill row.** `total_amount = 0`, `items_confirmed_at = null`.
   - Create both `Delivery` legs (existing leg-creation code, simplified; `delivery_status = unassigned`). Drop `needs_weight_machine` writes.
   - Delete the cart as today.
   - After commit call `assignmentTrigger.onOrderPlaced(order)`. In this phase it is a stub that logs; Phase 3 makes it real.
   - Remove `confirmOrder` and the draft path.
3. Share the schedule validation in `src/services/schedule-rules.js` (used again by reschedule in Phase 4).
4. Customer orders list (`getCustomerOrders`): items now show service + pricing type only; `bill` is null; add `is_express`, `pickup_mode`, `delivery_mode`, `can_cancel`, `can_reschedule` (true only when `placed`, reschedule false for Express). Final DTO polish is Phase 10.

## API contract (old -> new)

| Endpoint | Change |
|---|---|
| `POST /carts/items` | no `selections`, no `weight_kg` |
| `PATCH /carts/items/:id` | **new** switch pricing type |
| `PATCH /carts/items/:id/selections/*` | **removed** |
| `POST /orders/create_order` | new body (above), no `order_type`, response has no bill/total |
| `GET /orders` | items = services; `bill: null` until pickup |

## Tests

- Ordinary scheduled/scheduled; instant pickup + scheduled delivery; scheduled pickup + instant delivery.
- Buffer: delivery on pickup day + 1 -> 400; + 2 -> OK; buffer config changed to 0 -> OK same day.
- Express: no times; both modes `instant`; `is_express = true`; sending times -> 400.
- Mixed cart (per kg + per unit services) accepted; per_unit service without clothes rejected; inactive service rejected; empty cart rejected.
- No `Bill` row; exactly two `Delivery` rows; cart deleted; second submit of same cart -> 404.
- Legacy payload (`order_type`) rejected with a clear message.

## Exit checklist

- [ ] Migration applies on a reset test DB and on a copy of the real DB; catalogue counts unchanged (`verify-catalogue`); seed still runs.
- [ ] Order placed with no bill, two legs, `placed`.
- [ ] All tests above green; Postman folder "Phase 2".
- [ ] `onOrderPlaced` stub is called exactly once per placed order.
