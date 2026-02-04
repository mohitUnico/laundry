-- ============================================================================
-- Pickup Assignment Webhook Trigger Migration
-- ============================================================================
-- This migration sets up an event-driven approach for pickup assignment
-- processing using database functions and pg_cron (if available).
-- 
-- Instead of polling every 60 seconds from the application, we use:
-- 1. A PostgreSQL function that calls the webhook endpoint
-- 2. pg_cron to schedule the function execution (every 5 minutes)
-- 3. A trigger function that can be called when pickup_time_from is set
--
-- This approach is more scalable and reduces application-level polling.
-- ============================================================================

-- Enable required extensions
-- Note: Supabase may use 'http' extension instead of 'pg_net'
-- If pg_net is not available, try: CREATE EXTENSION IF NOT EXISTS http;
-- If neither is available, you may need to use Supabase Edge Functions instead
DO $$
BEGIN
    -- Try to enable pg_net (common in newer Supabase instances)
    BEGIN
        CREATE EXTENSION IF NOT EXISTS pg_net;
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to http extension (older Supabase instances)
        BEGIN
            CREATE EXTENSION IF NOT EXISTS http;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Neither pg_net nor http extension is available. You may need to use Supabase Edge Functions or enable the extension manually.';
        END;
    END;
END $$;

-- ============================================================================
-- Function: Call webhook endpoint for pickup assignment processing
-- ============================================================================
-- This function makes an HTTP POST request to the webhook endpoint
-- to process pickup assignments for orders that have reached their pickup time.
--
-- Note: Replace 'YOUR_BACKEND_URL' with your actual backend URL
-- Example: https://api.yourdomain.com/api/v1/webhooks/pickup-assignment/process
-- ============================================================================
CREATE OR REPLACE FUNCTION process_pickup_assignments_via_webhook()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    webhook_url TEXT;
    webhook_secret TEXT;
    response_status INT;
    response_body TEXT;
BEGIN
    -- Get webhook URL from environment variable or use default
    -- In Supabase, you can set this via: SELECT current_setting('app.webhook_url', true);
    -- For now, we'll use a placeholder that should be replaced
    webhook_url := COALESCE(
        current_setting('app.pickup_assignment_webhook_url', true),
        'http://localhost:3000/api/v1/webhooks/pickup-assignment/process'
    );

    -- Get webhook secret if configured
    webhook_secret := current_setting('app.pickup_assignment_webhook_secret', true);

    -- Make HTTP POST request to webhook endpoint
    -- Try pg_net first, fallback to http extension
    BEGIN
        SELECT status, content INTO response_status, response_body
        FROM net.http_post(
            url := webhook_url,
            body := jsonb_build_object(
                'timestamp', now(),
                'source', 'database_trigger'
            )::text,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'X-Webhook-Secret', COALESCE(webhook_secret, '')
            )
        );
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to http extension
        BEGIN
            SELECT status, content INTO response_status, response_body
            FROM http_post(
                webhook_url,
                jsonb_build_object(
                    'timestamp', now(),
                    'source', 'database_trigger'
                )::text,
                'application/json'::text,
                jsonb_build_object(
                    'Content-Type', 'application/json',
                    'X-Webhook-Secret', COALESCE(webhook_secret, '')
                )::jsonb
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Failed to call webhook: %', SQLERRM;
            response_status := 500;
            response_body := SQLERRM;
        END;
    END;

    -- Log the response (optional - can be removed in production)
    IF response_status != 200 THEN
        RAISE WARNING 'Webhook call failed with status %: %', response_status, response_body;
    END IF;
END;
$$;

-- ============================================================================
-- Function: Process pickup assignment for a specific order
-- ============================================================================
-- This function can be called when pickup_time_from is set on an order
-- to immediately trigger assignment processing.
-- ============================================================================
CREATE OR REPLACE FUNCTION process_order_pickup_assignment(p_order_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    webhook_url TEXT;
    webhook_secret TEXT;
    response_status INT;
    response_body TEXT;
BEGIN
    -- Get webhook URL
    webhook_url := COALESCE(
        current_setting('app.pickup_assignment_webhook_url', true),
        'http://localhost:3000/api/v1/webhooks/pickup-assignment/process'
    );

    -- Get webhook secret if configured
    webhook_secret := current_setting('app.pickup_assignment_webhook_secret', true);

    -- Make HTTP POST request for specific order
    -- Try pg_net first, fallback to http extension
    BEGIN
        SELECT status, content INTO response_status, response_body
        FROM net.http_post(
            url := webhook_url || '/' || p_order_id,
            body := jsonb_build_object(
                'timestamp', now(),
                'source', 'database_trigger',
                'orderId', p_order_id
            )::text,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'X-Webhook-Secret', COALESCE(webhook_secret, '')
            )
        );
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to http extension
        BEGIN
            SELECT status, content INTO response_status, response_body
            FROM http_post(
                webhook_url || '/' || p_order_id,
                jsonb_build_object(
                    'timestamp', now(),
                    'source', 'database_trigger',
                    'orderId', p_order_id
                )::text,
                'application/json'::text,
                jsonb_build_object(
                    'Content-Type', 'application/json',
                    'X-Webhook-Secret', COALESCE(webhook_secret, '')
                )::jsonb
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Failed to call webhook for order %: %', p_order_id, SQLERRM;
            response_status := 500;
            response_body := SQLERRM;
        END;
    END;

    IF response_status != 200 THEN
        RAISE WARNING 'Webhook call for order % failed with status %: %', p_order_id, response_status, response_body;
    END IF;
END;
$$;

-- ============================================================================
-- Trigger Function: Auto-trigger assignment when pickup_time_from is set
-- ============================================================================
-- This trigger fires when pickup_time_from is set or updated on an order.
-- It checks if the pickup time has been reached and triggers assignment.
--
-- Note: This is optional. You can use pg_cron instead for scheduled checks.
-- ============================================================================
CREATE OR REPLACE FUNCTION trg_orders_pickup_time_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    now_time TIMESTAMPTZ;
BEGIN
    -- Only process if pickup_time_from is set and order is in 'placed' status
    IF NEW.pickup_time_from IS NOT NULL 
       AND NEW.order_status = 'placed'::"OrderStatus"
       AND (OLD.pickup_time_from IS NULL OR OLD.pickup_time_from IS DISTINCT FROM NEW.pickup_time_from) THEN
        
        now_time := NOW();
        
        -- If pickup time has been reached, trigger assignment
        -- Use a small buffer (30 seconds) to account for timing
        IF NEW.pickup_time_from <= (now_time + INTERVAL '30 seconds') THEN
            -- Call webhook for this specific order
            PERFORM process_order_pickup_assignment(NEW.order_id);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger on orders table (table name is "orders" per @@map in schema)
DROP TRIGGER IF EXISTS trg_orders_pickup_time_assignment ON "orders";
CREATE TRIGGER trg_orders_pickup_time_assignment
    AFTER INSERT OR UPDATE OF pickup_time_from, order_status
    ON "orders"
    FOR EACH ROW
    EXECUTE FUNCTION trg_orders_pickup_time_assignment();

-- ============================================================================
-- pg_cron Setup (if available)
-- ============================================================================
-- If pg_cron extension is available, schedule the function to run periodically.
-- This provides a fallback mechanism in case the trigger doesn't catch all cases.
--
-- To enable pg_cron in Supabase:
-- 1. Go to Database > Extensions
-- 2. Enable "pg_cron" extension
-- 3. Run the commands below manually (or uncomment if your Supabase instance supports it)
-- ============================================================================

-- Uncomment the following if pg_cron is enabled in your Supabase instance:
-- Note: The cron expression uses '0,5,10,15,20,25,30,35,40,45,50,55 * * * *' instead of '*/5 * * * *'
-- to avoid comment parsing issues. Both expressions mean "every 5 minutes".
/*
-- Enable pg_cron extension (requires superuser privileges)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule pickup assignment processing every 5 minutes
-- This is a fallback to catch any orders that might have been missed by the trigger
SELECT cron.schedule(
    'process-pickup-assignments',           -- Job name
    '0,5,10,15,20,25,30,35,40,45,50,55 * * * *',  -- Cron expression: every 5 minutes
    $$SELECT process_pickup_assignments_via_webhook();$$
);

-- To view scheduled jobs:
-- SELECT * FROM cron.job;

-- To unschedule a job:
-- SELECT cron.unschedule('process-pickup-assignments');
*/

-- ============================================================================
-- Alternative: Using Supabase Edge Functions (if pg_net is not available)
-- ============================================================================
-- If pg_net extension is not available, you can use Supabase Edge Functions
-- or call the webhook endpoint directly from your application.
--
-- For Supabase Edge Functions:
-- 1. Create an Edge Function that calls your backend webhook
-- 2. Use pg_cron to call the Edge Function
-- 3. Or use Supabase's built-in scheduled functions
-- ============================================================================

-- ============================================================================
-- Configuration Instructions
-- ============================================================================
-- 1. Set the webhook URL in your database:
--    ALTER DATABASE postgres SET app.pickup_assignment_webhook_url = 'https://your-backend-url.com/api/v1/webhooks/pickup-assignment/process';
--
-- 2. Set the webhook secret (optional, for security):
--    ALTER DATABASE postgres SET app.pickup_assignment_webhook_secret = 'your-secret-token';
--
-- 3. If using pg_cron, enable the extension and uncomment the cron.schedule() call above
--
-- 4. Test the function:
--    SELECT process_pickup_assignments_via_webhook();
--
-- 5. Test for a specific order:
--    SELECT process_order_pickup_assignment('your-order-id-here');
-- ============================================================================

