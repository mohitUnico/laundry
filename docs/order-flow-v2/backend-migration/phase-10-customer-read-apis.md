# Phase 10: Customer read APIs

**Size:** M  **Depends on:** 9  **Migration:** `v2_p10_service_copy` (adds `includes`/`excludes`)

## Goal

The customer app gets stable, ready-to-render responses: a 6-step tracker, action flags, order detail, order history, and pricing with "what is included".

Spec: Part 1 (P1.5 to P1.7), Part 6, Part 8, diagrams 6.x and 9.

## Schema changes

```prisma
model Service {
  includes String[] @default([])
  excludes String[] @default([])
}
```

Seed gets sample copy for each service.

## Tasks

1. **Tracker mapper** `src/services/order-tracker.js` (single source of truth):

   | Step | Label | Order status |
   |---|---|---|
   | 1 | Out for pickup | `placed` (pre-assignment: label "Finding a partner" via `substatus`), `pickup_assigned` |
   | 2 | Pickup done | `picked_up` |
   | 3 | In process | `submitted_to_cm`, `received_by_collection`, `submitted_to_services`, `services_in_progress` |
   | 4 | Ready | `services_completed` |
   | 5 | Out for delivery | `out_for_delivery` |
   | 6 | Delivered | `delivered` |

   `cancelled` returns `tracker: null` with `cancelled: { reason, at }`.
2. **Flags** on every order DTO: `canCancel` and `canReschedule` (only `placed`; reschedule false for Express), `canPay` (bill unpaid and status `picked_up` to `out_for_delivery`), `isExpress`, `pickupMode`, `deliveryMode`.
3. **Endpoints**
   - `GET /orders?bucket=active|history&page&limit` (history = delivered + cancelled).
   - `GET /orders/:orderId`: schedule, addresses, per-service lines (per-kg weight x price; per-unit lines with qty x snapshot), bill (when present), tracker, flags, captain block when assigned.
   - `GET /orders/:orderId/tracking`: captain name, phone, photo, live location (from `current_latitude/longitude`), `directionsRefreshSeconds`, ETA is **not** computed server-side (the app asks Google).
   - `GET /catalog/pricing` (or extend the service catalogue): services with `per_kg_price`, per-unit item prices, `includes`, `excludes`, and `bookable` / `unavailableReason` from the Phase 7A rule. Read live from the database (no cache) so admin catalogue edits show immediately.
4. Remove dead response fields: old `order_type`, `pricing_model`, `billing_status`, "verified" fields.
5. Authz: customer sees only their orders; staff see only through staff routes.

## API contract

| Method | Path | Notes |
|---|---|---|
| GET | `/orders?bucket=` | active / history |
| GET | `/orders/:orderId` | full detail with tracker and flags |
| GET | `/orders/:orderId/tracking` | captain + location |
| GET | `/catalog/pricing` | pricing with includes/excludes |

## Tests

- Table-driven test: each of the 11 statuses maps to the correct step and flags.
- Detail shows per-service lines before pickup (no money) and after pickup (bill).
- History bucket includes cancelled and delivered only; pagination stable.
- Another customer's order -> 404.
- Tracking hidden before assignment; visible with captain details after.

## Exit checklist

- [ ] Every status covered by the mapper test.
- [ ] Postman folder "Phase 10" with sample responses saved.
