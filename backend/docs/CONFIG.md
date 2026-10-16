# Config

Keys live in `app_config`. Resolution order is database, then environment variable, then the code default. Reads are cached for 30 seconds and the cache clears on write.

Admin: `GET /api/v1/admin/config` and `PUT /api/v1/admin/config/:key` (admin or owner).

The customer app reads the public subset from `GET /api/v1/config`.

| Key | Default | Meaning |
|---|---|---|
| ASSIGNMENT_TIMEOUT_MINUTES | 10 | Whole ring search. Allowed 5, 10, 20 |
| ASSIGNMENT_RANGE_SLICES | 5 | How many rings |
| ASSIGNMENT_MAX_RANGE_KM | 10 | Outer ring |
| PICKUP_DELIVERY_BUFFER_DAYS | 2 | Calendar days in Asia/Kolkata between pickup and delivery dates |
| DELIVERY_FEE | 0 | Flat fee snapshotted onto the bill |
| EXPRESS_FEE | 0 | Added when the order is Express, snapshotted |
| SERVICE_QUEUE_POLL_SECONDS | 120 | Service-man queue poll hint |
| DIRECTIONS_REFRESH_SECONDS | 120 | Client Directions refresh hint |

Fee changes after pickup do not rewrite an existing bill.
