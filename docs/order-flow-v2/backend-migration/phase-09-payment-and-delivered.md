# Phase 9: Payment and delivered

**Size:** L  **Depends on:** 5, 8  **Migration:** `v2_p09_payments`

## Goal

Customer pays the bill (optional coupon, UPI intent via a provider interface, mock provider for now), captain records cash only after a failed UPI, and **Mark delivered** needs payment completed plus one drop photo.

Spec: Part 5 (P5.10 to P5.13), Part 3 section on Bill, diagrams 4.6, 5.10.

## Schema changes

```prisma
enum PaymentAttemptStatus { initiated pending succeeded failed cancelled expired }

model PaymentAttempt {
  attempt_id       Int      @id @default(autoincrement())
  order_id         Int
  bill_id          Int
  provider         String   @db.VarChar(30)       // mock | razorpay | ...
  provider_ref     String?  @db.VarChar(100)      // gateway order/txn id
  idempotency_key  String   @unique @db.VarChar(100)
  amount           Decimal  @db.Decimal(10,2)
  status           PaymentAttemptStatus @default(initiated)
  intent_payload   Json?                          // UPI deep link / params
  failure_reason   String?
  created_at       DateTime @default(now())
  updated_at       DateTime @updatedAt
  @@index([order_id, status])
}
```

`Bill.coupon_id/coupon_code/payment_method/cash_recorded_by` were added in Phase 5. No new `Delivery` column is needed: the drop proof stays in the existing `drop_proof` JSON (single photo).

## Tasks

1. **Provider interface** `src/services/payments/provider.interface.js`: `createIntent({ amount, orderId, attemptId })`, `verifyWebhook(headers, rawBody)`, `fetchStatus(ref)`. `mock.provider.js` returns a fake UPI link and exposes a dev-only endpoint to force `succeeded`/`failed`. Real PSP is a later drop-in.
2. **Coupons** (existing `Coupon` table):
   - `POST /payments/orders/:orderId/coupon {code}` and `DELETE`: only when order is `picked_up` or later, bill unpaid, no pending attempt. Validate active, dates, usage limit, min order, applicable scope. Percentage/fixed with the existing cap. Discount is capped so `final_amount >= 1.00` (A8).
   - Updates `Bill.discount_amount`, `final_amount`, `coupon_id/code`; the response recomputes the totals. Usage count is incremented only when payment succeeds.
3. **Pay intent:** `POST /payments/orders/:orderId/pay-intent`
   - Allowed when the bill is unpaid and the order is `picked_up` through `out_for_delivery` (customer may pay early or at the door).
   - Creates a `PaymentAttempt` with an idempotency key (reusing a live `initiated/pending` attempt instead of creating duplicates). Amount is always `bill.final_amount` server-side.
4. **Webhook:** `POST /payments/webhook/:provider`, raw-body signature verification, idempotent by `provider_ref`. On success (single transaction): attempt `succeeded`; `Bill.payment_status = completed`, `payment_method = 'upi'`, `paid_at`; coupon usage++; `Payment`/transaction row; push "payment received"; SSE to the captain. On failure: attempt `failed`; push "payment failed".
5. **Customer status:** `GET /payments/orders/:orderId/payment-status` returns the latest attempt and the bill state (polled by the app after returning from the UPI app).
6. **Cash fallback (captain):** `POST /delivery-staff-app/orders/:orderId/record-cash`
   - Only the drop leg owner; order `out_for_delivery`; **only if the latest attempt is `failed|expired|cancelled`** (A9); bill unpaid.
   - Conditional update `payment_status = pending -> completed` so a late webhook and cash cannot both win; `payment_method = 'cash'`, `cash_recorded_by`. Late successful webhook after cash: mark the attempt `succeeded` but flag `refund_required` in `failure_reason`/admin queue (log + admin metric); do not double-complete.
7. **Mark delivered:** `POST /delivery-staff-app/orders/:orderId/mark-delivered` multipart with exactly **one** drop photo.
   - Guards: drop leg owner, order `out_for_delivery`, `bill.payment_status = completed`, photo present.
   - One transaction: order -> `delivered`, drop leg `completed`, `drop_proof` saved, `delivered_at`.
   - Remove the old `dropped`, `payment_pending`, `payment confirmed` ungated paths and `payment_confirmed_at` writers.
8. Replace the old customer `processPayment` (410 since Phase 5) with the new endpoints; remove `PaymentStatus` writes from customer routes entirely.

## API contract

| Method | Path | Who |
|---|---|---|
| POST/DELETE | `/payments/orders/:orderId/coupon` | customer |
| POST | `/payments/orders/:orderId/pay-intent` | customer |
| GET | `/payments/orders/:orderId/payment-status` | customer |
| POST | `/payments/webhook/:provider` | PSP (signature) |
| POST | `/delivery-staff-app/orders/:orderId/record-cash` | drop captain |
| POST | `/delivery-staff-app/orders/:orderId/mark-delivered` | drop captain, 1 photo |

## Tests

- Coupon: valid, expired, over usage, below minimum, percentage cap, discount floor at 1.00, remove coupon.
- Pay intent idempotency: repeated calls return the same live attempt; changing the coupon after an intent exists -> 409 until that attempt is cancelled.
- Webhook: bad signature 401; duplicate delivery processed once; success completes bill exactly once; failed leaves bill unpaid.
- Cash: before any attempt -> 409; after failed attempt -> OK; after succeeded -> 409; parallel webhook + cash -> exactly one completes.
- Mark delivered: unpaid -> 409; no photo -> 400; wrong captain -> 403; success sets all fields; repeated call idempotent.
- Customer can never set payment status (no endpoint left).
- Full happy path including payment up to `delivered` on mock provider.

## Exit checklist

- [ ] Payment provider is behind the interface; mock works in dev and tests only.
- [ ] Webhook signature and idempotency tested.
- [ ] `delivered` unreachable without payment and photo.
- [ ] Postman folder "Phase 9".
