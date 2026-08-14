DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS pg_net;
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            CREATE EXTENSION IF NOT EXISTS http;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Neither pg_net nor http extension is available.';
        END;
    END;
END $$;

CREATE OR REPLACE FUNCTION process_pickup_assignments_via_webhook()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    webhook_url TEXT := 'http://13.232.71.139:4000/api/v1/webhooks/pickup-assignment/process';
    webhook_secret TEXT := '';
    response_status INT;
    response_body TEXT;
BEGIN
    BEGIN
        SELECT status, content INTO response_status, response_body
        FROM net.http_post(
            url := webhook_url,
            body := jsonb_build_object('timestamp', now(), 'source', 'database_trigger')::text,
            headers := jsonb_build_object('Content-Type', 'application/json', 'X-Webhook-Secret', COALESCE(webhook_secret, ''))
        );
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            SELECT status, content INTO response_status, response_body
            FROM http_post(
                webhook_url,
                jsonb_build_object('timestamp', now(), 'source', 'database_trigger')::text,
                'application/json'::text,
                jsonb_build_object('Content-Type', 'application/json', 'X-Webhook-Secret', COALESCE(webhook_secret, ''))::jsonb
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Failed to call webhook: %', SQLERRM;
        END;
    END;
    
    IF response_status != 200 THEN
        RAISE WARNING 'Webhook call failed with status %: %', response_status, response_body;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION process_order_pickup_assignment(p_order_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    webhook_url TEXT := 'http://13.232.71.139:4000/api/v1/webhooks/pickup-assignment/process';
    webhook_secret TEXT := '';
    response_status INT;
    response_body TEXT;
BEGIN
    BEGIN
        SELECT status, content INTO response_status, response_body
        FROM net.http_post(
            url := webhook_url || '/' || p_order_id,
            body := jsonb_build_object('timestamp', now(), 'source', 'database_trigger', 'orderId', p_order_id)::text,
            headers := jsonb_build_object('Content-Type', 'application/json', 'X-Webhook-Secret', COALESCE(webhook_secret, ''))
        );
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            SELECT status, content INTO response_status, response_body
            FROM http_post(
                webhook_url || '/' || p_order_id,
                jsonb_build_object('timestamp', now(), 'source', 'database_trigger', 'orderId', p_order_id)::text,
                'application/json'::text,
                jsonb_build_object('Content-Type', 'application/json', 'X-Webhook-Secret', COALESCE(webhook_secret, ''))::jsonb
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Failed to call webhook for order %: %', p_order_id, SQLERRM;
        END;
    END;
    
    IF response_status != 200 THEN
        RAISE WARNING 'Webhook call for order % failed with status %: %', p_order_id, response_status, response_body;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_orders_pickup_time_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    now_time TIMESTAMPTZ;
BEGIN
    IF NEW."pickup_time_from" IS NOT NULL 
       AND NEW."order_status" = 'placed'::"OrderStatus"
       AND (OLD."pickup_time_from" IS NULL OR OLD."pickup_time_from" IS DISTINCT FROM NEW."pickup_time_from") THEN
        now_time := NOW();
        IF NEW."pickup_time_from" <= (now_time + INTERVAL '30 seconds') THEN
            PERFORM process_order_pickup_assignment(NEW."order_id");
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_pickup_time_assignment ON "orders";

CREATE TRIGGER trg_orders_pickup_time_assignment
    AFTER INSERT OR UPDATE OF "pickup_time_from", "order_status"
    ON "orders"
    FOR EACH ROW
    EXECUTE FUNCTION trg_orders_pickup_time_assignment();
