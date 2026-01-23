-- Enable pgcrypto for gen_random_uuid() used in triggers
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Helper: ensure a daily_metrics row exists for a date
CREATE OR REPLACE FUNCTION upsert_daily_metrics_row(p_metric_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO "daily_metrics" ("metric_id", "metric_date", "updated_at")
    VALUES (gen_random_uuid()::text, p_metric_date, CURRENT_TIMESTAMP)
    ON CONFLICT ("metric_date") DO UPDATE
    SET "updated_at" = EXCLUDED."updated_at";
END;
$$ LANGUAGE plpgsql;

-- Orders trigger: increment counters on create / status transitions
CREATE OR REPLACE FUNCTION trg_orders_daily_metrics()
RETURNS TRIGGER AS $$
DECLARE
    metric_day DATE;
    revenue_amount NUMERIC(10, 2);
BEGIN
    IF TG_OP = 'INSERT' THEN
        metric_day := (NEW."created_at" AT TIME ZONE 'UTC')::date;
        PERFORM upsert_daily_metrics_row(metric_day);

        UPDATE "daily_metrics"
        SET
            "total_orders" = "total_orders" + 1,
            "updated_at" = CURRENT_TIMESTAMP
        WHERE "metric_date" = metric_day;

        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        -- Only act on status transitions
        IF NEW."order_status" IS DISTINCT FROM OLD."order_status" THEN
            metric_day := (NEW."updated_at" AT TIME ZONE 'UTC')::date;
            PERFORM upsert_daily_metrics_row(metric_day);

            -- Completed (delivered): increment completed_orders and revenue
            -- Note: 'closed' is excluded here to avoid double-counting if an order moves delivered -> closed later.
            IF (NEW."order_status" = 'delivered'::"OrderStatus")
               AND (OLD."order_status" IS DISTINCT FROM 'delivered'::"OrderStatus") THEN
                revenue_amount := NULL;
                SELECT b."final_amount" INTO revenue_amount
                FROM "bills" b
                WHERE b."order_id" = NEW."order_id"
                LIMIT 1;

                IF revenue_amount IS NULL THEN
                    revenue_amount := COALESCE(NEW."total_amount", 0);
                END IF;

                UPDATE "daily_metrics"
                SET
                    "completed_orders" = "completed_orders" + 1,
                    "total_revenue" = "total_revenue" + revenue_amount,
                    "updated_at" = CURRENT_TIMESTAMP
                WHERE "metric_date" = metric_day;
            END IF;

            -- Cancelled: increment cancelled_orders
            IF (NEW."order_status" = 'cancelled'::"OrderStatus")
               AND (OLD."order_status" IS DISTINCT FROM 'cancelled'::"OrderStatus") THEN
                UPDATE "daily_metrics"
                SET
                    "cancelled_orders" = "cancelled_orders" + 1,
                    "updated_at" = CURRENT_TIMESTAMP
                WHERE "metric_date" = metric_day;
            END IF;
        END IF;

        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS orders_daily_metrics_trigger ON "orders";
CREATE TRIGGER orders_daily_metrics_trigger
AFTER INSERT OR UPDATE OF "order_status" ON "orders"
FOR EACH ROW
EXECUTE FUNCTION trg_orders_daily_metrics();

-- Customers trigger: increment new_customers on create
CREATE OR REPLACE FUNCTION trg_customers_daily_metrics()
RETURNS TRIGGER AS $$
DECLARE
    metric_day DATE;
BEGIN
    metric_day := (NEW."created_at" AT TIME ZONE 'UTC')::date;
    PERFORM upsert_daily_metrics_row(metric_day);

    UPDATE "daily_metrics"
    SET
        "new_customers" = "new_customers" + 1,
        "updated_at" = CURRENT_TIMESTAMP
    WHERE "metric_date" = metric_day;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS customers_daily_metrics_trigger ON "customers";
CREATE TRIGGER customers_daily_metrics_trigger
AFTER INSERT ON "customers"
FOR EACH ROW
EXECUTE FUNCTION trg_customers_daily_metrics();

