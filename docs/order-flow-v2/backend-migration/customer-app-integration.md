# Customer app ↔ backend

The OpenAPI files under `backend/docs/api-contracts/customer/` are the contract. The app should stop using on-device sample orders once each phase below is live.

## Phase 1 — Read orders (this pass)

- `GET /orders?status=all|active|completed` returns `card_type`, `title`, `items` (with `category_name`), `item_count`, `total_weight_kg`, and `bill`.
- Cancelled orders are omitted from all three filters.
- `prisma/seed.js` inserts demo orders for `customer@washbee.test` (instant placed, scheduled placed, pickup assigned, picked up, in progress, delivered, cancelled). Re-running the seed does not duplicate them.
- The Orders screen asks for `status=all` and renders the API rows. Local samples are only a fallback when the API call fails.

## Phase 2 — Write the order

Cancel calls `POST /orders/{orderId}/cancel`. Change Schedule calls `PATCH /orders/{orderId}/schedule` with the pickup window, and the delivery window when it has to move. Express orders can be rescheduled while `placed`. `can_reschedule` is true for every placed order, including Express.

## Phase 3 — Slots

`GET /slots` returns the daily template (open 30-minute windows, horizon from `BOOKING_HORIZON_DAYS`). The schedule sheet uses that list and falls back to the built-in windows if the call fails. Change Schedule sends the window as `pickup_time_from` / `pickup_time_to`.

## Phase 4 — Pay and track

`GET /orders/{orderId}/tracking` returns the shop, pickup, delivery and both legs from `placed` onward. A cancelled order is `409 ORDER_CANCELLED`. Pay your bill is shown only at `out_for_delivery` and calls pay-intent, then the mock complete.

## Phase 5 — Staff door count

`GET .../door` includes the catalogue. `PATCH .../door/services/{id}` accepts either an existing order-item id or a service id; a service id with no line creates the line, then saves the weight or the cloth counts. Confirm still writes the bill and moves the order to `picked_up`.

## Phase 6 — Place order

`POST /orders/create_order` accepts `is_express`, `pickup_mode`, and `delivery_mode`. It rejects `order_type`, `pickup_date`, and `delivery_date`. Express place sends no times. A scheduled leg sends `*_time_from` and `*_time_to`. `cart_id` is optional: a pickup-card order is created with no lines, and the door count adds them later. Cart checkout, the payment screen, and the schedule confirm screen all place through this body. Change Schedule on tracking and the date-time screen calls `PATCH /orders/{orderId}/schedule`.
