# Debugging the Pickup Assignment Job

Use this checklist when the **polling-based** automatic pickup assignment (SSE broadcast to delivery staff) is not working.

## Quick start (polling mode)

1. **Use polling, not webhook:** Leave `USE_WEBHOOK_PICKUP_ASSIGNMENT` unset or set to `false`. Do **not** set it to `true` if you want the in-process polling job.
2. **Call the status endpoint** (with admin/owner/manager JWT):
   ```bash
   GET /api/v1/admin/delivery-ops/pickup-assignment-status
   ```
   Check: `webhookMode: false`, `pollingActive: true`, and `eligibleOrderCount` / `eligibleOrderIds`.
3. **Turn on debug logs:** In `.env` set `PICKUP_ASSIGNMENT_DEBUG=true`, restart the server. You’ll see a log line every run with `eligibleCount` and `orderIds`.

If `eligibleOrderCount` is 0, no orders currently match the job criteria (see section 3). If it’s > 0 but staff don’t see requests, check logs for errors and that staff are “active” and connected to SSE (sections 4–5).

---

## 1. Confirm the job is running

**Check server logs on startup.** You should see one of:

- `📋 Starting pickup assignment polling job (webhook mode disabled)` → polling job **is** started.
- `🔗 Pickup assignment webhook mode enabled - polling job disabled` → in-process job is **not** running (webhook/pg_cron is used instead).

If you want the **in-process** job (every 2 minutes), ensure:

- `USE_WEBHOOK_PICKUP_ASSIGNMENT` is **not** set to `true` (or unset it).
- `PICKUP_ASSIGNMENT_JOB_ENABLED` is **not** set to `false`.

After that, you should see:

- `Pickup assignment job scheduled` with `intervalMs: 120000` (or your configured value).

## 2. Use the status endpoint

Call the debug endpoint (with an admin/owner/manager JWT):

```bash
GET {{base_url}}/api/v1/admin/delivery-ops/pickup-assignment-status
Authorization: Bearer <admin-or-manager-jwt>
```

Response tells you:

| Field | Meaning |
|-------|--------|
| `jobEnabled` | Job is allowed to run (not disabled by env). |
| `webhookMode` | If true, polling job is not started. |
| `pollingActive` | In-process timer is actually running. |
| `intervalMs` | How often the job runs (e.g. 120000 = 2 min). |
| `eligibleOrderCount` | Number of orders that match the job’s criteria **right now**. |
| `eligibleOrderIds` | Those order IDs (so you can check them in the DB). |
| `criteria` | Short reminder of the selection rules. |

**If `eligibleOrderCount` is 0** → no orders currently match. Go to step 3.  
**If `eligibleOrderCount` > 0 but staff never see requests** → job may be failing when creating requests, or SSE/FCM not reaching staff; check step 4 and 5.

## 3. Why might no orders be eligible?

The job only considers orders that satisfy **all** of:

1. `order_status = 'placed'`
2. `pickup_time_from IS NOT NULL` and `pickup_time_from <= NOW()`
3. No **pending, non-expired** pickup assignment request for that order (no row in `delivery_assignment_requests` for the order’s pickup delivery with `delivery_type = 'pickup'`, `status = 'pending'`, `expires_at > NOW()`)
4. No pickup delivery already in progress (no `delivery` row for that order with `delivery_type = 'pickup'` and `delivery_status` in `assigned`, `en_route`, `reached`)

**Checks in the database:**

- Orders in `placed` with `pickup_time_from` in the past:
  ```sql
  SELECT order_id, order_status, pickup_time_from, pickup_time_to
  FROM orders
  WHERE order_status = 'placed' AND pickup_time_from IS NOT NULL AND pickup_time_from <= NOW();
  ```
- For one of those `order_id`, see if there is already a pending request or an active pickup delivery (as above). If there is, the job will correctly skip that order.

Fix: ensure test orders have `order_status = 'placed'`, `pickup_time_from` set to a time in the past, and no existing pending pickup request / assigned pickup delivery.

## 4. Enable debug logging

Set in `.env`:

```env
PICKUP_ASSIGNMENT_DEBUG=true
```

Restart the server. Every run of the job will log:

- `Pickup assignment job tick` with `eligibleCount` and `orderIds`.

So you can see:

- That the job runs every `intervalMs`.
- How many orders it finds each time.

Turn this off in production if you don’t want extra log volume.

## 5. Errors when creating assignment requests

If the status endpoint shows `eligibleOrderCount > 0` but no assignment requests appear for staff:

- **Logs:** Look for `Failed to create pickup assignment request` or `Pickup assignment job failed` (and the error message/stack). Fix the underlying error (e.g. missing address, no active delivery staff, validation error from `createAssignmentRequest`).
- **Active staff:** The job (and the admin “create assignment request” endpoint) notifies **active** delivery staff. If there are no active staff (e.g. no one on a shift / no one with an open SSE connection), no one will get the request. Check how “active” is defined (e.g. `getAllActiveDeliveryStaff` in delivery-operations.service) and that at least one staff is active when you test.
- **SSE:** Staff receive the request via SSE on `/api/v1/delivery-staff/events`. Ensure the management/delivery app is connected to that SSE endpoint when you expect to see the request.

## 6. Quick checklist

- [ ] `USE_WEBHOOK_PICKUP_ASSIGNMENT` is not `true` (if you want the in-process job).
- [ ] `PICKUP_ASSIGNMENT_JOB_ENABLED` is not `false`.
- [ ] Startup log shows “Starting pickup assignment polling job” and “Pickup assignment job scheduled”.
- [ ] `GET .../pickup-assignment-status` shows `pollingActive: true`, `webhookMode: false`.
- [ ] Test order has `order_status = 'placed'`, `pickup_time_from` in the past, and no pending pickup request / assigned pickup delivery.
- [ ] `eligibleOrderCount` from the status endpoint is > 0 for that order.
- [ ] `PICKUP_ASSIGNMENT_DEBUG=true` shows “job tick” logs every 2 minutes (or your `intervalMs`).
- [ ] No errors in logs when the job runs; if there are, fix the error (e.g. createAssignmentRequest, active staff, SSE).
