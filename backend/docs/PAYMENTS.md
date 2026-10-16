# Payments

Customers cannot set a bill to paid. `POST /api/v1/payments/orders/:orderId/process` returns `410 PAYMENT_FLOW_CHANGED`.

## Provider

`src/services/payments/mock.provider.js` implements `createIntent`, `verifyWebhook`, and `fetchStatus`. A real PSP replaces that module. The mock is refused in production on the dev complete endpoint.

`POST /api/v1/payments/orders/:orderId/pay-intent` creates one live attempt for `bill.final_amount`. A repeat call returns that attempt. The webhook is `POST /api/v1/payments/webhook/mock` with header `x-mock-signature` (HMAC-SHA256 of the raw body, secret `PAYMENT_WEBHOOK_SECRET` or `mock-webhook-secret`).

Success sets `payment_status = completed` and `payment_method = upi` only if the bill is still pending. A duplicate webhook is ignored. If cash already won, the attempt is marked succeeded with `failure_reason = refund_required` and the bill stays cash.

## Coupon

`POST` and `DELETE /api/v1/payments/orders/:orderId/coupon` while the bill is unpaid and no attempt is open. Discount is capped so `final_amount` is at least 1.00. Usage counts paid bills only.

## Cash and delivered

`POST /api/v1/delivery-staff-app/orders/:orderId/record-cash` is the drop captain only, while `out_for_delivery`, and only after the latest attempt is `failed`, `expired`, or `cancelled`.

`POST .../mark-delivered` needs that captain, status `out_for_delivery`, a completed bill, and one photo.
