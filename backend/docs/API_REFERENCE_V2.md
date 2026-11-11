# API reference (order flow v2)

Base path `/api/v1`. Auth is a Bearer JWT. Customer routes use role `customer`. Staff routes use `delivery_staff`, `collection_manager`, `distribution_manager`, or `service_man`. Admin routes use `admin` or `owner`.

Request and response shapes are in [api-contracts/](api-contracts/). Routes marked (new) or (changed) belong to the booking redesign and are specified there but not built yet.

## Customer

| Method | Path |
|---|---|
| GET | `/catalog/pricing` |
| GET | `/slots` (new) |
| POST | `/orders/create_order` (changed: `cart_id` optional, `date + slot_id` per scheduled leg, Express is priority only) |
| POST/PATCH | `/customer-info/addresses` and `/customer-info/addresses/:addressId` (changed: `SERVICE_AREA_KM` check) |
| GET | `/orders?bucket=active\|history` |
| GET | `/orders/:orderId` |
| GET | `/orders/:orderId/tracking` (changed: answers from `placed`, `tracker_step`) |
| POST | `/orders/:orderId/cancel` |
| PATCH | `/orders/:orderId/schedule` (changed: `date + slot_id`, Express allowed) |
| GET | `/payments/orders/:orderId/bill` |
| POST/DELETE | `/payments/orders/:orderId/coupon` |
| POST | `/payments/orders/:orderId/pay-intent` |
| GET | `/payments/orders/:orderId/payment-status` |

## Pickup partner

| Method | Path |
|---|---|
| GET | `/delivery-staff-app/orders/:orderId/door` (changed: whole catalogue, locked cart lines) |
| PATCH | `/delivery-staff-app/orders/:orderId/door/services/:serviceId` (changed: keyed by service, creates the line) |
| DELETE | `.../door/services/:serviceId` (new: removes a line he added) |
| POST | `.../door/services/:serviceId/photo` (changed: keyed by service) |
| POST | `.../door/confirm` (changed: at least one line) |
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
| GET/PUT | `/admin/config` (new keys `EXPRESS_BUFFER_DAYS`, `SERVICE_AREA_KM`) |
| GET/POST | `/admin/slots` (new) |
| PATCH | `/admin/slots/:slotId` (new) |
| PUT | `/admin/slots/:slotId/status` (new) |
| PUT | `/admin/slot-settings` (new) |

Cart lines include `available`. Placing an order with an unavailable service returns `409 SERVICE_UNAVAILABLE`. Deleting a catalogue row that an order uses returns `409 IN_USE_DEACTIVATE_INSTEAD`.
