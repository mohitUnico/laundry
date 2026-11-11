# Customer app API contract (partial)

This folder is the source of truth for the customer app calls agreed so far: login and signup, the homepage, the two pickup cards, Delivery Options with slots, Order Successful, tracking, the orders list, and View Details. It is a contract only. It does not change the backend. A later pass will check each operation against the routes, the business rules, and the database.

Each service is one OpenAPI 3 JSON file. Read that file for the path, the body, and the response. Names match the columns and request fields already used by the backend (`full_name`, `profile_image_url`, `is_express`, `pickup_mode`, `per_kg_price`). Money is a decimal string.

## Auth

Every operation here requires

`Authorization: Bearer <customer JWT>`

The token is the customer token. `user_id` in that token is `customer_id`.

`POST /auth/otp` and `POST /auth/sessions` are public. `POST /auth/customers` uses the registration `session_token`. After that, the customer `access_token` is used.

## Login and signup

Email is the identifier. The contact-number box on the login mock is not this contract.

| Step | Contract | Result |
|---|---|---|
| Enter email, Get OTP | `POST /api/v1/auth/otp` | Code is emailed. Six digits. |
| Enter OTP | `POST /api/v1/auth/sessions` | Existing customer: tokens, then homepage. New email: `session_token` only. |
| First name, last name, contact number | `POST /api/v1/auth/customers` | Stored as `full_name` and `phone`. Returns the customer tokens. |
| Profile photo | `POST /api/v1/customer-info/profile-image` | Optional. Skip makes no call. |
| Allow location, Done | `POST /api/v1/customer-info/addresses` | Required before the homepage for a new customer. |

## What the homepage calls

| Screen need | Contract | Why it is shaped this way |
|---|---|---|
| My profile | `GET /api/v1/customer-info/profile` | One customer. Profile photo is `profile_image_url`. |
| Address dropdown | `GET /api/v1/customer-info/addresses` | The phone keeps the selected address. There is no "current address" API. `is_default` is only the suggested start. The chosen ids go out on the order as `pickup_address_id` and `delivery_address_id`. |
| Notifications | `GET /api/v1/notifications` | One list. `count` is the badge. A second count call is not needed. |
| Coupons, view only | `GET /api/v1/coupons` | Customer can read. This contract does not include create, edit, or delete. Display name is `description`. The table has no `name` column. |
| Categories, services, cloth prices, per-kg prices | `GET /api/v1/catalog` | One catalogue. The app stores it locally and does not refetch it on every screen. |
| Pickup cards, or the cart, become an order | `POST /api/v1/orders` | One create for both paths. A pickup card sends no `cart_id` and the order has no service lines. The cart path sends `cart_id`. Order Successful is this response. |
| Schedule bottom sheet | `GET /api/v1/slots` | Daily slot template with `status`, plus `booking_horizon_days` and `server_time` for the date chips. |
| Fees and buffers | `GET /api/v1/config` | `delivery_fee` and `express_fee` before a bill exists, and the two buffer days. |
| Address form | `POST` / `PATCH /api/v1/customer-info/addresses` | The pin must be inside `SERVICE_AREA_KM`, else `OUTSIDE_SERVICE_AREA`. |
| Map tracking, opens after Order confirmed | `GET /api/v1/orders/{orderId}/tracking` | Answers from `placed` (`finding_partner`) through `delivered`. |
| All, Active and Completed orders | `GET /api/v1/orders?status=all\|active\|completed` | One list. Every row has `card_type` (`upcoming_pickup`, `in_progress`, `delivered`) so the app does not re-derive the card. See "Orders list cards" below. |
| View Details | `GET /api/v1/orders/{orderId}` | Items, both addresses, and `bill`. |
| Change Schedule | `PATCH /api/v1/orders/{orderId}` | After place, before pickup is assigned (`order_status` is `placed`). Express orders too. Sends mode, `date` and `slot_id` per leg. The card changes the pickup leg only; delivery follows automatically when the buffer would break (`delivery_shifted`). |
| Cancel | `POST /api/v1/orders/{orderId}/cancel` | After place, before pickup is assigned, with a reason (the "Are you sure?" pop-up holds the reason options). |
| Invoice | `GET /api/v1/orders/{orderId}/invoice` | The bill. Not a second document and not a PDF. |

## Fields from the place-order brief

| Brief | Contract field |
|---|---|
| isExpressType | `is_express` |
| addresses.pickupAddress | `pickup_address_id` |
| addresses.deliveryAddress | `delivery_address_id` |
| typeOfPickup instant/scheduled | `pickup_mode` |
| pickupInterval, when scheduled | `pickup_date` and `pickup_slot_id` |
| typeOfDelivery instant/scheduled | `delivery_mode` |
| deliveryInterval, when scheduled | `delivery_date` and `delivery_slot_id` |
| instructions | `special_instructions` |
| cart (cart path only) | `cart_id`, optional |

`is_express: true` is queue priority, a badge and the express fee. It does not change the pickup or delivery modes, and any mix of instant and scheduled is allowed on an Express order too.

A scheduled leg needs its `*_date` and `*_slot_id`; an instant leg must send neither. The client never sends times. The server derives `*_time_from` and `*_time_to` from the slot (IST) and returns them. It rejects an unknown slot (`SLOT_NOT_FOUND`), a slot that is `too_busy` or `closed` (`SLOT_TOO_BUSY`, `SLOT_CLOSED`), a slot that has already started (`SLOT_STARTED`), a date beyond the booking horizon (`OUTSIDE_BOOKING_HORIZON`), and a buffer violation (`BUFFER_VIOLATION`). The delivery calendar date cannot be earlier than the pickup date plus the buffer: `EXPRESS_BUFFER_DAYS` (1) for an Express order, `PICKUP_DELIVERY_BUFFER_DAYS` (2) otherwise.

Placing an order does not create a bill. `bill` is `{ "generated": false }` and `total_amount` is `"0.00"` until the pickup partner confirms the door count. View Details and the invoice use that same object. After the bill exists, `generated` is `true` and the money fields are the `bills` columns: `subtotal`, `delivery_fee`, `express_fee`, `tax_amount`, `discount`, `final_amount`, `payment_status`.

## What the screens do not call

The phone does not hard-code slots. The slot list and each slot's status come from `GET /slots`. The date chips are built on the phone from `server_time` and `booking_horizon_days`. The server stores `pickup_slot_id`, `pickup_date` and the derived `pickup_time_from` / `pickup_time_to`, and the same three for delivery.

There is no handling fee column. Delivery Charges and the later Pickup Fee plus Delivery Fee on the bill are the one `delivery_fee`. Laundry Charges stay empty until `bill.generated` is true.

`#LD12345` is not stored. The id is `order_id`. The app can format it.

The bring-it-back row labelled Express on Delivery Options is `delivery_mode: "instant"`. The Express toggle is the separate flag `is_express`, which has no effect on either mode.

An order placed from a pickup card has no service lines until the pickup partner records the door count. `items` is `[]`, `item_count` is `null` and `services` is `[]`. The app shows the title Laundry pickup. On View Details before pickup (`placed` / `pickup_assigned`), Items Summary is the placeholder "Order items will be updated after pickup" and Bill Summary is "Bill will be generated after pickup is done" (`bill.generated` is false). After the door count, `GET /orders/{orderId}` returns `items` with `category_id` / `category_name` so the app can draw category → service → cloth, and a brief Bill Summary that expands on tap into a detailed sheet with the same hierarchy plus fees.

Tracking opens right after Order confirmed, so `GET /orders/{orderId}/tracking` answers from `placed`. `tracker_step` is `finding_partner` (placed, no partner card or live pin, map pin at the pickup address), then `out_for_pickup`, `pickup_done`, `in_process`, `ready`, `out_for_delivery`, `delivered`. A cancelled order returns `409 ORDER_CANCELLED`.

Cancel and schedule change are allowed only in that window: the order is `placed`, and no pickup partner has been assigned. `can_cancel` and `can_reschedule` are false from `pickup_assigned` onward. Express can be cancelled and rescheduled in that window. A schedule or address change on `PATCH /orders/{orderId}` uses the same window. Once a bill exists, both flags are already false.

`status=all` is active plus delivered. `status=completed` is `delivered` only. Cancelled orders are on none of the tabs for now.

## Orders list cards

`GET /orders` rows carry `card_type`. The screen draws one card per row.

| `card_type` | `order_status` | Header | Content | Buttons |
|---|---|---|---|---|
| `upcoming_pickup` | `placed` | Upcoming Pickup | `pickup_date` + `pickup_slot.label` (or "Instant pickup" when `pickup_mode` is `instant`), pickup address | Change Schedule, Cancel. Tapping the card opens View Details. |
| `upcoming_pickup` | `pickup_assigned` | Upcoming Pickup | Same | Same buttons. Tapping either opens a popup ("Order cannot be cancelled" / "Schedule cannot be changed", with "Pickup partner has already started."). `can_cancel` and `can_reschedule` are false. |
| `in_progress` | `picked_up` through `out_for_delivery` | In progress | Short id, `title`, count/weight line, pickup date and slot, price from `bill.final_amount` | View details, Track on map |
| `delivered` | `delivered` | Delivered | Same as in progress | View details |

- `is_express` puts the Express chip at the top of every card type.
- `title` is `Mixed` for more than one service line, otherwise the service name. Before the door count (`services` is empty) it is `Laundry pickup`, which only happens on `upcoming_pickup`.
- The line under the title is `item_count` and `total_weight_kg`: `6 Items`, `3.5 kg`, or `6 Items - 3.5 kg`.
- Row order is fixed on the server: upcoming pickups (soonest first), then in progress, then delivered (newest first).
- Change Schedule opens the schedule sheet with `pickup_date` and `pickup_slot.slot_id` preselected in green. After the customer picks another date or slot the old one turns red and the new one is green. Confirm sends `PATCH /orders/{orderId}` with the pickup leg. If the delivery has to move, the response has `delivery_shifted: true` and the app says so.
- Cancel opens one pop-up, "Are you sure you want to cancel?", with the reason options and Yes / No. Yes calls `POST /orders/{orderId}/cancel` with `reason`.

## Files

- `auth.openapi.json`
- `profile.openapi.json`
- `addresses.openapi.json`
- `notifications.openapi.json`
- `coupons.openapi.json`
- `catalog.openapi.json`
- `config.openapi.json`
- `slots.openapi.json`
- `orders.openapi.json`

Related contracts: `../admin/slots.openapi.json` (slot template and status, written by the owner) and `../staff/door.openapi.json` (the pickup partner's door count, which fills in the lines an order from a pickup card does not have).

Where today's route or response names differ, the operation has `x-current`. That note is for the verification pass. The contract path and field names above are the ones to build and test against.

Admin create and replace for category, service, and cloth images is `../admin/catalog.openapi.json`. Those routes take the image file and store the Cloudinary URL.
