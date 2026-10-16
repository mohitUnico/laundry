# WashBee order flow v2 - locked spec

**Status:** LOCKED (Parts 1-9). Complete enough to implement. Change a rule here first, then in code.  
**Captured:** 7-15 Oct 2026  
**How to extend:** add a new `## Part N` at the bottom; mark superseded rules instead of silently rewriting.  
**Diagrams:** [diagrams/](diagrams/) (start with [../README.md](README.md))  
**Interactive viewer:** [diagrams/viewer.html](diagrams/viewer.html)  
**UI prototype (designer click-through):** [ui-prototype/index.html](ui-prototype/index.html)

---

## 0. What this batch is

Move from **customer-counted laundry** to **service-booked laundry, counted at the door** (Layyr-style):

1. Customer books **services** (and per-kg vs per-unit), not cloth SKUs.
2. After cart: **instant vs scheduled** only. Logistics is **always pickup and delivery** (`both`). Pickup-only / delivery-only are gone.
3. Pickup partner **lists items / weights, takes photos, generates the bill**.
4. Until that happens, customer **Pay Bill** and **View Details** are placeholders. **Part 3:** after generation, **View Bill** is real; Pay Bill stays **not payable** — pay at delivery.
5. Tracking gains a first step **Out for pickup** + pickup-boy call/message.
6. Customer app adds a **Pricing** catalogue and a **home footer** (how-we-work + brand strip).

---

## 1. Current flow (as built in this prototype)

### 1.1 Customer place-order path

```
Category (Regular Wash / Pro Clean / Home Linens / Luxury Care)
  → Service sheet (e.g. Wash & Fold)
  → Pricing type (per kg / per piece)   [Regular Wash sheet already has this]
  → Item screen (shirt, pants, … steppers)
  → Add to Cart
  → Cart
  → Delivery Options: Pickup only | Delivery only | Pickup & Delivery
      (backend OrderType: pickup_only | drop_only | both | express_delivery)
  → Schedule Date & Time (From–To window)
  → Confirm / Payment screen (amounts shown now)
  → Orders list
  → Tracking / Pay Bill / View Details / Change schedule / Cancel
```

Bottom nav today: **Home, Orders, Cart, Account**. Home header has a **non-tappable** avatar (top left), greeting, address, bell.

### 1.2 What the customer already sees after place

- **Active order** card on Home.
- **Orders list:** Pay Bill, View Details, Change Schedule, Cancel.
- **Tracking** (`order_tracking_screen.dart`): map + 5-step tracker
  - Both: Pickup → In Process → Ready → Out for Delivery → Delivered
  - Mapped from `OrderStatus` (placed / pickup_assigned / picked_up / services_* / dispatch_assigned / out_for_delivery / delivered).
- Addresses under the tracker: laundry, pickup, delivery.
- Assigned partner card with call / chat when a delivery row exists.

### 1.3 Data model (relevant bits)

| Piece | Today |
|---|---|
| `CartItem` | `service_id` + `pricing_type` (`per_unit` / `per_kg`) + optional `weight_kg` + `CartItemSelection` (cloth + qty) |
| Place order | `POST` from `cart_id`. **Per-unit cart items must already have cloth selections** or the API rejects |
| `Order.pricing_model` | Whole-order enum. If **any** cart line is `per_kg`, the order is tagged `per_kg` |
| Bill | Created **immediately** for `per_unit` orders. For `per_kg`, bill waits until pickup staff uploads weights (`billing_status` pending / generated) |
| Pickup | `Delivery` + `PickupForDelivery.pickup_proof` (one photo). `needs_weight_machine` if order has per-kg lines |
| Pickup staff weight API | Updates **existing** `OrderItem.weight_kg` on per-kg lines. Does **not** create a cloth list from scratch |
| Pickup details UI (staff) | Sheet: customer name, weight kg, take photo, Confirm Pickup |
| Tracking steps in UI | 5. No “Out for pickup” |

### 1.4 What is already half-aligned

- Per-kg amount can be **₹0 until pickup**.
- Pickup photo already exists.
- Staff app already has a pickup-confirm sheet (weight + photo).
- Mixed cart of several **services** is already allowed at cart level.

### 1.5 What is **not** aligned

- Customer **must** pick cloth SKUs for per-unit.
- Bill is **not** deferred for per-unit.
- Delivery choice is **who carries what** (pickup / drop / both). **Locked change:** always `both`; customer only picks instant vs scheduled.
- Pickup staff cannot **enumerate items** (only fill weight on lines the customer already created).
- Customer Pay Bill / View Details assume items + amount exist.
- No Pricing catalogue screen; no Layyr-style home footer.
- Tracker first step is “Pickup”, not “Out for pickup”.

---

## 2. Proposed flow (this batch only)

### 2.1 Customer booking (new)

```
Select one or more categories
  → Select one or more services
  → For each service: per kg OR per unit   (NO cloth SKUs)
  → Cart shows services + pricing type only
  → Choose Instant and/or Scheduled **independently** for pickup and for delivery
      (always both legs; mix allowed, e.g. instant pickup + scheduled delivery)
  → If pickup scheduled: pickup date/time window
  → If delivery scheduled: delivery date/time — **not earlier than pickup date + 2 days**
      (leave room later for Express: same-day pickup+delivery with extra cost)
  → Confirm order   (no itemised bill yet)
  → Orders list / Active order
```

Cart line = `{ service, category, pricing_type }`. Quantity of clothes and kg are unknown.

### 2.2 Instant vs scheduled (LOCKED 7 Oct 2026, updated evening)

**Always both legs.** Pickup-only / delivery-only are gone.

Pickup and delivery each have their own mode. **Mix is allowed** (instant pickup + scheduled delivery, or the reverse, or both instant, or both scheduled).

| Leg | Instant | Scheduled |
|---|---|---|
| **Pickup** | Assignment job starts **immediately** on place | Job starts at **`pickup_time_from`** |
| **Delivery (drop)** | Job starts when **distribution manager marks the order ready / completed for dispatch** | Job starts at **`delivery_time_from`** |

Both jobs use the **same** expanding-radius search, timeout variable, and manager fallback (CM for pickup, **DM for drop**). See Part 2.6.

**Delivery schedule constraint:** customer may only pick a delivery date/time **≥ pickup date + 2 days**. If pickup is instant, pickup date = today. This must be a **config** (`min_days_pickup_to_delivery = 2`) so **Express** (same-day pickup + delivery, extra fee) can be added later without a redesign.

**Checkout UI:** not a single Instant/Scheduled toggle for the whole order — two legs, two modes. `order_type` always `both`. Store `pickup_mode` and `delivery_mode` (`instant | scheduled`).

Tracking (full 6 steps) is shown **only after pickup staff is assigned**. Before accept: no tracking screen.

Call / Message on tracking: **placeholder icons only** (not implemented).

### 2.3 Pickup partner (new job of counting)

At the door the pickup partner:

1. Lists **all cloth items** with **count** (per-unit) and/or **one weight per kg-service**.
2. Uploads **one photo per service**.
3. System **generates the bill** (service maths + admin delivery fee). Item list is **not editable** after this.

Until that submit: order has services but **no itemised bill**.

### 2.4 Customer order surfaces until pickup count is done

| Control | Until pickup list submitted | After |
|---|---|---|
| Pay Bill | Disabled / “Bill yet to be generated” | **SUPERSEDED Part 3:** bill is **view-only**. Customer pays **only at delivery**, not in this screen. |
| View Details | “Item list yet to be generated” | Item list + weights/qty + prices |
| Tracking | **Only after pickup is assigned.** Out for pickup current; live map; name/photo; call/message placeholders | Same after door submit |

### 2.5 After pickup list exists

Customer can see items and the generated bill. **SUPERSEDED Part 3:** they **cannot pay** here. Payment is **only at delivery**. Later tracker steps (In process → Ready → Out for delivery → Delivered) stay as now unless a later batch changes them.

### 2.6 New customer UI (from screenshots)

**a. Pricing section** (Layyr Pricing)

- Top service chips: Steam Press, Shoe Laundry, Wash & Fold, Wash & Press, …
- Selected service: itemised **₹ per pair / per piece** list, or **₹/kg** for kg services.
- “Your order includes” / “Not included” bullets.
- CTA: Select {service} (adds that service to cart with the active pricing type).

**b. Home bottom (scroll end)**

- Service tiles with **₹/kg + SELECT** (and Coming Soon tiles).
- “How we do your laundry” entry → 3-step story:
  1. Doorstep pickup (count & weigh in front of you; nothing charged yet)
  2. Cleaned at the hub
  3. Delivered fresh (pay after weighing)  
  **SUPERSEDED Part 9:** full pickup→delivery steps + images; pay is **at delivery**, not after weighing.
- Brand strip / tagline block.
- Coupon / offer bottom sheet (NEW50-style) is in the screenshots; **coupon product rules not specified this batch** — note only.

### 2.7 Bottom nav, Pricing screen, Account entry (LOCKED 7 Oct 2026)

**Bottom nav becomes:** Home · Orders · Cart · **Pricing**  
Remove **Account** from the bar (`home_bottom_nav.dart` index 3, `main_shell_screen.dart`).

**Pricing** (new tab, Layyr Pricing screenshot):

1. Category toggle along the top (Regular Wash, Pro Clean, Home Linens, Luxury Care — same families as Home tiles).
2. Then service chips/tabs for that category (e.g. Steam Press, Shoe Laundry, Wash & Fold).
3. Then the item list with **₹ prices** (per piece / per pair) or **₹/kg** for kg services, plus includes / excludes if we keep that copy.
4. CTA Select {service} still adds the **service** to cart (not a cloth SKU), matching the new booking model.

**Account** moves to the **top-left profile photo** on Home (`HomeHeader` avatar). Tap avatar → existing Account screen. Avatar is not tappable today; make it the Account entry.

**UX implication:** Orders, Cart, Pricing, and Tracking do not have that avatar. Account is reached by going **Home → avatar**, unless a later batch adds the same avatar on other tabs. Do not add a fifth nav item.

---

## 3. Target tracker (customer map screen)

Current (both): `Pickup → In Process → Ready → Out for Delivery → Delivered`

Proposed (this batch):

```
Out for pickup  →  Pickup  →  In Process  →  Ready  →  Out for delivery  →  Delivered
```

Under the tracker (keep):

- Laundry address, pickup address, delivery address
- Pickup boy identity + **message** + **call** once assigned (especially while Out for pickup / Pickup)
- Live map of partner when they are en route to pickup **or** to deliver

Suggested mapping to existing `OrderStatus` (to confirm later):

| UI step | Likely statuses |
|---|---|
| Out for pickup | `pickup_assigned` (staff accepted, moving) |
| Pickup | `picked_up` (list + photos submitted) |
| In Process | `received_by_collection` … `services_in_progress` |
| Ready | `services_completed` / `dispatch_assigned` |
| Out for delivery | `out_for_delivery` |
| Delivered | `delivered` / `closed` |
| (before assignment) | `placed` — tracker shows step 0 empty / “Partner not assigned yet” |

`placed` with no staff: show tracker but no live pin / no call buttons.

---

## 4. Impact by layer (for later planning, not a build ticket)

### 4.1 Database / backend

- Relax `CartItem`: per-unit **without** `CartItemSelection` at add-to-cart.
- Relax `order.service.js`: stop requiring selections on per-unit at place; **do not** create a per-unit bill at place.
- Treat **all** new orders like today’s per-kg bill delay: `billing_status = pending`, `Bill` created only after pickup submit.
- New (or extend) pickup API: **upsert item lines** `{ cloth_id, quantity }` and/or `{ service_id, weight_kg }`, plus photos, then compute bill.
- Flag on order: `items_confirmed_at` / `inventory_source = pickup_staff` so customer UI can branch.
- Instant vs scheduled: `pickup_mode` + `delivery_mode` (`instant | scheduled`). Always `order_type = both`.
- Assignment timeout, max search range, time-slice count, delivery fee, min days pickup→delivery: **admin/backend config variables** (see Part 2.6).
- Drop assignment mirrors pickup: Redis/BullMQ + expanding radius + DM force-assign after timeout.
- Photos: `pickup_proof` is a single URL today — likely needs a list.
- Service queue / collection manager: today they consume `OrderItem`s. If items appear only after pickup, **queue assignment must wait** until pickup submit. Call out when designing CM / service-man parts.

### 4.2 Customer app

- Remove item stepper screens from the **booking** path (keep catalogue data for Pricing + for staff picker).
- Cart UI: service name, category, per kg / per unit chip, no qty/kg totals.
- Replace Delivery Options screen: **Instant / Scheduled only**. Always collect pickup + delivery addresses. Drop pickup-only and delivery-only cards and the `toBackendOrderType()` mapping to `pickup_only` / `drop_only`.
- Payment: after pickup, not at confirm (confirm = place job).
- Orders / details / pay: empty states.
- Tracking: 6 steps; pickup-boy block earlier.
- Bottom nav: Home, Orders, Cart, **Pricing**. Remove Account tab.
- New Pricing screen: category toggle → services → priced item list (Layyr).
- Account: tap Home header avatar (top left). Other tabs have no Account icon unless specified later.
- Home footer + optional “how we do laundry” sheet.
- Demo store (`customer_demo_store.dart`) must simulate “items pending” vs “items confirmed”.

### 4.3 Delivery / management app

- Pickup job: item picker per service; **one weight per kg-service**; **one photo per service**; then submit → bill.
- Confirm Pickup stays, but weight-only sheet is not enough.
- Expanding-radius SSE search; after timeout CM (pickup) / DM (drop) force-assign. Assigned staff **cannot reject**.
- CM/DM staff list shows **Google Maps / coordinate distance** to pickup or drop address.

### 4.4 Admin / mart-admin

- Pricing page is a **read** of existing `Service` + `ClothesItem` prices.
- Include / exclude copy per service (Layyr bullets) — **still unspecified** (content model).
- Coming Soon services: likely `is_active` or a new flag.
- **Delivery fee** is an admin-editable variable, auto-added when the bill is generated.
- Assignment timeout (5/10/20 min), max range, slice count, min days to delivery: admin or env config.

### 4.5 Demo prototype vs live

Implement against **both** `C:\prototype` (demo) and `C:\my_workspace\laundry` (live). Demo must show: pending items → after fake pickup submit, **viewable bill (not payable)**; assignment timeout → CM force-assign. Pay happens on the **delivery** demo path.

---

## 5. Questions — locked 7 Oct evening (unless marked open)

1. ~~Pickup-only / delivery-only / both~~ **Always both.**
2. ~~Instant vs scheduled timing~~ **Pickup job:** instant → on place; scheduled → at pickup time. **Drop job:** instant → when DM marks ready/completed for dispatch; scheduled → at delivery time. Mix of modes allowed. Delivery date ≥ pickup + 2 days (config; Express later).
3. ~~Pay at confirm~~ No item bill until door submit. **SUPERSEDED Part 6:** **no booking fee** will be added later.
4. ~~Mixed cart~~ Allowed. Bill = per-service kg or unit maths, then + delivery fee.
5. ~~Min kg~~ **Not enforced.**
6. ~~Edit item list after submit~~ **Not editable** for now.
7. ~~Pricing in nav~~ Fourth tab Pricing. Account = Home avatar.
8. ~~Call / message~~ **Placeholder icons only.** **Part 8:** Pricing shows **Includes** bullets; browse-only; no Coming Soon.
9. ~~Coupons~~ Applied **when paying the bill** (after generation). **SUPERSEDED Part 3:** one existing `Coupon` at UPI pay (unlocks on `out_for_delivery`). Cash is **fallback after UPI fail** only. UPI success marks **payment completed everywhere** without waiting on the boy. Boy + **one photo** still required for **Delivered**.
10. ~~Drop-only / walk-in~~ Out of scope.
11. ~~Original repo~~ `C:\my_workspace\laundry`.

---

## 6. Screenshot → WashBee mapping

| Screenshot | Use in WashBee |
|---|---|
| Pricing / Shoe Laundry list + includes/excludes | New **Pricing** section; data from `ClothesItem.per_unit_price` / `Service.per_kg_price` |
| Home tiles ₹49/kg SELECT + Coming Soon | Home **bottom** service grid; SELECT adds that service to cart with default pricing type |
| How we do your laundry (3 photos) | Home footer entry + full screen/sheet; copy matches new “count at door, pay after” model |
| Coupon sheet NEW50 | Later; do not design payment rules until coupons batch |

---

## 7. Suggested sequence when implementation starts (after remaining flows)

Not a go-ahead. When parts 2+ are in:

1. Backend: cart without SKUs + deferred bill + pickup item-list API + `items_confirmed` flag.
2. Staff pickup UI: catalogue + photos + generate bill.
3. Customer: booking path + empty Pay/Details + 6-step tracker + pickup-boy actions.
4. Customer: Pricing + home footer.
5. Expanding-radius assignment (pickup + drop) + CM/DM force-assign.
6. Demo store: pending items, timeout, force-assign, viewable bill, pay at delivery.

---

## 8. Next input expected from you

**Part 3 captured** (pickup door-count → bill → request-for-submission → CM verify/receive).

**Parts 3–9 locked.** Pricing = **nav tab only**, browse-only, **Includes** bullets, no Coming Soon. Living spec is complete enough to implement.

---

## Part 2 — Pickup assignment, CM fallback, door count, bill (7 Oct 2026)

### P2.1 Proposed flow (this batch)

```
Customer places order (always both legs; pickup_mode × delivery_mode independently)

PICKUP SEARCH starts:
  instant  → immediately
  scheduled → at pickup_time_from
  Expanding radius over ASSIGNMENT_TIMEOUT (default 5 min, 5 slices) — Part 2.6
  On-shift staff only. First accept wins.
       ↓
  If none accept by timeout → CM only now may force-assign
       staff cannot reject
       SSE: “CM assigned this job to you”
       ↓
  THEN customer may open tracking (not before)
       Out for pickup current, live map, name/photo, call/message placeholders
       ↓
  At door: services + pricing type from cart
       per-unit → item counts (old customer item UI)
       per-kg → ONE weight for that whole service
       ONE photo per service
       POST → Bill = service maths + admin delivery-fee variable
       customer **views** bill; pay is at delivery (Part 3 lock)
       item list not editable after submit

DROP SEARCH (same engine as pickup) — **SUPERSEDED Part 5:**
  instant  → auto-starts when **all service items are completed** (not “DM marks ready”)
  scheduled → auto-starts at `delivery_time_from`, and **only if** processing is already done
  If processing done but delivery still in the **future** → no auto search, **DM cannot assign**
  After ASSIGNMENT_TIMEOUT → DM may force-assign (cannot reject)
```

**Bill maths (locked):**

| Line | Formula |
|---|---|
| Per-kg service | **one** `weight_kg` for that service × `service.per_kg_price` |
| Per-unit service | sum of `qty × clothes_item.per_unit_price` |
| Delivery fee | admin **variable**, added automatically |
| Coupons | **SUPERSEDED Part 3:** not on an in-app Pay Bill. Apply when paying **at delivery** (details in payment batch). |
| Order total | sum of service lines + delivery fee − coupon |

### P2.2 Current flow (what the prototype/backend already does)

| Topic | Today | This batch wants |
|---|---|---|
| When pickup broadcast starts | BullMQ at `pickup_time_from`. No instant mode | Instant = now; scheduled = at pickup time |
| When drop broadcast starts | Separate DM/dispatch flow, not the same job | Instant = DM marks ready; scheduled = at delivery time. **Same engine as pickup** |
| Who is notified | Default send-to-all active, cap 100 | **On-shift only**, expanding radius rings (not all-at-once) |
| Accept window | 120s, then auto-retry (max 2) | **One** timeout (`ASSIGNMENT_TIMEOUT_MINUTES`, default 5, toggle 10/20). No auto-retry |
| Manager fallback | Log and stop | After timeout only: **CM** pickup, **DM** drop. Force-assign, **cannot reject** |
| Distance | Not shown on CM assign | **Google Maps + coordinates**; show km on CM/DM staff list |
| Customer tracking | Available from placed | **Hidden until pickup is assigned** |
| Door | Weight on existing per-kg lines; one proof URL | Item picker; **one weight per kg-service**; **one photo per service** |
| Bill | Immediate if whole order per_unit | After door submit + **delivery fee variable**. Customer **views** only; pay at delivery. |

### P2.3 What we can reuse vs what must change

**Reuse**

- `DeliveryAssignmentRequest` + recipients + accept/reject SSE
- BullMQ pickup-assignment queue + catch-up job (today every 5 min as Redis safety net — different from the 5-min accept window)
- `assignPickupDirect` for CM override
- Delivery staff shift + last lat/lng for “active nearby”
- Pickup proof upload
- Customer tracking map + partner card (extend, don’t replace)

**Change**

- `pickup_mode` / `delivery_mode`; drop job twin of pickup job
- Expanding-radius notifier (5 slices); on-shift only; first accept wins
- Timeout config; **no** second auto-retry; CM/DM force-assign after timeout only
- Google Maps distance on manager assign lists
- Door: one weight + one photo **per service**; bill + delivery-fee variable
- Hide customer tracking until pickup assigned
- Item list frozen after submit. Coupons: **at delivery** (Part 3).

### P2.4 Layer notes

**Backend:** sliced search (Part 2.6). On full timeout with no accept → overdue for CM (pickup) or DM (drop). Direct assign SSE is forced.

**CM / DM:** overdue only **after** timeout. Staff list = on-shift; show distance. Assign = existing direct-assign.

**Delivery app:** accept overlay during search. After manager assign, job is mandatory. Door UI: per service, counts or one weight, one photo.

**Customer app:** no tracking until assigned. Then Out for pickup + live map + placeholders.

### P2.6 Config variables and expanding-radius search (LOCKED)

All of these must be **named config** (env now, laundry-admin later) so ops can change them without a code rewrite.

| Variable | Default (now) | Purpose |
|---|---|---|
| `ASSIGNMENT_TIMEOUT_MINUTES` | `5` | Total auto-search window. Must be switchable to `10` or `20` |
| `ASSIGNMENT_RANGE_SLICES` | `5` | How many equal time parts the timeout is split into |
| `ASSIGNMENT_MAX_RANGE_KM` | *set in admin/env* | Outer search radius |
| `MIN_DAYS_PICKUP_TO_DELIVERY` | `2` | Earliest scheduled delivery. **Same value as `PICKUP_DELIVERY_BUFFER_DAYS` (Part 6) — one env, two names not allowed.** Express later can set this to `0` + surcharge |
| `DELIVERY_FEE` | admin-editable | Added automatically when the bill is generated |

**Expanding radius (pickup and drop, same logic):**

```
sliceDuration = ASSIGNMENT_TIMEOUT_MINUTES / ASSIGNMENT_RANGE_SLICES
ringKm(i)     = (i / ASSIGNMENT_RANGE_SLICES) * ASSIGNMENT_MAX_RANGE_KM
                i = 1..SLICES

For slice i in 1..SLICES:
  window = ((i-1) * sliceDuration)  ..  (i * sliceDuration)
  radius = ringKm(i)                // includes all inner rings
  notify on-shift staff whose distance from
      pickup coords (pickup job) or delivery coords (drop job)
      is ≤ radius AND who were not already notified
  distance = Google Maps (road) using staff current lat/lng
             and the job address coordinates
If anyone accepts in any slice → stop search, first write wins.
If timeout ends with no accept → manager force-assign only from then.
```

Example: timeout 5 min, max range 10 km, 5 slices → minute 1: 2 km; minute 2: 4 km; … minute 5: 10 km.

**Staff set:** `DeliveryStaffShift.is_active` (shift on). Others ignored.

**CM/DM manual list:** same distance (Google Maps + coordinates) shown next to each on-shift staff.

**Race:** two accepts at once → **one** assignment (DB first-writer wins); the other is rejected.

**Express:** **SUPERSEDED Part 7** — not a global buffer=0. Per-order flag + badge + service-queue priority + extra fee. Buffer stays 2 for ordinary orders.

### P2.7 Part-2 questions — locked

12. Nearby = **dynamic rings**, not a single radius.  
13. **On-shift only.**  
14. **First accept wins.**  
15. Manager assign **only after timeout.**  
16. Force-assigned staff **cannot reject.**  
17. Drop search **mirrors pickup** (instant after DM ready, or at scheduled delivery time).  
18. **Mix of instant and scheduled** allowed per leg.  
19. **One weight per service**, not per cloth.  
20. **One photo per service.**  
21. **Delivery fee = admin variable**, auto on bill.  
22. **No customer tracking until pickup is accepted/assigned.**

---

## Part 3 — Pickup door-count, bill, submit-to-CM handshake (13 Oct 2026)

### P3.1 Proposed flow (this batch)

Customer tracker at this point is already on **Out for pickup** (Part 2: tracking only after assignment).

Pickup-boy **one button**, three labels (same control, not three actions):

| When | Button |
|---|---|
| Assigned, door work not confirmed | **Mark as picked up** |
| After mark picked up, request not sent | **Submit request to CM** |
| After request, waiting on CM | **Waiting for CM verification** (inactive colour, not tappable) |

```
Pickup boy opens the assigned order
  Sees booked services (same list the customer booked)
  Each row shows pricing type: per kg | per unit
       ↓
  Tap a service → same semi-flow the customer used to have
    (service list → expand that service → count / weigh)
    per unit → count items from that service’s catalogue
    per kg   → ONE weight for that whole service (locked P2.7 #19)
    ONE photo per service (camera or gallery) (locked P2.7 #20)
  All booked services finished in **this one visit** (no come-back to finish later)
       ↓
  Taps **Mark as picked up**
    bill generated, written to DB
    customer **View Details / View Bill** unlock (Pay Bill does **not** become payable)
    customer tracker: **Out for pickup** → **Pickup done**
    button label becomes **Submit request to CM**
    order stays on pickup-boy list
       ↓
  Anytime after that (door, transit, or laundry): taps **Submit request to CM**
    status → submitted_to_cm
    button becomes **Waiting for CM verification** (inactive)
    cannot cancel request; cannot edit items
       ↓
  CM taps **Verified & Received**
    status → received_by_collection
    pickup list: row gone on next **pull-to-refresh**
    pickup delivery leg complete
```

### P3.2 What exists today (prototype + live)

| Step | Today | Gap |
|---|---|---|
| Pickup item UI | Per-kg **weight fields per order item**, not per-service expander. Per-unit items were already on the order from **customer** cart. No “old customer item list” for staff. | New: SKU-less cart → staff fills the expander per booked service. |
| Photo | Pickup proof on the **delivery** (`pickup_proof`), not one photo per service. | Per-service photo (locked). |
| Bill | **Not** generated at the door. CM invoice API requires `received_by_collection`. Per-unit bills can exist at place-order; per-kg stays 0 until CM. | Door POST generates the **one** bill (Part 2). CM invoice-after-receive **conflicts** — drop that rule. |
| Customer tracker | Steps start at Pickup; `picked_up` fills that step. | Assigned = **Out for pickup**. **Mark as picked up** → **Pickup done**. |
| Submit to CM | Pickup boy one-shot action `submitted_to_cm`: marks drop-at-laundry, **completes** the pickup delivery, sets `submitted_to_cm`. Order moves to pickup **Completed** tab immediately. | Split into **request** (order stays) then **CM verify** (then remove). |
| CM receive | Incoming list today: `placed` / `pickup_assigned` / `picked_up` / `submitted_to_cm`. `markOrderReceived` from those → `received_by_collection`. Button **Verified & Received**. | **List stays as today:** yet-to-pick-up **and** incoming picked-up. **Action** Verified & Received only from `submitted_to_cm` (not from `placed` / `pickup_assigned`). |
| Queue | Pickup **assignment** already uses BullMQ/Redis. Handoff is a **synchronous HTTP** status change. No queue between pickup and CM. | See over-engineering below. |

Relevant current statuses (keep; remap meaning, do not invent a Redis job type):

```
picked_up                Mark as picked up. Items + bill. Customer: Pickup done. Button: Submit request to CM.
submitted_to_cm          Request sent. Button: Waiting for CM verification (inactive). Still on pickup list.
received_by_collection   CM verified. Row gone after pull-to-refresh. Pickup Delivery completed.
```

### P3.3 Pickup-boy UI (door)

1. Service list = cart services only (not the full open catalogue).
2. Badge on the row: **Per unit** / **Per kg**.
3. **Semi-flow = the old customer path**, reused for staff: tap a booked service → expanded item sheet for **that** service’s catalogue (not a shortened common-items list).
   - per unit: quantities on cloth items that belong to that service
   - per kg: one numeric weight for the service (not per cloth)
4. Photo on the same expanded panel: **camera or gallery**. One image per service.
5. A service is “done” when required fields for its pricing type + photo are present.
6. **Mark as picked up** enabled only when **all** booked services are done in **this visit**. No planned “come back tomorrow.” Mid-visit crash: **server draft** (P3.9 #15) so he can reopen the same job and finish.
7. Mixed order (some services per-unit, some per-kg) is **allowed**.
8. After **Mark as picked up**: item list **not editable**, request **not cancellable**. CM refuse / recount is a later scale-up, not this batch.

### P3.4 Bill

- Written on **Mark as picked up** (same POST as Part 2).
- Line items = service maths + admin delivery-fee variable.
- Customer: bill is **visible** immediately (View Details / View Bill). **Cannot pay.** Only the **customer** sees this bill for now (no CM/admin bill ping).
- **Pay unlocks on `out_for_delivery`** (P3.12): UPI first; cash only if UPI fails. UPI success = paid everywhere, no boy needed for payment.
- Coupons are **not** applied at the door. Applied on the **doorstep UPI pay** sheet (P3.12).
- Do **not** keep today’s “invoice only after `received_by_collection`” gate.

### P3.5 Customer tracker (this slice)

| Event | Tracker |
|---|---|
| Pickup assigned (Part 2) | **Out for pickup** current |
| **Mark as picked up** | **Out for pickup** → **Pickup done** |
| Submit request / CM verify | **Not** a customer-visible step |

Call/message placeholders stay as in Part 2.

### P3.6 Submit handshake

One control on the order row / detail, label changes with status. Request may be sent **anytime after** Mark as picked up (door, transit, or counter).

| Status | Pickup list | Button |
|---|---|---|
| `pickup_assigned` (door work unfinished) | Yes | **Mark as picked up** (blocked until all services filled) |
| `picked_up` | Yes | **Submit request to CM** |
| `submitted_to_cm` | Yes | **Waiting for CM verification** (inactive) |
| `received_by_collection` | **No** (after pull-to-refresh) | — |

**CM incoming list (locked, keep as today):** orders **yet to be picked up** (`placed` / `pickup_assigned`) **and** incoming after pickup (`picked_up` / `submitted_to_cm`). Do not hide pre-request orders from CM.

**CM Verified & Received** still only for `submitted_to_cm`. Pickup boy cannot skip the request. Seeing an order ≠ allowed to mark received.

**Backend:** HTTP status transitions + existing notify. Pickup list: `pickup_assigned` | `picked_up` | `submitted_to_cm`. Hide at `received_by_collection`. **Refresh = pull-to-refresh**, not a live SSE drop. Complete the pickup **Delivery** row on CM receive, not on the request.

### P3.7 “Queue” — do not over-build

**Do not add a new BullMQ/Redis queue for this.** Assignment already has a timed worker. This handoff is two HTTP writes; the pickup app **pull-to-refresh** hides the row. If “queue” means CM’s incoming list, that is a query, not Redis.

### P3.8 Over-engineering / extra complication (this batch)

1. **Redis/BullMQ for CM handshake** — skip.
2. **New status names** — skip; reuse `picked_up` / `submitted_to_cm` / `received_by_collection`.
3. **Completing the pickup Delivery at request time** (today). Complete it on **CM receive** only.
4. **CM Verified & Received from `placed` / `pickup_assigned`** — close. List may still **show** those orders (locked: keep incoming as today).
5. **Bill twice** (door + CM invoice) — one bill at Mark as picked up. CM does not get a bill-generated notification.
6. **CM editing weights** after pickup — freeze. CM refuse/recount is a later scale-up (locked: not this batch).
7. **Photos “uploaded to the database”** — do **not** store image bytes in PostgreSQL (`BYTEA`). Use the existing upload pipeline (S3 / `uploads/` + URL on the service/order-item row), same as today’s `pickup_proof`.
8. **Live SSE to drop the pickup row** — skip; pull-to-refresh is locked.
9. **In-app Pay Bill after door-count** — skip. View only. Pay is **UPI intent at doorstep**.
10. **Timeouts / auto-receive / cancel-request** on this handshake — skip.
11. **Draft as a separate product** (Draft table, version history, multi-device merge, a Save Draft button, “resume tomorrow” UI) — skip. Autosave counts/photos onto the **same order** (`items_confirmed = false`) when leaving each service expander. Mark as picked up flips confirmed and generates the bill. That is crash recovery, not a second visit.
12. **Home-grown UPI** (`upi://pay` to the boy’s VPA, then guess success from Android resume). Food/grocery apps do **not** do that — they use a PSP (Razorpay / PhonePe / Cashfree) UPI intent so the app gets a real success/fail when it returns. Rolling your own collect + polling is both extra work and unreliable. Reuse a PSP; payee = **merchant**, not the delivery boy’s personal UPI.
13. **Card / wallet / netbanking** — skip. **COD as a first-class checkout** — skip. Cash is only a **Paid in cash** fallback after UPI fails. Reuse existing `payment_method = cod` on `Bill`; do not add a cash-drawer / change-making product.
14. **New Promotion table.** There is already `Coupon` (`coupons` in Prisma). There is **no** separate promotions table — do not create one. One code per pay from that table.
15. **`order_status = payment_pending` after UPI success.** That old status meant “delivered, waiting for boy to confirm pay.” New rule: UPI success writes `bill.payment_status = completed` immediately and **shows paid everywhere**. Order stays `out_for_delivery` until boy + photo → `delivered`. Payment and delivery are different fields.

### P3.9 Questions — locked 13 Oct 2026

1. Request for submission: **anytime after** Mark as picked up (door, transit, or laundry).
2. **One button**, three labels: **Mark as picked up** → **Submit request to CM** → **Waiting for CM verification** (inactive). Not a second unlock-tap after CM.
3. CM refuse / recount / cancel: **not this batch**. Scale up later. Until then CM only **Verified & Received**.
4. Pickup boy **cannot** cancel the request once sent. **Cannot** edit items after Mark as picked up.
5. Item UI: **same semi-flow the customer used** (service list → expand that service → count/weigh from that service’s catalogue).
6. **One visit:** every booked service finished before Mark as picked up. No resume-later for leftover services.
7. Photos: **camera and gallery**. Persist via existing upload + URL on the record (not raw bytes in DB).
8. **Mixed** per-unit + per-kg services on one order: allowed.
9. Customer **cannot pay** after the bill exists. **View only.** Pay **only at delivery**.
10. Pickup list after CM verify: **pull-to-refresh** (not live SSE).
11. Tracker: **Out for pickup** → **Pickup done** when the boy taps **Mark as picked up**.
12. **CM incoming list stays as today:** yet-to-pick-up **and** incoming picked-up. Not request-only.
13. After bill generation, **only the customer** sees it for now. No CM/admin ping.
14. Mid-visit **server draft:** yes (crash recovery on the same job).
15. Pay unlocks when order is **`out_for_delivery`** (boy may still be en route). Not after pickup, not at confirm. **SUPERSEDES** “only once the boy is at the doorstep.”
16. Pay method: **UPI intent** first (any UPI app → back to WashBee). **SUPERSEDES “cash not allowed”:** if UPI **fails**, **delivery boy** taps **Paid in cash**. Then `bill.payment_status = completed`, `payment_method = cod`, shown **everywhere including the customer**. Customer cannot self-declare cash. Cash is not the first option. Do not record cash if UPI already completed.
17. **UPI success** → write payment completed in DB **immediately**; **every** surface shows paid (customer, staff, admin). **Does not wait** for the delivery boy. Boy action is only for **Delivered**, not for UPI payment.
18. **Delivered** still requires the delivery boy: **Mark as delivered** + **one photo** (existing `drop_proof`). UPI success does **not** auto-deliver. **Payment must be completed first** (UPI or Paid in cash); Delivered stays inactive until then.
19. **One coupon per pay**, from existing **`Coupon` / `coupons`** table (yes, that table is already in Prisma). No second promotions table. Not a free-typed string.
20. **Paid in cash** is a **delivery-boy** action only. After it, payment completed reflects in DB and on **all** UIs (customer included), same as UPI success.
21. **Payment before Delivered.** Boy cannot mark delivered (or upload the photo as the completing action) while the bill is still pending.

Q10 from the previous pass (paid-then-count-error) is **moot**: there is no pay until `out_for_delivery`.

### P3.10 Closed

**Mark as delivered + photo** is disabled until `bill.payment_status = completed` (UPI success **or** boy **Paid in cash**). Payment first, then delivered.

### P3.11 Draft (how, without extra machinery)

On each service expander complete (counts/weight + photo URL): `PATCH` the order’s item rows. `items_confirmed` stays false; **no bill**. App kill → reopen assignment → expander shows saved numbers. **Mark as picked up** requires all services filled, sets confirmed, writes the bill. Do not add a Drafts screen.

### P3.12 Pay (locked)

Payment lives on **`Bill`**. Delivery lives on **`Order.order_status`**. Do not conflate them.

```
order_status becomes out_for_delivery
  Customer Pay unlocks (View Bill already existed)
    optional: pick ONE code from coupons table → Bill.discount + final_amount
    primary: PSP UPI intent → any UPI app → return to WashBee
      success → bill.payment_status = completed, payment_method = upi
               paid shown everywhere immediately (no boy involved)
      fail    → still unpaid; customer can retry UPI
               OR delivery boy taps **Paid in cash**
                 → bill.payment_status = completed, payment_method = cod
                 shown everywhere, including the customer app
       ↓
  Delivery boy: Mark as delivered + ONE photo (drop_proof)
    enabled only if bill.payment_status = completed
    → order_status = delivered
    Does not change payment
```

| Event | Payment (`Bill`) | Order status |
|---|---|---|
| `out_for_delivery` | pending; Pay unlocked | `out_for_delivery` |
| UPI success | **completed** everywhere | still `out_for_delivery` |
| Cash fallback recorded | **completed** everywhere | still `out_for_delivery` |
| Boy + photo | unchanged | **`delivered`** |

**Today:** `Coupon` model exists (`coupons`); there is **no** `Promotion` table — use Coupon. `processPayment` PATCHes the bill (no PSP yet). Drop `dropped` sets `delivered` and already accepts `drop_proof`, **without** checking payment. **Gap:** UPI PSP intent; cash fallback on boy UI after UPI fail; gate `dropped` on `bill.payment_status === completed` + one photo; do **not** set `payment_pending` on the order after UPI success.

**Do not** pay the delivery boy’s VPA. Merchant PSP.

---

## Part 4 — CM send to services, service-man FIFO, DM sees completed items (13 Oct 2026)

### P4.1 Proposed flow

```
CM list of Verified & Received orders (received_by_collection)
  Taps **Send to service queue**
       ↓
  Order leaves the CM list
  order_status → submitted_to_services
  Each booked service line is auto-assigned to **that service’s** one service man
  New queue rows sit at the **bottom** (sort by assigned_at ASC)
  No SSE — next list load / refresh shows them there
       ↓
  Service man queue (FIFO)
    mark item **In progress**
    mark item **Completed**
  When any item completes, DM can already see that order + its completed items
  When **all** items complete → order_status → services_completed
```

### P4.2 What exists today (mostly this already)

| Piece | Today | Gap vs this batch |
|---|---|---|
| CM received list | `listReceivedOrders` = `received_by_collection`. UI: **Submit to Services**. | Rename/label **Send to service queue** if you want that copy. Behaviour is the same. |
| Submit | `submitOrderToServices`: requires received; creates `ServiceQueueItem` per `OrderItem`; assigns `Staff` where `role=service_man` and `service_id` matches; `priority = max(service)+1`; order → `submitted_to_services`. Order drops off received list. | **Keep.** Fails if no service man for a service. |
| One SM per service | `Staff.service_id` is **unique**. | **Locked:** one service man ↔ one service. No load-balance. |
| FIFO | `orderBy: [{ priority: 'asc' }, { assigned_at: 'asc' }]`. | **UI order = `assigned_at` ASC** (time assigned). New rows naturally at the bottom. `priority` integer not required for this UX. |
| SM actions | `in_progress`, `completed`, plus **`mark_for_later`**. First in_progress → `services_in_progress`. Last completed → `services_completed`. `assigned_at` already stored. | **In progress + Completed only.** No Mark for later. **Any** row may be started. Multiple in_progress allowed. Show assigned time. |
| Live list | SSE hub exists only for **delivery-staff assignment**. SM queue is already pull/GET. | **No SM SSE.** Poll **1–2 min** (default 2) while the queue screen is visible. Sort `assigned_at` ASC. |
| DM | `listReadyToVerify` includes `services_in_progress` **and** `services_completed`. `getOrderItems` returns each line’s `item_status`. | Order appears when **any** service item is completed. Expand = **whole** order: completed vs pending (pending = inactive colour). Verify/dispatch still wait for all done (Part 5). |
| CM invoice button | Still on the received card. | **Conflicts Part 3** (bill at door). Hide generate-invoice here. |
| CM history | `listSubmissionHistory` (`submitted_to_services_at` not null). | **Keep.** After send-to-queue the order is gone from received list but remains in history. |

Queue row today = **one `OrderItem`** (one booked **service** line, with nested cloth selections). Not one row per shirt.

### P4.3 Assignment (locked)

- **One service man per service**, and **one service per service man**, as of now (`Staff.service_id` unique).
- Mixed order → split by service onto those men. CM does **not** pick the man.
- No service man for a booked service → submit **fails** (already). Don’t silently skip lines.

### P4.4 FIFO in the UI — **no SSE**

New service items at the **bottom** is a **sort**, not a live push.

**List order:** `assigned_at` **ASC** (oldest assignment at top). A later `assigned_at` renders below. Starting a row does **not** change `assigned_at`, so other rows stay put.

**How the SM sees a new row**

- Open the screen / app killed → **GET DB**, already ordered.
- While the screen is **already open:** **poll** the same list GET every **`SERVICE_QUEUE_POLL_SECONDS`** (default **120** / 2 minutes; 60 is also allowed). Replace the list from the response (`assigned_at` ASC). New rows land at the bottom; in-progress rows keep their assigned time so they don’t jump. Pull-to-refresh still works in between.
- Poll **only while this screen is visible**. Stop in background.

**Do not** extend `RealtimeService` for service men. Do not add SSE, Redis, or a queue product. `priority` can stay on the row unused.

### P4.5 Service man

- **One queue per service** (current version): each booked **service item** (`OrderItem` / `ServiceQueueItem`) lands on that service’s queue. Because there is one service man per service, his list **is** that service’s queue.
- **Any row can be started** (not only the top). Several may be In progress at once.
- List **order** is still **time assigned** (`assigned_at`), not “whatever he started first.”
- **In progress** and **Completed** only. **No Mark for later.**
- Show **assigned time**. After app kill, GET DB: same statuses + same times + same order.

### P4.6 Distribution manager (this slice only)

- Order enters the DM list when **any** service item is completed (`services_in_progress` or `services_completed`).
- Expand = **the whole order**. Completed items vs **pending** (inactive colour / indication). Not a completed-only subset.
- **Cannot** verify / dispatch until all items are done (`services_completed`) — today’s gate; next part.

### P4.7 Over-engineering — locked 14 Oct (your answers)

1. **SSE / Redis / new queue product / extend `RealtimeService` for SM** — **skip.** New items at the bottom = `ORDER BY assigned_at ASC` on GET. Open screen: **poll 1–2 min** (default 2). Do not poll every few seconds.
2. **One queue row per cloth SKU** — skip. Per **service item**, current `ServiceQueueItem` / `OrderItem`. Each service has its own queue.
3. **Many service men per service + load-balance** — skip. **One service man ↔ one service**, as of now.
4. **“Only the top row can be started”** — skip. **Any** row can be started. On-screen **order** is **time assigned**.
5. **`mark_for_later`** — no, as of now.
6. **CM generate invoice after receive** — skip. Bill is generated when the **pickup boy updates all items** (Part 3).
7. **Offline / local SQLite sync** — skip. Reopen = GET DB. Fine as specified.

### P4.8 Questions — locked 14 Oct 2026

1. Queue grain: **per service item**, each service has **its own queue**, current version.
2. **Multiple** items may be In progress at the same time. **Any** row can be started. List order = **`assigned_at`**.
3. **No Mark for later** for now.
4. DM sees the **whole order**. If **any** service item is completed, expand: completed vs pending (inactive colour).
5. Customer tracker: **In Process** while any service is pending. **Ready / Processed** when all service items are completed (`services_completed`). Confirmed in spirit by Part 5; exact customer label still in P5 questions.
6. App killed: reopen **from DB** with statuses **and assigned time**; as before the kill.
7. After send-to-queue: order **remains in CM history**.
8. **No SM SSE.** Bottom-of-queue is sort-on-read.
9. Open queue screen: **poll every 1–2 minutes** (config, default **2 min**). Same GET as cold start. Pull-to-refresh still allowed.

### P4.8b Closed

Poll while the SM queue is visible; default **2 minutes** (`SERVICE_QUEUE_POLL_SECONDS=120`). 1 minute is the other allowed value. No SSE.

### P4.9 Suggested next flow

Part 5 now captures DM → drop assignment. Next: **drop-boy trip** (maps to Part 3 pay + delivered + photo).

---

## Part 5 — DM list, auto drop assignment, customer out-for-delivery (14 Oct 2026)

### P5.1 Proposed flow

```
Any service item completed
  → order appears on DM **completed** list (already Part 4)
  → expand: ALL service items, each Completed or Pending (pending = inactive colour)

All service items completed
  → order_status = services_completed
  → customer tracker: **Ready** (existing UI label; don’t invent Processed)
  → Delivery search does **not** always start now:

  IF delivery_mode = instant
       auto drop-search starts immediately
       same engine as pickup (Part 2.6): on-shift, expanding radius, first accept wins
       Assign button **visible, disabled** until timeout
  IF delivery_mode = scheduled AND now < delivery_time_from
       **no** auto search
       Assign **visible, disabled**, copy **“Available from {time}”**
  IF delivery_mode = scheduled AND now >= delivery_time_from
       (and processing already done — including **late** plant: start **immediately**)
       auto drop-search starts
       Assign **visible, disabled** until timeout

  After timeout, no accept:
       Assign **enabled**. DM force-assign, staff cannot reject.
       SSE: “DM assigned this job to you”

Partner accepts or DM force-assigns (**captain**)
  → order_status = **out_for_delivery** immediately (do not wait for Start)
  → customer tracker: **Out for delivery**
  → map **only now**: live pin + **one** Directions path at assign
  → card: **name + phone + photo** (phone **display only**, no tel:)
```

### P5.2 Conflicts with earlier parts / today

| Topic | Was | Now |
|---|---|---|
| Instant drop start | Part 2: when **DM marks ready / dispatch** | Auto when **all service items completed**. No extra “mark ready.” |
| Scheduled drop start | At `delivery_time_from` | Same, **and** processing must already be done. If done early, wait; **DM cannot jump the queue.** |
| DM Verify | Today: `verifyOrder` then dispatch | **Not mentioned.** Extra step — likely drop (over-engineering). |
| Status after all services | `services_completed`; customer step **Ready** | Keep enum + **Ready** (you: whatever is already in the UI). |
| After partner assigned | `dispatch_assigned`, then `out_for_delivery` on **Start** | **`out_for_delivery` as soon as captain is assigned.** |
| Call/message | Part 2: **placeholder icons** | Card shows **name + phone + photo**. Phone **display only**. Call/message stay placeholders. |
| Map | Live **pin** | Pin + **one** path at assign. Off-route: see P5.6. Map **only after** assignment. |

### P5.3 What exists today

- DM list already includes `services_in_progress` + `services_completed`; `getOrderItems` has per-item status.
- `verifyOrder` + `assignDropDirect` + `dispatchOrder` require **verified_at**. New flow should **not** require verify if we drop that step.
- Drop assignment is **not** the pickup expanding-radius worker; DM starts it by dispatch. Need a **drop twin** of the pickup BullMQ job, triggered by (a) last queue item completed + instant, or (b) `delivery_time_from` if already processed.
- `dispatch_assigned` / `out_for_delivery` already in the enum. Customer tracking already has an Out for delivery step and a staff card (name; map pin if lat/lng present).
- Live location: `DeliveryStaff.current_latitude/longitude` + `updateLiveLocation`. **No** stored route polyline today.

### P5.4 Status mapping (reuse enums; don’t invent `processed`)

| Event | DB `order_status` | Customer tracker |
|---|---|---|
| Some items done, some not | `services_in_progress` | In Process |
| All items done | `services_completed` | **Ready** (existing step) |
| Searching / waiting for scheduled time | still `services_completed` | **Ready** |
| Captain assigned (accept or DM) | **`out_for_delivery`** | **Out for delivery** |
| Delivered | `delivered` after pay + photo (Part 3) | Delivered |

### P5.5 Auto vs DM assign (locked enough)

Same engine as pickup: on-shift only, expanding rings, first accept, `ASSIGNMENT_TIMEOUT_MINUTES` (5 / 10 / 20). “Send to all active partners” here means **all who match the current ring**, not every partner in the city (that would fight Part 2.6).

| Situation | Auto search | DM Assign button |
|---|---|---|
| Items still pending (**in-plant** list) | Off | Off (expand only) |
| All done + **instant** | On immediately | **Visible, disabled** until timeout |
| All done + scheduled **in the future** | Off | **Visible, disabled** — **“Available from {time}”** |
| All done + scheduled time **reached or already past** (incl. late plant) | On **immediately** | **Visible, disabled** until timeout |
| Timeout, nobody accepted | Stopped | **Enabled** (manual, cannot reject) |

### P5.6 Customer after assignment

- Tracker **Out for delivery** the moment the captain is assigned.
- Card: **name + phone + photo**. Phone is **display only** (not tap-to-call). Call/message icons stay placeholders (Part 2).
- Map **only after** assignment (agreed). Live pin from existing GPS. **One** Directions polyline at assignment (boy → customer address).

**If he changes path:** pin always follows GPS. Do **not** redraw on every tick. Off-polyline → refresh Directions **at most once every 2 minutes**. Same map for **customer and captain**. No snap-to-road engine.

### P5.7 Over-engineering

1. **New status `processed` / `processing_done` in Prisma** — skip. Keep `services_completed`; change the **label**.
2. **DM Verify** as a required click before assign — skip unless you still want a QC gate. You did not list it.
3. **Broadcast to every active partner at once** — skip. Same expanding rings as pickup.
4. **Turn-by-turn / re-route every GPS tick / snap-to-road** — skip. Path once + live pin. Off-route refresh at most every 2 min (P5.6).
5. **Map or Out for delivery before assignment** — skip. Customer stays on **Ready** until a captain exists.
6. **Second assignment worker** copied line-for-line — reuse pickup job with `deliveryType: 'drop'`.
7. **`tel:` on the phone number** — skip. Display only.
8. **DM live-tracking screen** after assign — skip. History (delivered or not) is enough.
9. **Start delivery** as a status gate — skip. Assigned = Out for delivery on both apps.

### P5.8 Questions — locked 14 Oct 2026

1. Auto-search running: Assign **visible but disabled** until timeout.
2. Scheduled still in the future: Assign visible, disabled, **“Available from {time}”**.
3. Late plant (processing after slot): auto-start **immediately**.
4. Customer label after all services: keep existing UI — **Ready**.
5. **Out for delivery as soon as the captain is assigned** (no wait for Start / leaving the plant).
6. Card: **name + phone + photo**.
7. Phone **display only**.
8. Path **once** at assign + **live pin**. Off-route: refresh Directions at most every **2 minutes**.
9. Map **only after** assignment (customer **and** captain).
10. **Two DM lists:** **in-plant** vs **ready to dispatch**.
11. After captain assigned: order **leaves** ready-to-dispatch; DM **history** shows it and whether it is **delivered or not**.
12. Captain app: **immediately Out for delivery** with tracking, path, and live location. No “sit until Start.”
13. At door: **UPI or Paid in cash**, then **one photo** by the delivery staff, then order **completed** (`delivered`). Payment before complete (Part 3).

### P5.10 DM lists (locked)

| List | What’s on it |
|---|---|
| **In-plant** | ≥1 service item completed, **not** all done (`services_in_progress`). Expand: completed vs pending (inactive). No Assign. |
| **Ready to dispatch** | All items done, **no captain yet** (`services_completed`). Assign visible: disabled during search / “Available from {time}” / enabled after timeout. |
| **History** | Captain assigned onward. Shows **delivered or not** (`out_for_delivery` vs `delivered`). |

Do not keep a live third “tracking” queue on DM unless you ask later. History is enough after assign.

### P5.9 Suggested next flow

Part 5 is **locked**. Part 6 is cancellations. Next: **Express**, or Pricing include/exclude copy.

---

## Part 6 — Cancel (14 Oct 2026)

### P6.1 Locked rules (tightened 14 Oct)

Two **different** gates:

| Action | Allowed until | Blocked from |
|---|---|---|
| **Cancel** | **Before a pickup boy is assigned** (`placed` only — waiting or still searching) | `pickup_assigned` onward |
| **Reschedule** | **Same: before a pickup boy is assigned** (`placed` only) | `pickup_assigned` onward |

**Cancel — who:** **customer** in-app. Reason **required**, then **Confirm**.

**After cancel:** order in customer **history as Cancelled**. `order_status = cancelled`. Stop pickup search / pending offers. No assigned boy to notify (cancel isn’t allowed once assigned).

**Fees:** **no booking fee later.** Nothing prepaid → no refund product.

This **supersedes** the earlier “cancel until Mark as picked up.” At-the-door draft cancel is **moot** (already assigned). T&C “after pickup may incur charges” stays wrong: cancel isn’t offered then.

**Reschedule** uses the **same gate as cancel** (SUPERSEDES “until pickup is done”): once a boy is assigned, **no** reschedule. Hide Change schedule from `pickup_assigned` onward.

### P6.2 What exists today

- Customer Orders **Cancel** is a stub dialog: *“Contact supervisor for further help.”* No customer cancel API.
- `OrderStatus.cancelled` exists. Admin order-management can set it as a status among many.
- Pickup assignment job can be cancelled (`cancelPickupAssignment`). Assignment *requests* can be cancelled (so other boys stop seeing the offer).
- Help copy already says cancel before pickup — closer to this lock than the T&C charges line.

**Gap:** real cancel API (today’s button is “contact supervisor”). Hide **Cancel** and **Change schedule** once `pickup_assigned`. Stop search on cancel. History list includes `cancelled`.

### P6.3 What cancel must do (when allowed)

1. Require **reason**, then **Confirm**
2. `order_status = cancelled`
3. Stop pickup auto-search + pending assignment offers
4. Leave active lists; appear in **history as Cancelled**

Replace the supervisor stub. Do **not** void a bill (none yet). Do **not** refund.

### P6.4 Over-engineering

1. **Cancel after assignment / after pickup / with fees** — skip.
2. **Cancel individual services** — skip. Whole order only.
3. **Refund / booking-fee engine** — skip. **No fee will be added later.**
4. Keep the **supervisor dialog** next to a working Cancel — skip. One real flow.
5. Staff/CM/boy cancel screens — skip unless you ask. Customer only.

### P6.5 Questions — locked 14 Oct 2026

1. **Customer** can cancel, and **only before the pickup boy is assigned**.
2. **Reason required**, then Confirm. (Door-draft cancel N/A — already assigned.)
3. Visible in **history as cancelled**.
4. **No booking fee later.**
5. **Reschedule** only **before the pickup boy is assigned** — same window as cancel.
6. Reschedule may change **pickup and delivery**. Constraint: delivery ≥ pickup + **`PICKUP_DELIVERY_BUFFER_DAYS`** (env, default **2**). This **is** Part 2’s `MIN_DAYS_PICKUP_TO_DELIVERY` — **one constant**, not two. Name in env: `PICKUP_DELIVERY_BUFFER_DAYS` (clearer than `buffer_day`).
7. If search is already running and they pick **new timings**: **stop search** and wait for the new `pickup_time_from` (if that time is still “now” / instant, search starts immediately).
8. Reschedule: **no reason** — date/time sheet + confirm only.
9. Cancel reason: **free text** (store on the order, e.g. `cancel_reason` — not a reasons table).

### P6.6 Reschedule behaviour (locked)

```
Customer still placed (no pickup boy)
  → can edit pickup window, delivery window, or both
  → validate delivery_date >= pickup_date + PICKUP_DELIVERY_BUFFER_DAYS
  → if a pickup search / pending offers exist:
       cancel that job + offers
       if new pickup is instant or time already reached → start search again
       else wait until new pickup_time_from
```

No reason on reschedule. After `pickup_assigned`: no reschedule, no cancel.

### P6.7 Over-engineering (add)

- A **second** env for the same +2 days (`buffer_day` *and* `MIN_DAYS_…`) — skip. One: `PICKUP_DELIVERY_BUFFER_DAYS`.
- Preset cancel-reason catalog — skip. Free text on the order row.
- Reschedule audit/reason — skip.

### P6.8 Suggested next flow

Part 6 is **locked**. Express is Part 7. Next after Express gaps: Pricing include/exclude copy.

---

## Part 7 — Express (14 Oct 2026)

### P7.1 Proposed

Express is a **per-order flag**, not a different logistics type. Legs stay **both**. Ordinary orders keep `PICKUP_DELIVERY_BUFFER_DAYS` (2). Express may allow same-day (buffer **0** for that order only).

```
Checkout: customer picks **Express**
  → no schedule step (pickup **and** delivery are **instant**)
  → is_express = true; pickup_mode = instant; delivery_mode = instant
  → buffer does not apply
  → chip on **every** order card including **customer**
  → EXPRESS_FEE (admin variable) added automatically on the pickup bill
  → cannot later change Express → ordinary

CM Send to service queue
  → new Express rows: **after older Express, before all ordinary**
```

### P7.2 Queue: one list, two bands — do **not** build two queues

You offered: jump to very front, **or** two queues per service.

**Recommended: one queue per service (as today), sort Express first.**

`ServiceQueueItem` already has `priority`. Simpler still: store `is_express` on the order (or copy onto the queue row) and:

```
ORDER BY is_express DESC, assigned_at ASC
```

| Band | Where | New item goes |
|---|---|---|
| Express | Top of the list | **Bottom of the Express band** (after older Express, before all ordinary) |
| Ordinary | Below | Bottom of the list (Part 4) |

**Why not “absolute very front” (index 0 every time):** a second Express would jump an older Express that is already waiting. That disturbs in-flight Express work. Two-band FIFO keeps “Express is urgent” without leapfrogging other Express.

**Why not two queues per service:** same data, twice the UI (tabs, empty states, poll × 2). A service man already has one list; a badge + sort is enough. Two queues is the over-build unless you later want physically separate lines in the plant.

Poll every 1–2 min still applies: an Express row appears in the Express band on the next GET. No SSE.

Any row can still be started (Part 4). Express does not lock FIFO discipline.

### P7.3 Badge

Small **Express** icon or heading on the **order card**, on **every** role list:

- Customer (orders / tracking / active card) — **yes, chip here too**
- Pickup boy, drop/delivery boy
- Collection manager (incoming, received, history)
- Service man (queue + completed)
- Distribution manager (in-plant, ready to dispatch, history)

Same treatment everywhere so nobody misses it. Don’t invent a second card layout — one chip.

### P7.4 What exists today

- `OrderType.express_delivery` in Prisma — this is a **logistics** enum alongside `both`. Part 1 locked `order_type = both` always. **Do not** reuse `express_delivery` as the type (that fights pickup+delivery). Add **`is_express` boolean** on `Order` (default false).
- Help text already mentions express + extra charges. No checkout flag, no fee line, no queue sort, no badge.
- Queue sort today: `priority ASC, assigned_at ASC` — all ordinary.

### P7.5 Everything else stays the same

Pickup/drop expanding-radius, timeouts, CM/DM force-assign, door-count, bill, cancel **before pickup assigned**, UPI/cash, photo, DM lists — unchanged.

**Express has no schedule**, so **Change schedule is hidden** on Express (nothing to reschedule). Cancel before pickup assigned still applies. Express **cannot** be converted to ordinary.

### P7.6 Over-engineering

1. **Two physical queues per service** (ordinary + express) — **skip** unless you insist on split UI. One list, two-band sort.
2. **Newest Express always index 0** — skip. FIFO **inside** the Express band.
3. **`order_type = express_delivery`** instead of `both` — skip. `is_express` on a `both` order.
4. Setting **`PICKUP_DELIVERY_BUFFER_DAYS=0` globally** — skip. Ordinary stays 2. Express orders only use 0.
5. Faster assignment rings / shorter timeout for Express **unless you ask** — you said rest remains the same.
6. Per-service “Express available” matrix — skip. Allowed on **any service mix**.
7. Schedule UI / converting Express → ordinary — skip. Sticky until cancel.
8. Second invoice for the fee — skip. Same bill as delivery fee.

### P7.7 Fee (locked)

**`EXPRESS_FEE`**: admin-editable variable (₹). Added **automatically** on the bill at **Mark as picked up**, with the delivery fee. Ordinary orders: 0.

### P7.8 Questions — locked 14 Oct 2026

1. **No schedule on Express.** Pickup and delivery are both **instant**.
2. **`EXPRESS_FEE`** admin variable, auto on the bill.
3. **Customer cards** get the Express chip too.
4. New Express queue row: **after older Express**, before ordinary.
5. **Cannot** change Express to ordinary (sticky). Cancel before pickup assigned still OK. No Change schedule.
6. Express allowed on **any service mix**.

### P7.9 Suggested next

Part 7 is **locked**. Pricing catalogue is Part 8.

---

## Part 8 — See pricing (14 Oct 2026)

### P8.1 Locked (this batch)

**SUPERSEDED:** no Home **See pricing** footer card. Catalogue is the **Pricing bottom-nav tab only**.

That screen lists:

1. **All categories** (Regular Wash, Pro Clean, Home Linens, Luxury Care — same as booking)
2. Then **services** in the selected category
3. Then, for the selected service, **both**:
   - **₹/kg** for that service (`Service.per_kg_price`)
   - **each cloth item** with its per-piece / per-pair price (`ClothesItem.per_unit_price`)

Not either-or. One service shows kg price **and** the cloth list.

Data is a **read** of the existing catalogue. Do **not** create a second pricing table.

### P8.2 Entry (locked)

**Pricing bottom-nav tab only.** Do **not** put See pricing in the Home footer. One catalogue UI.

### P8.3 What exists today

- No dedicated Pricing screen. Home has category tiles that open **booking** sheets, not a price list.
- `Service.per_kg_price` + `ClothesItem.per_unit_price` already power booking. Pricing should reuse those APIs.

### P8.4 Over-engineering

1. **CMS / new Pricing table** — skip. Catalogue prices are the prices.
2. **Includes** copy is static (or fields on `Service` if they already exist). Don’t build a CMS for it.
3. **Select / add-to-cart from Pricing** — skip. Browse-only.
4. **Per-service either kg or pieces only** — skip. You asked for **both** on each service.

### P8.5 Questions

1. **Pricing tab — yes.** No Home footer card.
2. **Includes** bullets per service — **yes**. (“Not included” is the matching Layyr column — show if copy exists; don’t block the screen on a CMS.)
3. **Browse-only.** No Select / add-to-cart from Pricing. Booking stays Home category tiles.
4. **Coming Soon not required** — don’t show them on Pricing.
5. Footer is How we work + brand strip only.

### P8.6 Suggested next

Part 8 is **locked**. How-we-work is Part 9.

---

## Part 9 — How we work (14 Oct 2026)

### P9.1 Locked

A **How we work** screen that **briefly** describes each step **from pickup to delivery**, each with an **image**.

Entry: Home **footer** (with brand strip). Pricing is **not** in this footer. This **supersedes** Part 1’s 3-step story and its “pay after weighing” line. Pay is **at delivery** (Part 3).

Not a live tracker. Not tied to an order. Static explainer.

### P9.2 Steps (locked) — same 6 as the customer tracker

Keep copy short; one image each. **New designer images later;** until then **placeholders** (related stock / existing assets). English only.

| # | Step | One-line intent |
|---|---|---|
| 1 | Out for pickup | Partner comes to the door |
| 2 | Counted at door | Items / kg listed in front of you; bill generated; nothing to pay yet |
| 3 | In process | Cleaned at the hub |
| 4 | Ready | All services done |
| 5 | Out for delivery | Partner on the way (Express chip if that order type — **not** on this static screen) |
| 6 | Delivered | Pay on phone (UPI / cash fallback); done |

Do not fold steps. Don’t invent extra plant steps the customer never sees.

### P9.3 What exists today

No How-we-work screen. Part 1 only specified it from Layyr-style screenshots.

### P9.4 Over-engineering

1. **CMS / admin-editable steps** — skip. App assets + copy in the client (or a simple static list). Designer PNGs in `assets/`.
2. **Video / lottie per step** — skip unless you already have them. Still images.
3. **Wiring this to a live order** — skip. Tracking already does that.
4. **Pay after weighing** copy — skip. Wrong now.
5. **Brand-strip CMS** — not this screen unless you still want a separate footer block (P9.5).

### P9.5 Questions — locked 14 Oct 2026

1. **6 steps** (table above), matching the tracker.
2. **New designer images later.** For now: placeholders / related art. Swap files when you send them; don’t block the screen on final art.
3. Home **footer:** **How we work** only (plus brand strip). **No See pricing** in the footer. **SUPERSEDED.**
4. **Brand strip / tagline** under that as well (Part 1 §2.6b).
5. **English only** for now. No i18n pass.

### P9.6 Home footer (locked)

```
Home scroll end
  → How we work  (6 steps + images)
  → Brand strip
Pricing = bottom nav tab only (Part 8)
```

### P9.7 Suggested next

Part 9 is **locked**. Capture for this redesign is **complete enough to implement** (Pricing P8 closed).

## Part 10: Backend decisions

Locked while the backend was built:

- Ring distance is haversine on the backend. The Flutter app owns Google Directions and the polyline.
- After a search times out, a manager may force-assign any verified active delivery staff. Rings themselves notify on-shift staff only.
- A cart has one line per service.
- Config is read from the database, then the environment, then the code default.
- Cash is allowed only after a UPI attempt has failed, expired, or been cancelled.
- Delivery fee and express fee are snapshotted onto the bill at Mark as picked up.
- `Service.includes` and `Service.excludes` are the Pricing-tab bullets.
- Door and drop photos go to Cloudinary, not Postgres.
- A service is bookable without a service man. Submit-to-services still requires one.



