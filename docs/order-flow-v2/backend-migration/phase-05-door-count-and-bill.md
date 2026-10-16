# Phase 5: Door count, drafts, per-service photo, Mark as picked up, bill

**Size:** L  **Depends on:** 3  **Migration:** `v2_p05_door_count_bill`

## Goal

The assigned pickup partner counts or weighs each booked service at the door, attaches one photo per service, autosaves a server draft, and **Mark as picked up** writes the bill. The customer can view the bill but cannot pay it.

Spec: Part 3 (P3.1, P3.3, P3.4, P3.11), diagrams 4.2, 5.5, 5.6.

## Schema changes

```prisma
model OrderItem {
  photo_url String? @db.VarChar(500)      // one per service
}
model OrderItemSelection {
  unit_price Decimal? @db.Decimal(10,2)   // price snapshot written at confirm (fixes F8)
}
model Bill {
  express_fee    Decimal  @default(0) @db.Decimal(10,2)
  coupon_id      Int?
  coupon_code    String?  @db.VarChar(255)
  payment_method String?  @db.VarChar(50)  // null until paid (was 'pending' string)
  cash_recorded_by String?                  // staff_id of captain (Phase 9)
}
```

`OrderItem.unit_price` for per-kg = snapshot of `service.per_kg_price` at confirm. For per-unit it stays null; selections carry their own snapshot.

## Tasks

1. **Door read:** `GET /delivery-staff-app/orders/:orderId/door` (pickup leg owner only)
   - Booked services with `pricing_type`, draft values (`weight_kg`, `selections`, `photo_url`), per-service `isComplete`.
   - For per-unit services: that service's active catalogue clothes with `per_unit_price` (so the app can show the old customer item list for that service only).
   - Order-level: `itemsConfirmed`, `canMarkPickedUp` (all services complete and not confirmed), and `primaryAction = { key: MARK_PICKED_UP | SUBMIT_TO_CM | WAITING_FOR_CM, enabled }` (the one-button state machine; SUBMIT/WAITING keys are completed in Phase 6).
2. **Draft save:** `PATCH /delivery-staff-app/orders/:orderId/door/services/:orderItemId`
   - Body `{ weight_kg }` for per-kg, or `{ selections: [{ cloth_id, quantity }] }` for per-unit (replaces the set; quantity 0 removes a line). Optional `photo_url`.
   - Guards: caller owns the active pickup leg; order is `pickup_assigned`; `items_confirmed_at IS NULL`; cloth belongs to that service and is active; weight > 0 and sane upper bound; quantity integer >= 1.
   - Keeps `items_confirmed_at = null`, no bill.
3. **Photo:** `POST /delivery-staff-app/orders/:orderId/door/services/:orderItemId/photo` (multipart, camera or gallery) using the existing Cloudinary service; stores `photo_url`; returns it. Photos are never stored as bytes in Postgres.
4. **Mark as picked up:** `POST /delivery-staff-app/orders/:orderId/door/confirm`
   - One transaction with a row lock on the order.
   - Every order item must be complete (per-kg: weight > 0; per-unit: at least one selection with quantity >= 1; photo present). Otherwise 409 `DOOR_INCOMPLETE` listing the missing services.
   - Compute lines: per-kg `weight_kg x service.per_kg_price`; per-unit `sum(quantity x cloth.per_unit_price)`; write snapshots to `OrderItem` and `OrderItemSelection`.
   - Create `Bill`: `subtotal`, `delivery_fee = config.DELIVERY_FEE`, `express_fee = is_express ? config.EXPRESS_FEE : 0`, `discount = 0`, `tax_amount = 0`, `final_amount = subtotal + fees`, `payment_status = pending`, `payment_method = null`. Fee values are **snapshotted** into the bill.
   - Set `items_confirmed_at`, `order.total_amount = final_amount`, status `picked_up` via `assertTransition`; pickup leg row `pickup_status = picked_up`, `pickup_time = now`.
   - Idempotent: a repeat call returns the existing result with 200.
   - Customer push `picked_up` (FCM/WhatsApp).
5. **Customer bill view:** `GET /payments/orders/:orderId/bill` and `/invoice` rewritten for the new line structure (per service: per-kg weight and price, or per-unit item lines with qty x snapshot price; fees; discount; total; `payment_status`; `canPay = false` for now).
6. **Disable self-payment (fixes F14):** `POST /payments/orders/:orderId/process` returns 410 `PAYMENT_FLOW_CHANGED` until Phase 9 replaces it.
7. **Remove:** per-kg weights endpoints for delivery staff and CM (`GET|PATCH .../items/weights`), CM `generate-invoice` and `generateInvoice`, delivery action `picked_up` on the pickup leg, `mark-picked-up` single-proof endpoint. `pickup_proof` is no longer written.

## API contract

| Method | Path | Notes |
|---|---|---|
| GET | `/delivery-staff-app/orders/:orderId/door` | **new** |
| PATCH | `/delivery-staff-app/orders/:orderId/door/services/:orderItemId` | **new**, draft autosave |
| POST | `.../door/services/:orderItemId/photo` | **new** |
| POST | `/delivery-staff-app/orders/:orderId/door/confirm` | **new** = Mark as picked up |
| GET/PATCH | `/delivery-staff-app/orders/:orderId/items/weights` | **removed** |
| GET/PATCH | `/staff-app/collection-manager/orders/:orderId/items/weights` | **removed** |
| POST | `/staff-app/collection-manager/orders/:orderId/generate-invoice` | **removed** |
| POST | `/payments/orders/:orderId/process` | **disabled (410)** |

## Tests

- Draft save, reload (GET door returns saved values), overwrite, clear a line.
- Confirm with one service missing -> 409 listing it; missing photo -> 409.
- Bill maths: mixed order (2 per-kg + 2 per-unit services) with decimals, assert exact `subtotal`, fees, `final_amount`; Express adds `EXPRESS_FEE`; ordinary does not.
- Fee snapshot: change `DELIVERY_FEE` after confirm -> existing bill unchanged. Change a cloth price after confirm -> invoice unchanged.
- Edits after confirm -> 409; confirm twice -> same bill, one row.
- Guards: other staff, wrong order status, cloth from another service, negative weight.
- Customer sees the bill; `canPay` false; old `process` endpoint returns 410.
- Bill row count is exactly 1 per order even under parallel confirm calls.

## Exit checklist

- [ ] Draft -> confirm -> bill works end to end on a reset DB.
- [ ] Old weights/invoice endpoints removed, 410 on self-payment.
- [ ] Money maths tests green (use `Prisma.Decimal`, never JS floats).
- [ ] Postman folder "Phase 5".
