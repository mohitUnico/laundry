# WashBee order flow v2

Status: this folder describes the **redesigned** booking flow (docs only, 4 Nov 2026). The redesign is not built yet: no backend, schema, test or Flutter changes have been made for it. The earlier v2 backend work on `laundry_test` predates the redesign. The real database has not been migrated.

Current design for the end-to-end order flow: **customer books from the pickup cards (or the cart) → pickup boy records services and counts at the door → CM verifies → service men process → DM dispatches → captain delivers and collects payment.**

Start with the spec, use the diagrams to verify, use the prototype for UI.

## Contents

| What | Where |
|---|---|
| Current spec (booking, slots, assignment, door count, plant, payment, config, open items) | [order-flow-spec.md](order-flow-spec.md) |
| Customer-facing "How we work" copy (7 steps) | [how-we-work.md](how-we-work.md) |
| Quick overview pack (who-does-what, spine, status tracker, Express) | [diagrams/00-overview-pack.md](diagrams/00-overview-pack.md) |
| Actors, apps, use cases | [diagrams/01-actors-and-use-cases.md](diagrams/01-actors-and-use-cases.md) |
| Swimlane flows (booking, plant, drop and pay, cancel/reschedule) | [diagrams/02-swimlane-flows.md](diagrams/02-swimlane-flows.md) |
| Sequence diagrams (7) | [diagrams/03-sequence-diagrams.md](diagrams/03-sequence-diagrams.md) |
| State machines (7) | [diagrams/04-state-machines.md](diagrams/04-state-machines.md) |
| Data model (ER, with NEW fields) | [diagrams/05-data-model.md](diagrams/05-data-model.md) |
| Status catalogue and list visibility | [diagrams/06-status-catalogue.md](diagrams/06-status-catalogue.md) |
| Event catalogue (27 events) | [diagrams/07-event-catalogue.md](diagrams/07-event-catalogue.md) |
| Notifications and config variables | [diagrams/08-notifications-and-config.md](diagrams/08-notifications-and-config.md) |
| Screen map and spec-vs-code deltas | [diagrams/09-screen-map-and-code-deltas.md](diagrams/09-screen-map-and-code-deltas.md) |
| All diagrams in one browser page (zoomable) | [diagrams/viewer.html](diagrams/viewer.html) |
| Designer click-through prototype (42 screens, all roles). Shows the previous booking flow; not yet updated. | [ui-prototype/index.html](ui-prototype/index.html) (`#gallery` shows all at once) |

## How to view

- **Markdown + Mermaid:** open any `.md` here in Cursor / VS Code preview or on GitHub.
- **Viewer page and prototype:** open the `.html` file in a browser. The viewer needs internet (Mermaid loads from a CDN). The prototype is offline.
- If a local server is needed: `python -m http.server 8780` from this folder.

## Key rules (one-screen summary)

- Statuses on the new path: `placed → pickup_assigned → picked_up → submitted_to_cm → received_by_collection → submitted_to_services → services_in_progress → services_completed → out_for_delivery → delivered` (plus `cancelled`). `dispatch_assigned`, `payment_pending`, `closed` are not used.
- Two ways to book: pickup cards (no cart, the pickup boy records all services) or category tiles → cart → Delivery Options. `cart_id` is optional.
- Each leg is instant or scheduled on its own. Scheduled means a date plus an admin-managed slot (`open`, `too_busy`, `closed`; only `open` can be booked). A scheduled search starts at the slot start.
- Express is queue priority, a badge and `EXPRESS_FEE` only. It has a shorter buffer and does not change pickup or delivery.
- Tracking opens right after "Order confirmed", at `placed` ("finding a partner").
- Addresses are checked against `SERVICE_AREA_KM` when added or edited, not at order creation.
- Cancel and reschedule only while `placed` (before any pickup partner is assigned).
- Pickup/drop search: expanding radius rings, on-shift staff only, first accept wins, manager force-assign only after timeout, force-assigned staff cannot reject.
- Bill is written at "Mark as picked up" (services + `DELIVERY_FEE` + `EXPRESS_FEE`). Customer sees it but cannot pay until `out_for_delivery`.
- Payment: UPI intent via PSP, one existing `Coupon`; cash only as the captain's fallback after UPI fails. `delivered` is blocked until payment is completed, plus one drop photo.
- Service men: one queue per service, ordered `is_express DESC, assigned_at ASC`, poll every 2 min, no SSE, no mark-for-later.

## Config variables

`ASSIGNMENT_TIMEOUT_MINUTES` (5), `ASSIGNMENT_RANGE_SLICES` (5), `ASSIGNMENT_MAX_RANGE_KM`, `PICKUP_DELIVERY_BUFFER_DAYS` (2, ordinary), `EXPRESS_BUFFER_DAYS` (1), `SERVICE_AREA_KM`, `DELIVERY_FEE`, `EXPRESS_FEE`, `SERVICE_QUEUE_POLL_SECONDS` (120), Directions refresh (max every 2 min).

## Status of this folder

Docs only. **No app code has been changed.** Implementation tasks should be derived from [diagrams/09-screen-map-and-code-deltas.md](diagrams/09-screen-map-and-code-deltas.md) and the spec, one part at a time. Open decisions are listed in section 12 of the spec.
