# Pickup Assignment Webhook Setup Guide

This guide explains how to set up the event-driven pickup assignment system using database triggers and webhooks, replacing the polling-based approach.

## Overview

Instead of polling the database every 60 seconds from the application, we now use:
1. **Database Triggers**: Automatically trigger assignment when `pickup_time_from` is set
2. **pg_cron**: Scheduled database function execution (every 5 minutes as fallback)
3. **Webhook Endpoint**: Backend endpoint that processes pickup assignments

This approach is more scalable and reduces application-level polling.

## Prerequisites

1. **Supabase Database** with the following extensions:
   - `pg_net` (for HTTP requests from database)
   - `pg_cron` (optional, for scheduled execution)

2. **Backend API** running and accessible from the database

## Setup Steps

### 1. Run Database Migration

Apply the migration that creates the database functions and triggers:

```bash
cd backend
npx prisma migrate deploy
```

Or manually run the migration SQL file:
```sql
-- Located at: backend/prisma/migrations/20260130162041_pickup_assignment_webhook_trigger/migration.sql
```

### 2. Configure Database Settings

Set the webhook URL and secret in your Supabase database:

```sql
-- Set webhook URL (replace with your actual backend URL)
ALTER DATABASE postgres SET app.pickup_assignment_webhook_url = 'https://your-backend-url.com/api/v1/webhooks/pickup-assignment/process';

-- Set webhook secret (optional, for security)
ALTER DATABASE postgres SET app.pickup_assignment_webhook_secret = 'your-secret-token-here';
```

**Note**: In Supabase, you may need to set these via the Supabase dashboard or use `ALTER ROLE` instead of `ALTER DATABASE`.

### 3. Enable pg_cron (Optional but Recommended)

1. Go to Supabase Dashboard → Database → Extensions
2. Enable the `pg_cron` extension
3. Run the following SQL to schedule the function:

```sql
-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule pickup assignment processing every 5 minutes
SELECT cron.schedule(
    'process-pickup-assignments',           -- Job name
    '*/5 * * * *',                          -- Cron expression: every 5 minutes
    $$SELECT process_pickup_assignments_via_webhook();$$
);
```

### 4. Configure Backend Environment Variables

Add the following to your `.env` file:

```env
# Enable webhook-based pickup assignment (disables polling job)
USE_WEBHOOK_PICKUP_ASSIGNMENT=true

# Webhook secret for security (must match database setting)
PICKUP_ASSIGNMENT_WEBHOOK_SECRET=your-secret-token-here
```

### 5. Restart Backend Server

Restart your backend server to apply the changes:

```bash
# The polling job will be automatically disabled when USE_WEBHOOK_PICKUP_ASSIGNMENT=true
npm start
```

## How It Works

### Automatic Trigger (Primary Method)

When an order is created or updated with `pickup_time_from` set:
1. The database trigger `trg_orders_pickup_time_assignment` fires
2. It checks if `pickup_time_from <= NOW() + 30 seconds`
3. If true, it calls `process_order_pickup_assignment(order_id)`
4. This function makes an HTTP POST to the webhook endpoint
5. The webhook processes the assignment request

### Scheduled Execution (Fallback Method)

If pg_cron is enabled:
1. Every 5 minutes, pg_cron calls `process_pickup_assignments_via_webhook()`
2. This function finds all orders ready for pickup
3. It calls the webhook endpoint to process them in batch

## Testing

### Test the Webhook Endpoint Directly

```bash
curl -X POST http://localhost:3000/api/v1/webhooks/pickup-assignment/process \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret-token-here" \
  -d '{}'
```

### Test for a Specific Order

```bash
curl -X POST http://localhost:3000/api/v1/webhooks/pickup-assignment/process/ORDER_ID \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret-token-here" \
  -d '{}'
```

### Test Database Function

```sql
-- Test the webhook function
SELECT process_pickup_assignments_via_webhook();

-- Test for a specific order
SELECT process_order_pickup_assignment('your-order-id-here');
```

### Verify Trigger is Working

1. Create an order with `pickup_time_from` set to a past time
2. Check the logs to see if the webhook was called
3. Verify that assignment requests were created

## Monitoring

### View Scheduled Jobs (pg_cron)

```sql
SELECT * FROM cron.job WHERE jobname = 'process-pickup-assignments';
```

### View Job Execution History

```sql
SELECT * FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'process-pickup-assignments')
ORDER BY start_time DESC
LIMIT 10;
```

### Check Trigger Status

```sql
SELECT * FROM pg_trigger WHERE tgname = 'trg_orders_pickup_time_assignment';
```

## Troubleshooting

### Webhook Not Being Called

1. **Check database settings**:
   ```sql
   SELECT current_setting('app.pickup_assignment_webhook_url', true);
   SELECT current_setting('app.pickup_assignment_webhook_secret', true);
   ```

2. **Verify pg_net extension is enabled**:
   ```sql
   SELECT * FROM pg_extension WHERE extname = 'pg_net';
   ```

3. **Check backend logs** for webhook requests

4. **Test webhook endpoint directly** (see Testing section)

### Trigger Not Firing

1. **Verify trigger exists**:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'trg_orders_pickup_time_assignment';
   ```

2. **Check order status**: Trigger only fires for orders with `order_status = 'placed'`

3. **Verify pickup_time_from is set**: Trigger only fires when `pickup_time_from` is not null

### pg_cron Not Running

1. **Verify extension is enabled**:
   ```sql
   SELECT * FROM pg_extension WHERE extname = 'pg_cron';
   ```

2. **Check if job is scheduled**:
   ```sql
   SELECT * FROM cron.job WHERE jobname = 'process-pickup-assignments';
   ```

3. **Check job execution logs**:
   ```sql
   SELECT * FROM cron.job_run_details 
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'process-pickup-assignments')
   ORDER BY start_time DESC;
   ```

## Disabling Webhook Mode

To revert to polling-based assignment:

1. Set environment variable:
   ```env
   USE_WEBHOOK_PICKUP_ASSIGNMENT=false
   ```

2. Restart backend server

3. (Optional) Disable pg_cron job:
   ```sql
   SELECT cron.unschedule('process-pickup-assignments');
   ```

## Security Considerations

1. **Webhook Secret**: Always set `PICKUP_ASSIGNMENT_WEBHOOK_SECRET` in production
2. **HTTPS**: Use HTTPS for webhook URLs in production
3. **Rate Limiting**: The webhook endpoint should have appropriate rate limiting
4. **Database Access**: Ensure database functions have proper security settings

## Performance Benefits

- **Reduced Polling**: No more 60-second polling from application
- **Event-Driven**: Immediate processing when pickup time is reached
- **Scalability**: Database-level processing scales better than application polling
- **Efficiency**: Only processes orders that are actually ready

## Migration from Polling

1. Set up webhook system (follow steps above)
2. Monitor for 24-48 hours to ensure it's working correctly
3. Disable polling job by setting `USE_WEBHOOK_PICKUP_ASSIGNMENT=true`
4. Monitor logs and metrics to verify smooth transition

