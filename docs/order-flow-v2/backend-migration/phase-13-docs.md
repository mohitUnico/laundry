# Phase 13: Documentation

**Size:** M  **Depends on:** 12  **Migration:** none

## Goal

Remove order-flow documentation that describes the old design, rewrite the docs that must survive, and add new backend docs. Scope is **order flow only**; auth, email, WhatsApp, Redis and registration guides are untouched (locked decision).

Nothing is deleted before this phase.

## 1. Delete (describe the old flow only)

- `backend/docs/new_order_creation_flow.md`
- `backend/docs/WORKFLOW_DIAGRAMS.md`
- `backend/docs/NEW_ARCHITECTURE_OVERVIEW.md`
- `backend/docs/ARCHITECTURE_V2_SUMMARY.md`
- `backend/docs/MIGRATION_GUIDE.md`
- `backend/docs/DOCUMENTATION_UPDATE_SUMMARY.md`
- `backend/VERIFICATION_NO_PAYMENT_PENDING.md`
- `backend/CLEANUP_SUMMARY.md`
- `backend/OBSOLETE_FILES_REPORT.md`

Before each delete: grep for inbound links and fix them.

## 2. Rewrite

| File | Becomes |
|---|---|
| `backend/docs/PICKUP_ASSIGNMENT_QUEUE_SETUP.md` | `ASSIGNMENT_ENGINE.md` (rings, jobs, catch-up, Redis requirement) |
| `backend/docs/DOCUMENTATION_INDEX.md` | new index |
| `backend/docs/README.md`, `backend/README.md`, root `README.md` | status machine, endpoints overview, run/test steps |
| `backend/docs/SERVICE_CATALOG_RELATIONSHIPS.md` | services-only booking, includes/excludes |
| `.cursor/rules/core/vocabulary.mdc` | lifecycle: 11 statuses, new terms (Express, ring, handshake) |
| `.cursor/rules/core/product-overview.mdc` | new flow summary |
| `.cursor/ctx-store/architecture/technical/backend-architecture.md` | engine, config, payments layers |
| Postman collection | v2 only |

## 3. Keep (review only)

Auth, email, WhatsApp, Redis, registration guides; `scripts/EC2*`. Fix only references to removed env vars or endpoints.

## 4. New docs (`backend/docs/`)

- `ORDER_FLOW.md`: the status machine, who can do what, one diagram per leg (point to `docs/order-flow-v2/diagrams/`).
- `API_REFERENCE_V2.md`: every endpoint by persona, request/response examples taken from Postman.
- `ASSIGNMENT_ENGINE.md` (see above).
- `PAYMENTS.md`: provider interface, webhook, cash fallback, coupons.
- `CONFIG.md`: keys, defaults, who may change, how caching works.
- `TESTING.md`: running unit/integration/e2e, fixtures, test clock.

## 5. Spec housekeeping

- Add **Part 10: Backend decisions** to `docs/order-flow-v2/order-flow-spec.md`: haversine for rings (client uses Directions), `any_verified` after timeout, one cart line per service, config store precedence, cash fallback strictness, delivery fee/express fee snapshot, includes/excludes fields, Cloudinary for photos.
- Update the status line in `docs/order-flow-v2/README.md` to "backend implemented".
- `WashBee_Proposal_Report.txt`: **ask the user** whether to keep, archive or delete.

## Exit checklist

- [ ] No broken links (run a link check over `docs/`, `backend/`, root README).
- [ ] Grep for removed terms (`dispatch_assigned`, `payment_pending`, `mark_for_later`, `PICKUP_ASSIGNMENT`) in docs returns nothing.
- [ ] New docs reviewed by running the Postman collection against them.
