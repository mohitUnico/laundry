# Phase 11: Notifications, admin, metrics

**Size:** M  **Depends on:** 10  **Migration:** `v2_p11_metrics_review` (only if triggers/views need changes)

## Goal

Every event in the spec sends the right message to the right audience, the admin can manage v2 orders, and dashboards read the new statuses.

Spec: [07-event-catalogue.md](../diagrams/07-event-catalogue.md), [08-notifications-and-config.md](../diagrams/08-notifications-and-config.md).

## Tasks

1. **Notification matrix**: build a table-driven `notification-events.js` mapping `event -> audiences -> channels -> template`. Events: order placed, pickup offered, pickup assigned, picked up, bill ready, submitted to CM (CM), received at plant, services started, services completed, drop offered, out for delivery, payment received, payment failed, delivered, cancelled (customer + offered staff), reschedule (engine restart, staff offers withdrawn), assignment timeout (CM or DM only).
2. Channels: SSE for staff in-app, FCM push, WhatsApp status message for key customer milestones (keep the existing providers; no new vendor).
3. Remove `dispatch_assigned` and `payment_pending` customer texts; add `payment_completed`, `submitted_to_cm`.
4. **Dedupe**: one notification per `(order, event, recipient)`; engine retries must not repeat pushes.
5. **Admin**
   - Admin order list/detail: add filters `is_express`, status, mode, date range; show assignment history (requests + recipients), bill, payment attempts.
   - Remove the old status-transition admin validator; replace with the central guard. Admin override endpoint (if kept) goes through `assertTransition` and requires a reason, and is audit logged.
   - Admin can read and edit config (Phase 1).
6. **Metrics**: review the DB triggers/functions that maintain `MartDailyMetrics`/daily aggregates against the new statuses (`delivered` replaces `closed` for completion); add express count and cancelled-with-reason breakdown if the dashboard shows them. Remove references to `pricing_model`, `billing_status`.
7. Add **assignment health** admin endpoint: searches in progress, timed out and not yet assigned (what managers need to act on).

## Tests

- Matrix test: simulate each event and assert the audience, channel and no duplicates (providers mocked).
- Admin list filters and detail payload; override uses the transition guard.
- Metrics: place and deliver orders in the test DB, assert aggregate rows and revenue equal the bills of delivered orders.
- Timeout event goes to CM for pickup and DM for drop, not to the customer.

## Exit checklist

- [ ] No stale notification text for removed statuses.
- [ ] Dashboard queries run clean against the new enum.
- [ ] Postman folder "Phase 11".
