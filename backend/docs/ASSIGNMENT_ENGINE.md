# Assignment engine

Pickup and drop share one BullMQ queue, `delivery-assignment`. Redis is required. A 60 second catch-up job restarts searches and advances slices if a job is lost.

## Rings

`ASSIGNMENT_RANGE_SLICES` divides `ASSIGNMENT_MAX_RANGE_KM`. Slice `i` offers on-shift, verified, active staff whose haversine distance from the leg origin is within `i / N * max`. Pickup origin is the customer pickup address. Drop origin is the customer drop address. Staff with no location are skipped by rings and still appear on the manager list with distance unknown.

The first accept wins. The delivery row is updated only while `staff_id` is null. The order moves only while it is still `placed` (pickup) or `services_completed` (drop).

## When a search starts

- Pickup: immediately for instant or Express, or when `pickup_time_from` is due. Otherwise a delayed `assign-start:{orderId}:pickup` job.
- Drop: when the last service completes. Instant and Express start now. A future scheduled window waits until `delivery_time_from`. The DM list shows `available_from` until then.

## Timeout

When the request expires, assign state becomes `enabled`. The collection manager (pickup) or distribution manager (drop) may force-assign any verified active delivery staff, on shift or not. Before timeout the API returns `409 ASSIGNMENT_NOT_ENABLED`.

Job ids: `assign:{requestId}:slice:{i}`, `assign:{requestId}:timeout`, `assign-start:{orderId}:{pickup|drop}`.
