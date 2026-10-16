# API reference (order flow v2)

Base path `/api/v1`. Auth is a Bearer JWT. Customer routes use role `customer`. Staff routes use `delivery_staff`, `collection_manager`, `distribution_manager`, or `service_man`. Admin routes use `admin` or `owner`.

## Customer

| Method | Path |
|---|---|
| GET | `/catalog/pricing` |
| GET | `/orders?bucket=active\|history` |
| GET | `/orders/:orderId` |
| GET | `/orders/:orderId/tracking` |
| POST | `/orders/:orderId/cancel` |
| PATCH | `/orders/:orderId/schedule` |
| GET | `/payments/orders/:orderId/bill` |
| POST/DELETE | `/payments/orders/:orderId/coupon` |
| POST | `/payments/orders/:orderId/pay-intent` |
| GET | `/payments/orders/:orderId/payment-status` |

## Pickup partner

| Method | Path |
|---|---|
| GET | `/delivery-staff-app/orders/:orderId/door` |
| PATCH | `/delivery-staff-app/orders/:orderId/door/services/:orderItemId` |
| POST | `.../door/services/:orderItemId/photo` |
| POST | `.../door/confirm` |
| POST | `.../submit-to-cm` |

## Drop captain

| Method | Path |
|---|---|
| POST | `/delivery-staff-app/orders/:orderId/record-cash` |
| POST | `/delivery-staff-app/orders/:orderId/mark-delivered` |

## Plant

| Method | Path |
|---|---|
| GET | `/staff-app/collection-manager/orders/incoming` |
| POST | `.../orders/:orderId/mark-received` |
| POST | `.../orders/:orderId/submit-to-services` |
| GET | `/staff-app/service-man/queue` |
| PATCH | `/staff-app/service-man/queue/:queueId/status` |
| GET | `/staff-app/distribution-manager/orders/in-plant` |
| GET | `.../ready-to-dispatch` |
| GET | `.../history` |
| GET | `.../orders/:orderId/assignable-staff` |
| POST | `.../orders/:orderId/assign-drop` |

## Admin

| Method | Path |
|---|---|
| GET | `/admin/services` |
| POST | `/admin/services/:serviceId/service-man/release` |
| GET | `/admin/services/assignment-health` |
| GET/PUT | `/admin/config` |

Cart lines include `available`. Placing an order with an unavailable service returns `409 SERVICE_UNAVAILABLE`. Deleting a catalogue row that an order uses returns `409 IN_USE_DEACTIVATE_INSTEAD`.
