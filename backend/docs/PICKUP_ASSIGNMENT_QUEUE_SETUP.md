# Pickup Assignment Queue Setup Guide

This guide explains how to set up and use the **delayed job queue** system for automatic pickup assignment, replacing the polling-based approach.

## Overview

The queue-based pickup assignment system uses **BullMQ** (job queue) with **Redis Cloud** to schedule pickup assignment jobs that run at the exact `pickup_time_from` time for each order. This eliminates the need for periodic database polling.

## Architecture

1. **Order Creation/Update**: When an order is created or confirmed with `pickup_time_from`, a delayed job is scheduled in Redis
2. **Worker Process**: A BullMQ worker listens for jobs and processes them when their scheduled time arrives
3. **Assignment**: The worker calls the same `createAssignmentRequest` logic used by the polling job (SSE broadcast + FCM to delivery staff)

## Prerequisites

**Redis Cloud (recommended, no persistence)**  
1. Sign up at https://redis.com/try-free/  
2. Create a database (free tier: 30MB)  
3. Backend is tuned for no persistence: catch-up job runs every **5 minutes** as the safety net.  

See [REDIS_CLOUD_SETUP.md](./REDIS_CLOUD_SETUP.md) for a short setup guide.

**Node.js Dependencies**: `bullmq` and `ioredis` (already added to package.json)

## ⚠️ Important: Free Redis Cloud Limitation

**Free Redis Cloud tier does NOT support data persistence**. This means:
- Scheduled jobs are stored in memory only
- If Redis restarts or loses data, scheduled jobs will be lost
- Jobs that were scheduled but not yet processed will need to be re-queued

### Mitigation: Catch-Up Job (Safety Net)

A **catch-up job** is automatically enabled when queue mode is active. It:
- Runs every 15 minutes (configurable)
- Finds orders that should have been assigned but weren't
- Re-queues them automatically
- Acts as a safety net for Redis data loss or worker downtime

**For production with high reliability requirements**, consider:
1. **Upgrading Redis Cloud** to a paid plan with persistence (AOF/RDB)
2. **Running Redis on EC2** with persistence enabled (see alternatives below)
3. **Keeping catch-up job enabled** (default) as a safety net

## Setup Steps

### 1. Install Dependencies

```bash
cd backend
npm install
```

This will install `bullmq` and `ioredis` automatically.

### 2. Configure Redis

**Option A: Redis Cloud (Quick Setup)**

1. Sign up for Redis Cloud: https://redis.com/try-free/
2. Create a subscription (choose AWS, same region as your EC2 instance)
3. Create a database (30MB free tier is sufficient)
4. Copy the connection string from the database dashboard
   - Format: `redis://default:password@host:port`
5. ⚠️ **Note**: Free tier has NO persistence - catch-up job will handle missed orders

**Option B: Redis on EC2 (Recommended - Full Persistence)**

1. Follow the guide: [REDIS_EC2_SETUP.md](./REDIS_EC2_SETUP.md)
2. Install Redis on your EC2 instance
3. Enable AOF persistence (recommended)
4. Set a password for security
5. Use connection string: `redis://:password@localhost:6379`

### 3. Configure Environment Variables

Add to `backend/.env`:

```env
# Enable queue-based pickup assignment
PICKUP_ASSIGNMENT_USE_QUEUE=true

# Redis Cloud connection string (Option A)
# REDIS_URL=redis://default:your-password@redis-xxxxx.redis.cloud:xxxxx

# OR Redis on EC2 connection string (Option B - Recommended)
REDIS_URL=redis://:your-password@localhost:6379
```

**Important**: 
- Set `PICKUP_ASSIGNMENT_USE_QUEUE=true` to enable queue-based assignment
- When queue mode is enabled, the polling job (`startPickupAssignmentJob`) is automatically disabled
- The webhook mode (`USE_WEBHOOK_PICKUP_ASSIGNMENT`) can coexist but is not needed

### 4. Start the Application

```bash
npm start
# or
npm run dev
```

You should see:
```
✅ Pickup assignment worker started (queue-based mode)
Redis connected
Redis ready
```

## How It Works

### Order Creation Flow

1. Customer creates order with `pickup_time_from` (e.g., "2025-02-12 14:00:00")
2. After order is saved to database, `schedulePickupAssignment()` is called
3. A delayed job is added to Redis with:
   - **Job ID**: `pickup-assignment-{orderId}` (ensures one job per order)
   - **Delay**: Calculated from `pickup_time_from` - current time
   - **Payload**: `{ orderId, deliveryType: 'pickup' }`

### Job Processing Flow

1. When `pickup_time_from` arrives, BullMQ makes the job available
2. Worker picks up the job and calls `processPickupAssignment()`
3. Worker re-checks order eligibility:
   - Order exists
   - Order status is `placed`
   - No pending pickup assignment request
   - No assigned pickup delivery
4. If eligible, calls `createAssignmentRequest()` (same logic as polling job)
5. SSE events and FCM notifications are sent to delivery staff

### Order Update Flow

If `pickup_time_from` is changed:
1. Old job is removed (using jobId: `pickup-assignment-{orderId}`)
2. New job is scheduled with the updated time
3. Ensures only one job exists per order

## Monitoring

### Queue Statistics

You can check queue stats programmatically:

```javascript
const { getQueueStats } = require('./src/queues/pickup-assignment.queue');

const stats = await getQueueStats();
console.log(stats);
// {
//   waiting: 0,
//   active: 1,
//   completed: 150,
//   failed: 2,
//   delayed: 5
// }
```

### Logs

The worker logs all job processing:
- `Processing pickup assignment job` - Job started
- `Pickup assignment request created via queue` - Success
- `Pickup assignment job failed` - Failure (will retry)
- `Order not in placed status, skipping` - Order already processed

### Redis Cloud Dashboard

Monitor in Redis Cloud dashboard:
- Memory usage
- Connection count
- Command rate
- Slow queries

## Troubleshooting

### Worker Not Starting

**Error**: `Redis connection error`

**Solutions**:
1. Check `REDIS_URL` is correct in `.env`
2. Verify Redis Cloud database is active
3. Check network connectivity (firewall/security groups)
4. Test connection: `redis-cli -h <host> -p <port> -a <password>`

### Jobs Not Processing

**Symptoms**: Jobs are scheduled but not running

**Solutions**:
1. Check worker is started: Look for `✅ Pickup assignment worker started`
2. Check Redis connection: Look for `Redis connected` and `Redis ready`
3. Check job status in Redis Cloud dashboard
4. Review worker logs for errors

### Jobs Running Too Early/Late

**Cause**: Clock skew between application server and Redis Cloud

**Solution**: Ensure server time is synchronized (use NTP)

### Memory Issues

**Symptoms**: Redis Cloud shows high memory usage

**Solutions**:
1. Check `removeOnComplete` and `removeOnFail` settings in queue config
2. Clean up old completed/failed jobs manually
3. Upgrade Redis Cloud plan if needed

### Jobs Lost After Redis Restart

**Symptoms**: Orders with `pickup_time_from` in the past but no assignment

**Cause**: Free Redis Cloud tier doesn't persist data

**Solutions**:
1. **Catch-up job** (already enabled) will re-queue missed orders within 15 minutes
2. Upgrade to Redis Cloud paid plan with persistence
3. Use Redis on EC2 with persistence enabled
4. Manually trigger catch-up: The catch-up job runs automatically, but you can also call the function directly if needed

## Alternatives: Redis with Persistence

If you need persistence (recommended for production):

### Option 1: Upgrade Redis Cloud

Upgrade to a paid Redis Cloud plan that supports:
- **AOF (Append-Only File)**: Logs every write operation
- **RDB snapshots**: Periodic backups
- **Replication**: High availability

### Option 2: Redis on EC2 with Persistence ⭐ **RECOMMENDED**

Run Redis on your EC2 instance with persistence enabled - **NO additional cost**!

**Quick Setup:**

```bash
# Install Redis
sudo amazon-linux-extras install redis6

# Configure persistence in /etc/redis.conf
appendonly yes
appendfsync everysec

# Set password (recommended)
requirepass your-strong-password-here

# Start Redis
sudo systemctl start redis
sudo systemctl enable redis
```

Then use `REDIS_URL=redis://:password@localhost:6379`

**Full Setup Guide**: See [REDIS_EC2_SETUP.md](./REDIS_EC2_SETUP.md) for detailed instructions.

**Pros**: 
- ✅ Full persistence (AOF/RDB) - no data loss
- ✅ No additional cost (uses existing EC2)
- ✅ Full control over configuration
- ✅ No external dependency

**Cons**: 
- You manage Redis (updates, backups, monitoring)
- Uses EC2 resources (RAM, disk)

**Best For**: Production environments where reliability is critical

### Option 3: AWS ElastiCache for Redis

Use AWS ElastiCache (managed Redis with persistence):
- Automatic backups
- Multi-AZ support
- Managed by AWS
- Higher cost than self-hosted

## Comparison: Queue vs Polling vs Webhook

| Feature | Queue-Based | Polling | Webhook |
|---------|-------------|---------|---------|
| **Latency** | Exact (runs at pickup_time_from) | Up to interval delay (e.g., 10 min) | Up to cron interval (e.g., 5 min) |
| **Database Load** | Low (only when job runs) | High (periodic scans) | Medium (periodic scans) |
| **Scalability** | Excellent (distributed workers) | Limited (single process) | Good (DB-level) |
| **Infrastructure** | Requires Redis | None | Requires pg_cron + DB triggers |
| **Reliability** | High (persistent jobs, retries) | Medium (lost on restart) | High (DB-level) |
| **Setup Complexity** | Medium | Low | High |

## Migration from Polling

To migrate from polling to queue-based:

1. Set up Redis Cloud (steps above)
2. Add `PICKUP_ASSIGNMENT_USE_QUEUE=true` to `.env`
3. Restart application
4. Monitor logs to ensure worker starts
5. Test with a test order (set `pickup_time_from` 1-2 minutes in future)
6. Verify job runs at scheduled time

**Note**: Existing polling job is automatically disabled when `PICKUP_ASSIGNMENT_USE_QUEUE=true`

## Catch-Up Job (Safety Net)

A **catch-up job** is automatically enabled when queue mode is active. It runs every 15 minutes (configurable) and:

1. Finds orders that are eligible for pickup assignment but don't have pending requests
2. Re-queues them automatically (handles idempotency - won't create duplicates)
3. Acts as a safety net for:
   - Redis data loss (free tier without persistence)
   - Worker downtime
   - Missed jobs due to clock skew or other issues

### Configuration

```env
# Enable/disable catch-up job (default: enabled when queue mode is active)
PICKUP_ASSIGNMENT_CATCHUP_ENABLED=true

# Interval between catch-up runs (default: 15 minutes = 900000 ms)
PICKUP_ASSIGNMENT_CATCHUP_INTERVAL_MS=900000
```

The catch-up job is implemented in `backend/src/jobs/pickup-assignment-catchup.job.js` and starts automatically with the queue worker.

## Configuration Options

All configuration is in `backend/src/queues/pickup-assignment.queue.js`:

- **Job attempts**: 3 retries with exponential backoff
- **Concurrency**: 1 job at a time (adjustable in worker)
- **Job retention**: Completed jobs kept 24h, failed jobs kept 7 days
- **Rate limiting**: Max 10 jobs per second

## Support

For issues:
1. Check logs: `backend/logs/combined.log`
2. Check Redis Cloud dashboard
3. Verify environment variables
4. Test Redis connection manually
