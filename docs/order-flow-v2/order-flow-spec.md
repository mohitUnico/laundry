# WashBee order flow v2 - spec

**Status:** current design. Complete enough to implement; code lags behind it where noted in section 13.  
**Updated:** 6 Nov 2026 (orders list cards, cancel pop-up, reschedule auto-shifts delivery; earlier: booking redesign, pickup cards, Delivery Options, admin slots).  
**How to change it:** edit the rule here, in place, so this file always describes one current flow. Git history is the record of earlier versions. Then update the diagrams and `README.md`.  
**Diagrams:** [diagrams/](diagrams/) (start with [../README.md](README.md)).  
**Interactive viewer:** [diagrams/viewer.html](diagrams/viewer.html)

---

## 0. The model in one paragraph

WashBee is **service-booked laundry, counted at the door**. The customer places an order with a pickup leg and a delivery leg (always both). The pickup partner counts and weighs the laundry at the door, photographs it, and the bill is generated from that count. A collection manager (CM) verifies and receives it, service men process it in per-service queues, a distribution manager (DM) oversees dispatch, and a captain delivers and collects payment.

```
customer places order → pickup partner counts at the door → CM verifies
  → service men process → DM dispatches → captain delivers and collects payment
```

The customer picks **no cloth items**. Whether any services are chosen up front depends on how the order was started (section 1.1).

---

## 1. Customer booking

### 1.1 Two ways to place an order

```
A. No cart
   Home: [Schedule pick up] or [Instant pick up]
     → Delivery Options → Slide to place → "Order confirmed" → Tracking
   The order is created with NO service lines.

B. With cart
   Home category tiles → services → Cart (one line per service + per kg or per unit)
     → Delivery Options → Slide to place → "Order confirmed" → Tracking
   The order is created with one service line per cart line (pricing type pre-selected).
```

- Both paths use the same Delivery Options screen and the same create-order validation. Path A sends no `cart_id`.
- The Schedule card opens Delivery Options with pickup = scheduled preselected. The Instant card opens it with pickup = instant preselected. The customer can change it.
- A cart has one line per service, priced `per_kg` or `per_unit`. The cart holds no cloth items, no counts and no weights.
- There is no itemised bill at booking. The bill appears when the pickup partner marks the order picked up (section 3).

### 1.2 Delivery Options: fields and validation

| # | Field | Rule |
|---|---|---|
| a | `is_express` | Express is **queue priority only**: a faster band in the service queue, a badge, and `EXPRESS_FEE` on the bill (section 1.5). It does not change pickup or delivery logistics. |
| b | `pickup_mode` | `instant` or `scheduled` (section 1.3). |
| b | Pickup slot | Required when scheduled: `pickup_date` + `pickup_slot_id` (section 1.4). |
| c | `delivery_mode`, delivery slot | Same shape as pickup. |
| - | Buffer | Delivery calendar date (IST) must be on or after pickup date + buffer. Ordinary orders use `PICKUP_DELIVERY_BUFFER_DAYS` (2). Express orders use `EXPRESS_BUFFER_DAYS` (1). Both are admin config. |
| d | Addresses | `pickup_address_id` and `delivery_address_id`. They can be the same or different. Both must belong to the customer. Serviceability is checked when an address is added or edited (section 1.6), not at order creation. |
| e | `special_instructions` | Optional, at most 500 characters. |
| - | `cart_id` | Optional. If sent: it must be an active cart owned by the customer, non-empty, with every line bookable. If absent: the order has no service lines. |

`order_type` is always `both`. Pickup-only and delivery-only do not exist.

### 1.3 Instant and scheduled

Pickup and delivery each have their own mode, and any mix is allowed (instant pickup with scheduled delivery, the reverse, both instant, or both scheduled).

| Leg | Instant | Scheduled |
|---|---|---|
| Pickup | The assignment job starts **immediately** on place. | The job starts at the slot start (`pickup_time_from`). |
| Delivery (drop) | The drop search starts when **all service items are completed**. | The drop search starts at `delivery_time_from`, and only if processing is already done. |

- "Instant" means "as soon as allowed". An instant delivery's calendar date is the earliest allowed date (pickup date + buffer), not necessarily today.
- A scheduled delivery whose time is still in the future when processing finishes: no search starts and the DM cannot assign. If processing finishes after the slot, the drop search starts immediately (section 6).
- Pickup and drop use the same expanding-radius engine (section 2).

### 1.4 Slots (admin-maintained)

Slots are a **daily template**, identical every day. The owner maintains it, and a slot's status applies to all days.

| Field | Meaning |
|---|---|
| `slot_id`, `label` | For example "8 - 9:30 am". |
| `period` | `morning`, `afternoon` or `evening`. Groups the chips in the schedule sheet. |
| `start_time`, `end_time` | IST wall-clock times. |
| `status` | `open`, `too_busy` or `closed`. |
| `sort_order`, `is_active` | Display order; soft remove. |

- `open` is selectable. `too_busy` and `closed` are shown **disabled** with their own label, and the backend **rejects** them. They differ only in the message.
- The backend admin API (list, create, edit, set status) comes with this design. The mart-admin screen comes later.
- The customer app reads the slot list and statuses from an API and never hard-codes them.
- A scheduled create-order or reschedule sends `date + slot_id`. The server derives `pickup_time_from/to` and `delivery_time_from/to` from the slot (IST) and stores them. It rejects: an unknown or inactive slot, a status other than `open`, a slot that has already started, a date beyond the booking horizon, and a buffer violation.

### 1.5 Express

Express is a per-order flag (`is_express`) on a normal `both` order. It does not use the `express_delivery` order type.

| Aspect | Rule |
|---|---|
| Pickup and delivery | Exactly as for an ordinary order: any mode mix, slots, rings, timeouts. |
| Buffer | `EXPRESS_BUFFER_DAYS` (1) instead of `PICKUP_DELIVERY_BUFFER_DAYS` (2). |
| Fee | `EXPRESS_FEE` (admin variable, in rupees) is added on the bill at Mark as picked up, together with the delivery fee, snapshotted. Ordinary orders: 0. |
| Service queue | One list per service, sorted `is_express DESC, assigned_at ASC`. A new Express row goes after older Express rows and before all ordinary rows. |
| Badge | One Express chip on the order card on **every** role list: customer, pickup boy, captain, CM, service man, DM. |
| After placing | Sticky: it cannot become ordinary. Cancel and reschedule follow section 1.7. |
| Service mix | Allowed on any service mix. |

### 1.6 Address serviceability

- New admin config `SERVICE_AREA_KM`: the largest allowed distance from the active laundry.
- The add-address and edit-address API rejects a pin farther than that. The app address form shows the error.
- Order creation checks only that the address belongs to the customer. Addresses saved earlier are not re-checked.

### 1.7 Cancel and reschedule

Both are allowed only **before a pickup partner is assigned** (`order_status = placed`). From `pickup_assigned` onward the Upcoming Pickup card still shows Change Schedule and Cancel; tapping either opens a popup ("Order cannot be cancelled" / "Schedule cannot be changed", with "Pickup partner has already started.") and the API rejects the call.

| Action | Rule |
|---|---|
| Cancel | Customer only, whole order only. The Cancel button opens one pop-up, "Are you sure you want to cancel?", that holds the reason options and Yes / No. A reason is required: a preset label, or free text for "Something else". The presets live in the app (not a server catalogue). Yes sets `cancelled`, stores `cancel_reason`, stops the pickup search and pending offers. A cancelled order drops off the orders list (there is no cancelled card or history tab yet). No fee and no refund (nothing is prepaid). |
| Reschedule | Customer only. No reason. Pickup and delivery can each be changed through the API; the orders list card changes the **pickup** only, and an instant pickup can be changed to scheduled. The new windows use the same slot and buffer validation as booking (section 1.2, 1.4). A running search and its offers are cancelled. If the new pickup is instant or its time has already arrived, the search starts again immediately. Otherwise it waits for the new `pickup_time_from`. |
| Delivery follows pickup | When a reschedule changes only the pickup and the delivery would break the buffer (delivery date < new pickup date + buffer), the server moves the delivery in the same write: date = new pickup date + buffer, same slot if it is open, else the first open slot. It only ever moves later. The response says `delivery_shifted` and the app tells the customer "Delivery moved to {date}". If that date is past the booking horizon (`OUTSIDE_BOOKING_HORIZON`) or has no open slot (`DELIVERY_SHIFT_UNAVAILABLE`), the whole change is rejected and nothing is saved. An instant delivery has no date, so nothing moves. If the request itself sends a delivery date, nothing is shifted and a buffer break is `BUFFER_VIOLATION`. |

---

## 2. Assignment engine (pickup and drop)

One engine serves both legs. All values are named config (section 9).

```
sliceDuration = ASSIGNMENT_TIMEOUT_MINUTES / ASSIGNMENT_RANGE_SLICES
ringKm(i)     = (i / ASSIGNMENT_RANGE_SLICES) * ASSIGNMENT_MAX_RANGE_KM      i = 1..SLICES

For slice i in 1..SLICES:
  window = ((i-1) * sliceDuration) .. (i * sliceDuration)
  notify on-shift staff whose distance to the job address is <= ringKm(i)
         and who were not already notified
If anyone accepts in any slice: stop the search. First write wins.
If the timeout ends with no accept: a manager may force-assign.
```

- **On-shift staff only** (`DeliveryStaffShift.is_active`) are notified by rings.
- Distance is **haversine on the backend**, using each staff member's current lat/lng. Staff with no known location are skipped by rings. The Flutter app owns Google Directions and the route polyline.
- **First accept wins.** Two simultaneous accepts produce one assignment (the database's first writer); the other is rejected.
- **Manager assign only after the timeout:** the CM for pickup, the DM for drop. A manager may force-assign any verified active delivery staff, on shift or not. The assigned staff member **cannot reject**, and receives an SSE "assigned to you".
- During the search, the manager's Assign button is visible but disabled. After the timeout it is enabled.
- The CM and DM staff lists show the distance to the job address.
- Example: timeout 5 min, max range 10 km, 5 slices gives 2 km in minute 1, 4 km in minute 2, and so on up to 10 km in minute 5.
- There is one timeout and **no automatic retry**.
- Pickup assignment is created for `placed` orders. A reschedule or cancel stops the search (section 1.7).

---

## 3. Pickup door count and bill

The pickup partner uses **one button** with three labels:

| When | Button |
|---|---|
| Assigned, door work not confirmed | **Mark as picked up** |
| Marked picked up, request not sent | **Submit request to CM** |
| Request sent, waiting on the CM | **Waiting for CM verification** (inactive, not tappable) |

### 3.1 What the partner sees

The partner sees **all active categories and services**.

| Order type | What is pre-selected |
|---|---|
| With cart | The services the customer chose appear already selected, with their pricing type **locked**. Each must be filled in. He may **add other services** on top. |
| No cart | Nothing. He adds every service himself and picks per kg or per unit for each. |

- A row shows a **Per unit** or **Per kg** badge. One line per service.
- Tap a service to expand it:
  - **per unit:** counts on that service's cloth items.
  - **per kg:** **one** weight for the whole service.
  - **one photo per service**, from camera or gallery.
- A service is "done" when its counts or weight and its photo are present. Mixed per-unit and per-kg orders are allowed.
- All services are finished in **this one visit**. There is no "come back tomorrow".

### 3.2 Draft (crash recovery)

On each service expander complete, the app `PATCH`es the order's service lines with `items_confirmed_at = null`, including lines the partner added. Reopening the job after an app kill restores the numbers. This is not a second product: no Drafts screen, no version history, no "save draft" button.

### 3.3 Mark as picked up

Enabled only when the order has **at least one service line** and **every** line is complete (every pre-selected line included). It:

1. writes the **bill** (section 3.4),
2. sets `items_confirmed_at`,
3. sets `order_status = picked_up`,
4. changes the button to **Submit request to CM**.

After this the item list is **not editable** and the request **cannot be cancelled**. The order stays on the pickup partner's list.

### 3.4 Bill

| Line | Formula |
|---|---|
| Per-kg service | `weight_kg` (one per service) x `service.per_kg_price` |
| Per-unit service | sum of `quantity` x `clothes_item.per_unit_price` |
| Delivery fee | `DELIVERY_FEE`, an admin-editable flat value added automatically |
| Express fee | `EXPRESS_FEE` when `is_express`, else 0 |
| Coupon | One coupon at payment (section 7) |
| Order total | service lines + delivery fee + express fee - coupon |

- Prices and fees are **snapshotted** at Mark as picked up. Later price edits never change an existing bill.
- Only the **customer** sees the bill. No CM or admin notification.
- The customer can **view** the bill from `picked_up`. They **cannot pay** until `out_for_delivery` (section 7).
- There is no minimum weight.

### 3.5 Photos

Photos go through the existing upload pipeline (Cloudinary), with the URL stored on the service line. Image bytes are never stored in PostgreSQL.

---

## 4. Collection manager handshake

```
picked_up                Mark as picked up. Bill written. Button: Submit request to CM.
submitted_to_cm          Request sent (any time after Mark as picked up). Button: Waiting for CM verification.
received_by_collection   CM taps Verified and Received. The pickup leg completes.
```

- The partner can send the request any time after Mark as picked up (at the door, in transit, or at the laundry). He cannot skip it.
- **CM incoming list:** orders yet to be picked up (`placed`, `pickup_assigned`) **and** picked-up orders (`picked_up`, `submitted_to_cm`).
- **Verified and Received** works **only** from `submitted_to_cm`. Seeing an order does not allow marking it received.
- The pickup `Delivery` row is completed on CM receive, not on the request.
- The pickup partner's list shows `pickup_assigned`, `picked_up`, `submitted_to_cm`. The row disappears after the next **pull-to-refresh** once the order is `received_by_collection`.
- This handshake is plain HTTP status writes. **No** Redis or queue.
- The CM does not generate an invoice (the bill exists from the door). CM refuse, recount and cancel-request are out of scope.

---

## 5. Plant: service queues

```
CM list of received orders (received_by_collection)
  → Send to service queue
  → order leaves the CM list (it stays in CM history)
  → order_status = submitted_to_services
  → one queue row per booked service line, auto-assigned to that service's service man
```

- **One service man per service**, and one service per service man (`Staff.service_id` is unique). The CM does not choose the man.
- If a service has no service man, **send to service queue fails** (`409 NO_SERVICE_MAN`). Lines are never silently skipped.
- **Queue grain:** one row per service line (an `OrderItem`, which has nested cloth selections), not one row per cloth.
- **Sort:** `ORDER BY is_express DESC, assigned_at ASC`. New ordinary rows sit at the bottom of the ordinary band.
- **Any pending row can be started.** Several rows can be in progress at once. Starting a row does not change its `assigned_at`.
- **Actions: In progress and Completed only.** No "mark for later".
- The service man's screen shows each row's assigned time.
- **No SSE, no Redis, no extra queue.** While the queue screen is visible, the app polls the same list GET every `SERVICE_QUEUE_POLL_SECONDS` (120; 60 is also allowed). Pull-to-refresh works in between. A cold start is just that GET.
- First item in progress sets `services_in_progress`. When the **last** item completes, the order becomes `services_completed`.

---

## 6. Drop assignment and the DM lists

```
Any service item completed
  → the order appears on the DM in-plant list (expand: all items, completed or pending)

All service items completed
  → order_status = services_completed
  → customer tracker: Ready
  → the drop search starts according to delivery_mode (section 1.3)
```

| Situation | Auto search | DM Assign button |
|---|---|---|
| Items still pending (in-plant) | Off | Off (expand only) |
| All done + instant | On immediately | Visible, **disabled** until the timeout |
| All done + scheduled in the future | Off | Visible, disabled, "Available from {time}" |
| All done + scheduled time reached or already past (including a late plant) | On immediately | Visible, disabled until the timeout |
| Timeout with no accept | Stopped | **Enabled** (manual, cannot reject) |

- When a captain accepts, or the DM force-assigns, the order becomes **`out_for_delivery` immediately**. There is no start-delivery gate.
- The customer sees the captain's **name, phone and photo**. The phone is display only (no `tel:`). Call and message icons are placeholders.
- The live map shows the captain's pin and **one** Directions path drawn at assignment. If the pin leaves the path, Directions refreshes at most once every 2 minutes. There is no snap-to-road or turn-by-turn.
- DM lists:

| List | What is on it |
|---|---|
| **In-plant** | At least one item completed, not all (`services_in_progress`). Pending items are shown in an inactive colour. No Assign. |
| **Ready to dispatch** | All items done, no captain yet (`services_completed`). Assign visible: disabled during the search, "Available from {time}", or enabled after the timeout. |
| **History** | Captain assigned onward. Shows delivered or not (`out_for_delivery` vs `delivered`). |

- The DM does not verify an order before dispatch. After assignment the order leaves ready-to-dispatch.

---

## 7. Payment and delivered

Payment lives on **`Bill`**. Delivery lives on **`Order.order_status`**. They are separate fields.

```
order_status becomes out_for_delivery
  Customer Pay unlocks (the bill was already viewable)
    optional: ONE code from the existing coupons table → Bill.discount + final_amount
    primary: PSP UPI intent → any UPI app → back to WashBee
      success → bill.payment_status = completed, payment_method = upi
               paid shown everywhere at once, no captain involved
      fail    → still unpaid; the customer can retry UPI
               OR the captain taps Paid in cash
                 → bill.payment_status = completed, payment_method = cod
                 shown everywhere, including the customer app
  Captain: Mark as delivered + ONE photo (drop_proof)
    enabled only if bill.payment_status = completed
    → order_status = delivered
```

| Event | Payment (`Bill`) | Order status |
|---|---|---|
| `out_for_delivery` | pending, Pay unlocked | `out_for_delivery` |
| UPI success | completed everywhere | still `out_for_delivery` |
| Cash recorded | completed everywhere | still `out_for_delivery` |
| Captain: photo + delivered | unchanged | `delivered` |

- **One coupon per payment**, from the existing `Coupon` table. No second promotions table. Never a free-typed string. Validity, minimum order value, usage limits and caps are enforced at apply time, and the final amount stays at least 1.00.
- UPI goes through a **PSP merchant account** (Razorpay, PhonePe or Cashfree style) so the app gets a real success or failure. The payee is the merchant, never the captain's personal UPI.
- **Cash is a fallback only.** It is allowed only after a UPI attempt has failed, expired or been cancelled. The captain records it, the customer cannot declare cash, and it is not recorded if UPI already completed.
- **Delivered is blocked until payment is completed.** UPI success does not deliver the order.
- Card, wallet, netbanking and COD as a first-class checkout are not offered.
- The old `payment_pending` order status is not used.

---

## 8. Customer app surfaces

### 8.1 Navigation

- **Bottom nav:** Home, Orders, Cart, Pricing. There is no Account tab.
- **Account** is the top-left profile photo on Home. Orders, Cart, Pricing and Tracking do not show that avatar.

### 8.2 Tracker (six steps)

```
Out for pickup → Pickup done → In process → Ready → Out for delivery → Delivered
```

| DB status | Tracker |
|---|---|
| `placed` | Before the first step: "finding a partner". No partner card, call, message or live pin. The map pin shows the pickup address. |
| `pickup_assigned` | Out for pickup (live map, partner name and photo) |
| `picked_up` | Pickup done (bill viewable, not payable) |
| `submitted_to_cm`, `received_by_collection`, `submitted_to_services`, `services_in_progress` | In process |
| `services_completed` (searching, or waiting for the delivery time) | Ready |
| `out_for_delivery` | Out for delivery (map, path, name, phone, photo; Pay unlocked) |
| `delivered` | Delivered |
| `cancelled` | History: Cancelled |

- Tracking opens **right after "Order confirmed"**, including the `placed` state.
- Submit-to-CM and CM verification are **not** customer-visible steps.
- Call and message are placeholders. The phone number is display only.
- Under the tracker: laundry address, pickup address and delivery address.

### 8.3 Order surfaces until the door count is done

| Control | Until the pickup list is submitted (`placed`, `pickup_assigned`) | After Mark as picked up |
|---|---|---|
| Pay Bill | Disabled: "Bill yet to be generated" | View only until `out_for_delivery`, then pay |
| View Details → Items Summary | Placeholder: "Order items will be updated after pickup" | Hierarchy: **category → service → cloth items** (counts / weights and prices) |
| View Details → Bill Summary | Placeholder: "Bill will be generated after pickup is done" | Brief fee rows (as today). Tap opens an expanded sheet with the same category → service → cloth breakdown plus fees |

The active-order card for a no-cart order has no category until the door count. Until then its title is "Laundry pickup".

### 8.4 Pricing tab

- Browse only. No Select and no add-to-cart. There is no Pricing card in the Home footer.
- Category toggle (Regular Wash, Pro Clean, Home Linens, Luxury Care), then that category's services, then for the selected service **both** its per-kg price (`Service.per_kg_price`) **and** each cloth item's per-piece or per-pair price (`ClothesItem.per_unit_price`).
- **Includes** bullets per service (`Service.includes`, `Service.excludes`). Show "Not included" only if the copy exists. Do not show "Coming soon".
- The data is a read of the existing catalogue. There is no second pricing table and no CMS.

### 8.5 Orders list

Tabs: **All** (active + delivered), **Active**, **Completed** (delivered only). Cancelled orders are on none of them. The API gives each row a `card_type`, and the app draws exactly that card.

| Card | Orders | Content | Buttons |
|---|---|---|---|
| **Upcoming Pickup** (`upcoming_pickup`) | `placed`, `pickup_assigned` | Pickup date and slot (for example "Dec 2 - 8 - 9:30 am"), or "Instant pickup - finding a partner" for an instant pickup; pickup address | **Change Schedule**, **Cancel**. While `pickup_assigned`, tapping either opens a popup and does not change the order. |
| **In progress** (`in_progress`) | `picked_up` through `out_for_delivery` (the door count is done) | Header "In progress", short order id, title, count line, pickup date and slot, price | **View details**, **Track on map** |
| **Delivered** (`delivered`) | `delivered` | Same card, header "Delivered" | **View details** only |

- **Tap the card** (any status) opens Order Details.
- **Express:** an Express order shows the Express chip at the top of every card type.
- **Title:** "Mixed" when the order has more than one service line, otherwise the service name. It is "Laundry pickup" before the door count, which only happens on the Upcoming Pickup card.
- **Line under the title:** pieces for per-unit lines and weight for per-kg lines: "6 Items", "3.5 kg", or "6 Items - 3.5 kg". A per-kg service has a weight, not a count (section 3.1), so it never counts as an item.
- **Price:** the bill total (`bill.final_amount`) once the bill exists, which is every in-progress and delivered card.
- **Order of cards:** Upcoming Pickup cards first (soonest first; an instant pickup counts as now), then in progress (newest first), then delivered (newest first). An order is on exactly one card.
- **Cancel** while `placed` opens the "Are you sure you want to cancel?" pop-up with the reason options (section 1.7). While `pickup_assigned` it opens "Order cannot be cancelled. Pickup partner has already started."
- **Change Schedule** while `placed` opens the schedule sheet with the current date and slot preselected in **green**. When the customer picks another date or slot, the old one turns **red** and the new one is green. **Confirm** is enabled only when the choice differs from the current one. A current slot that is now `too_busy` or `closed` still shows as the current one (green or red) but cannot be picked again. An instant pickup has no current schedule, so nothing is preselected. If the delivery has to move, the customer is told (section 1.7). While `pickup_assigned` it opens "Schedule cannot be changed. Pickup partner has already started."
- **Track on map** opens the tracker (section 8.2).

### 8.6 How we work

- Home footer: the **How we work** entry, then the brand strip. Static, not tied to an order, English only.
- Six steps, each with a short line and one image (placeholders until the designer's art arrives): Out for pickup, Counted at door, In process, Ready, Out for delivery, Delivered.
- Pay is at delivery. Images and copy are in the client, not a CMS.

---

## 9. Config variables

All are named config, read from the database, then the environment, then the code default (section 10).

| Name | Default | Used by |
|---|---|---|
| `ASSIGNMENT_TIMEOUT_MINUTES` | 5 (10 or 20 allowed) | Pickup and drop search window |
| `ASSIGNMENT_RANGE_SLICES` | 5 | Number of rings |
| `ASSIGNMENT_MAX_RANGE_KM` | admin/env | Outer ring radius |
| `PICKUP_DELIVERY_BUFFER_DAYS` | 2 | Booking and reschedule validation, ordinary orders |
| `EXPRESS_BUFFER_DAYS` | 1 | Booking and reschedule validation, Express orders |
| `DELIVERY_FEE` | admin-editable | Bill at Mark as picked up |
| `EXPRESS_FEE` | admin-editable | Bill when `is_express` |
| `SERVICE_AREA_KM` | admin-editable | Add or edit address check |
| `SERVICE_QUEUE_POLL_SECONDS` | 120 (60 allowed) | Service man queue poll |
| Directions refresh | 2 minutes at most | Map re-route when off the path |

Slot template, slot status and the booking horizon are data and config managed through the slot admin API (section 1.4).

---

## 10. Backend decisions

- Ring distance is haversine on the backend. The Flutter app owns Google Directions and the polyline.
- After a search times out, a manager may force-assign any verified active delivery staff. Rings notify on-shift staff only.
- A cart has one line per service.
- Config is read from the database, then the environment, then the code default.
- Cash is allowed only after a UPI attempt has failed, expired or been cancelled.
- Delivery fee and express fee are snapshotted onto the bill at Mark as picked up.
- `Service.includes` and `Service.excludes` are the Pricing tab bullets.
- Door and drop photos go to Cloudinary, not Postgres.
- A service is bookable without a service man. Send to service queue still requires one.

---

## 11. Not building

- Pickup-only, delivery-only or walk-in orders.
- Booking fee, refunds, prepaid flows, cancelling individual services or cancelling after assignment.
- Redis, SSE or a second queue for the CM handshake or the service men. Two physical queues per service.
- A new order status for processing (`processed`) or for payment (`payment_pending`).
- DM verify step, a start-delivery gate, a DM live-tracking screen.
- Turn-by-turn navigation, re-routing on every GPS tick, snap-to-road.
- A promotions table, a CMS for steps, pricing or includes, a cancel-reason catalogue.
- A drafts screen, multi-device draft merge, or "resume tomorrow" at the door.
- Many service men per service, load balancing, or a per-service Express matrix.
- Offline SQLite sync for service men.
- Pay in the app before `out_for_delivery`, card or wallet payments, a cash-drawer product.

---

## 12. Open items (the default is used unless you say otherwise)

1. **Booking horizon and same-day cutoff:** how many days ahead the date chips go, and how long before a slot starts it stops being bookable. Default: 7 days; a slot is unavailable once it has started.
2. **Services with no service man:** the pickup partner sees every service, so `NO_SERVICE_MAN` can still happen at send-to-service-queue, after the bill is written. Default: keep as is.
3. **`SERVICE_AREA_KM` starting value.** Default: seed 10 km.
4. **UI copy for the designer:** the "Express" row under "bring it back" should read "Instant", because Express is now the top toggle. Its "Earliest - Today" subtitle must reflect the buffer, so ordinary orders will not show today. The pickup schedule sheet currently has the title "Schedule delivery", and it should follow the leg.

---

## 13. Where the code is today

API shapes for this design are in `backend/docs/api-contracts/`: `customer/orders`, `customer/slots`, `customer/config`, `customer/addresses`, `admin/slots` and `staff/door`.


The backend implements the flow up to the section 1 changes. Not built yet for the redesign:

- `cart_id` optional on create-order, and orders with no service lines.
- Express as priority only: modes and slots no longer forced instant, and `EXPRESS_BUFFER_DAYS`.
- The slot table, slot admin API, and `date + slot_id` validation on create and reschedule.
- `SERVICE_AREA_KM` check on add and edit address.
- Door count over the full catalogue: creating lines for services not on the order, locking pre-selected lines, and requiring at least one line to confirm.
- Customer app: slots API client, Delivery Options sending `date + slot_id`, and the `placed` tracker state.
- Orders list (section 8.5): `status=all`, `card_type`, `title`, `item_count` / `total_weight_kg` semantics, the fixed row order, and cancelled orders dropped from the list.
- Reschedule that moves the delivery (`delivery_shifted`, `DELIVERY_SHIFT_UNAVAILABLE`) and the cancel pop-up that sends `reason`.
- Customer app: the orders list cards, cancel pop-up and green/red schedule sheet are in the UI; they still read and write the device-local order store until the order APIs above are wired.
