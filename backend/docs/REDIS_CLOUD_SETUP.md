# Redis Cloud Setup (No Persistence)

Backend is configured for **Redis Cloud** as the queue store. The free tier has **no persistence**; the catch-up job is the safety net.

## 1. Get Redis Cloud

1. Sign up: https://redis.com/try-free/
2. Create a subscription (e.g. **AWS**, same region as your app).
3. Create a **database** (free tier is enough).
4. Copy the **Public endpoint** and **password** (or the full connection URL).

## 2. Configure backend

In `backend/.env`:

```env
PICKUP_ASSIGNMENT_USE_QUEUE=true
REDIS_URL=redis://default:YOUR_PASSWORD@YOUR_REDIS_CLOUD_HOST:YOUR_PORT
```

Example:

```env
REDIS_URL=redis://default:abc123xyz@redis-12345.redis.cloud:12345
```

No other Redis setup is required.

## 3. How it works (no persistence)

- **Queue**: Jobs are stored in Redis Cloud. If Redis restarts (e.g. free tier), scheduled jobs in memory are lost.
- **Catch-up job**: Runs **every 5 minutes**, finds orders that should have been assigned but weren’t, and re-queues them. So missed assignments are fixed within 5 minutes.
- **Cleanup**: Completed/failed jobs are removed sooner to stay within free tier memory (~30MB).

## 4. Start the app

```bash
cd backend
npm start
```

You should see:

- `Pickup assignment worker started (queue-based mode)`
- `Pickup assignment catch-up job started (safety net)`
- `Redis connected` / `Redis ready`

## 5. Optional env

| Variable | Default | Description |
|----------|---------|-------------|
| `PICKUP_ASSIGNMENT_CATCHUP_ENABLED` | `true` | Set `false` to disable catch-up. |
| `PICKUP_ASSIGNMENT_CATCHUP_INTERVAL_MS` | `300000` (5 min) | How often catch-up runs. |

No persistence is required; the design assumes Redis Cloud (including free tier) and relies on the catch-up job.
