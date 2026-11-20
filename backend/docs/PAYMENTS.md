# Payments

Customers cannot set a bill to paid. `POST /api/v1/payments/orders/:orderId/process` returns `410 PAYMENT_FLOW_CHANGED`.

## Razorpay

`src/services/payments/razorpay.provider.js` creates the Razorpay order, verifies the Checkout signature, and verifies the webhook.

`POST /api/v1/payments/orders/:orderId/pay-intent` creates one live attempt for `bill.final_amount`. A repeat call returns that attempt. The customer app opens Checkout with the public key and the Razorpay order id.

`POST /api/v1/payments/orders/:orderId/razorpay/confirm` checks the Checkout signature, fetches the payment from Razorpay, and settles the bill only when the order id and amount match.

`POST /api/v1/payments/webhook/razorpay` checks `X-Razorpay-Signature` with `RAZORPAY_WEBHOOK_SECRET`. `payment.captured` settles the bill. `payment.failed` leaves it unpaid.

Success sets `payment_status = completed` only if the bill is still pending. A duplicate webhook is ignored. If cash already won, the attempt is marked succeeded with `failure_reason = refund_required` and the bill stays cash.

## Coupon

`POST` and `DELETE /api/v1/payments/orders/:orderId/coupon` while the bill is unpaid and no attempt is open. Discount is capped so `final_amount` is at least 1.00. Usage counts paid bills only.

## Cash and delivered

`POST /api/v1/delivery-staff-app/orders/:orderId/record-cash` is the drop captain only, while `out_for_delivery`, and only after the latest attempt is `failed`, `expired`, or `cancelled`.

`POST .../mark-delivered` needs that captain, status `out_for_delivery`, a completed bill, and one photo.
