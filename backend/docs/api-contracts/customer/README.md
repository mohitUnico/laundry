# Customer app API contract (partial)

This folder is the source of truth for the customer app calls agreed so far: login and signup, the homepage, Delivery Options, Order Successful, the orders list, and View Details. It is a contract only. It does not change the backend. A later pass will check each operation against the routes, the business rules, and the database.

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
| Cart becomes an order | `POST /api/v1/orders` | One create. The cart is `cart_id`. Order Successful is this response. |
| Delivery and express quotes | `GET /api/v1/config` | `delivery_fee` and `express_fee` before a bill exists. |
| Active and Completed orders | `GET /api/v1/orders?status=active\|completed` | Upcoming Pickup is one row in `active`, not its own call. |
| View Details | `GET /api/v1/orders/{orderId}` | Items, both addresses, and `bill`. |
| Change Schedule | `PATCH /api/v1/orders/{orderId}` | After place, before pickup is assigned (`order_status` is `placed`). Not for Express. |
| Cancel | `POST /api/v1/orders/{orderId}/cancel` | After place, before pickup is assigned, with a reason. |
| Invoice | `GET /api/v1/orders/{orderId}/invoice` | The bill. Not a second document and not a PDF. |

## Fields from the place-order brief

| Brief | Contract field |
|---|---|
| isExpressType | `is_express` |
| addresses.pickupAddress | `pickup_address_id` |
| addresses.deliveryAddress | `delivery_address_id` |
| typeOfPickup instant/scheduled | `pickup_mode` |
| pickupInterval, when scheduled | `pickup_time_from`, optional `pickup_time_to` |
| typeOfDelivery instant/scheduled | `delivery_mode` |
| deliveryInterval, when scheduled | `delivery_time_from`, optional `delivery_time_to` |
| instructions | `special_instructions` |

`is_express: true` means both legs are instant. Do not send time fields on an express order.

A scheduled leg needs its `*_time_from`. The delivery calendar date cannot be earlier than the pickup date plus `PICKUP_DELIVERY_BUFFER_DAYS`. Express skips that buffer.

Placing an order does not create a bill. `bill` is `{ "generated": false }` and `total_amount` is `"0.00"` until the pickup partner confirms the door count. View Details and the invoice use that same object. After the bill exists, `generated` is `true` and the money fields are the `bills` columns: `subtotal`, `delivery_fee`, `express_fee`, `tax_amount`, `discount`, `final_amount`, `payment_status`.

## What the screens do not call

The date chips and the 30-minute slots (5:00–9:00) are built on the phone. The server stores `pickup_time_from` / `pickup_time_to` and `delivery_time_from` / `delivery_time_to`. There is no slots resource.

There is no handling fee column. Delivery Charges and the later Pickup Fee plus Delivery Fee on the bill are the one `delivery_fee`. Laundry Charges stay empty until `bill.generated` is true.

`#LD12345` is not stored. The id is `order_id`. The app can format it.

The bring-it-back row labelled Express on Delivery Options is `delivery_mode: "instant"`. Express Wash is the separate flag `is_express`, and that flag makes both legs instant.

Cancel and schedule change are allowed only in that window: the order is `placed`, and no pickup partner has been assigned. `can_cancel` and `can_reschedule` are false from `pickup_assigned` onward. Express can be cancelled in that window, and it cannot be rescheduled. A schedule or address change on `PATCH /orders/{orderId}` uses the same window. Once a bill exists, both flags are already false.

`status=completed` is `delivered` only. Cancelled orders are not on that tab.

## Files

- `auth.openapi.json`
- `profile.openapi.json`
- `addresses.openapi.json`
- `notifications.openapi.json`
- `coupons.openapi.json`
- `catalog.openapi.json`
- `config.openapi.json`
- `orders.openapi.json`

Where today's route or response names differ, the operation has `x-current`. That note is for the verification pass. The contract path and field names above are the ones to build and test against.

Admin create and replace for category, service, and cloth images is `../admin/catalog.openapi.json`. Those routes take the image file and store the Cloudinary URL.
