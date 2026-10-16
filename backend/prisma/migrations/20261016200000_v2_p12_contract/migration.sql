-- Drop columns the v2 flow no longer uses. Catalogue tables are untouched.

ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "orders_verified_by_distribution_manager_id_fkey";
ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "orders_dispatched_by_distribution_manager_id_fkey";

DROP INDEX IF EXISTS "orders_billing_status_idx";
DROP INDEX IF EXISTS "orders_verified_by_distribution_manager_id_idx";
DROP INDEX IF EXISTS "orders_dispatched_by_distribution_manager_id_idx";

ALTER TABLE "orders"
  DROP COLUMN IF EXISTS "pricing_model",
  DROP COLUMN IF EXISTS "order_type",
  DROP COLUMN IF EXISTS "pickup_date",
  DROP COLUMN IF EXISTS "delivery_date",
  DROP COLUMN IF EXISTS "billing_status",
  DROP COLUMN IF EXISTS "verified_by_distribution_manager_id",
  DROP COLUMN IF EXISTS "verified_at",
  DROP COLUMN IF EXISTS "dispatched_by_distribution_manager_id",
  DROP COLUMN IF EXISTS "dispatched_at",
  DROP COLUMN IF EXISTS "payment_confirmed_at";

DROP TYPE IF EXISTS "OrderType";
DROP TYPE IF EXISTS "BillingStatus";

ALTER TABLE "delivery" DROP COLUMN IF EXISTS "needs_weight_machine";
ALTER TABLE "pickup_for_delivery" DROP COLUMN IF EXISTS "pickup_proof";

DROP INDEX IF EXISTS "service_queue_service_id_queue_status_priority_idx";
DROP INDEX IF EXISTS "service_queue_service_man_id_queue_status_priority_idx";
ALTER TABLE "service_queue" DROP COLUMN IF EXISTS "priority";

-- Swap OrderStatus so draft, dispatch_assigned, closed, and payment_pending are gone.
DROP TRIGGER IF EXISTS orders_daily_metrics_trigger ON "orders";

CREATE TYPE "OrderStatus_new" AS ENUM (
  'placed',
  'pickup_assigned',
  'picked_up',
  'submitted_to_cm',
  'received_by_collection',
  'submitted_to_services',
  'services_in_progress',
  'services_completed',
  'out_for_delivery',
  'delivered',
  'cancelled'
);

ALTER TABLE "orders" ALTER COLUMN "order_status" TYPE "OrderStatus_new" USING (
  CASE "order_status"::text
    WHEN 'draft' THEN 'cancelled'
    WHEN 'dispatch_assigned' THEN 'out_for_delivery'
    WHEN 'payment_pending' THEN 'out_for_delivery'
    WHEN 'closed' THEN 'delivered'
    ELSE "order_status"::text
  END
)::"OrderStatus_new";

DROP FUNCTION IF EXISTS trg_orders_daily_metrics();
DROP TYPE "OrderStatus";
ALTER TYPE "OrderStatus_new" RENAME TO "OrderStatus";

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
        SET "total_orders" = "total_orders" + 1, "updated_at" = CURRENT_TIMESTAMP
        WHERE "metric_date" = metric_day;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' AND NEW."order_status" IS DISTINCT FROM OLD."order_status" THEN
        metric_day := (NEW."updated_at" AT TIME ZONE 'UTC')::date;
        PERFORM upsert_daily_metrics_row(metric_day);
        IF (NEW."order_status" = 'delivered'::"OrderStatus")
           AND (OLD."order_status" IS DISTINCT FROM 'delivered'::"OrderStatus") THEN
            SELECT b."final_amount" INTO revenue_amount FROM "bills" b WHERE b."order_id" = NEW."order_id" LIMIT 1;
            IF revenue_amount IS NULL THEN
                revenue_amount := COALESCE(NEW."total_amount", 0);
            END IF;
            UPDATE "daily_metrics"
            SET "completed_orders" = "completed_orders" + 1,
                "total_revenue" = "total_revenue" + revenue_amount,
                "updated_at" = CURRENT_TIMESTAMP
            WHERE "metric_date" = metric_day;
        END IF;
        IF (NEW."order_status" = 'cancelled'::"OrderStatus")
           AND (OLD."order_status" IS DISTINCT FROM 'cancelled'::"OrderStatus") THEN
            UPDATE "daily_metrics"
            SET "cancelled_orders" = "cancelled_orders" + 1, "updated_at" = CURRENT_TIMESTAMP
            WHERE "metric_date" = metric_day;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_daily_metrics_trigger
AFTER INSERT OR UPDATE OF "order_status" ON "orders"
FOR EACH ROW
EXECUTE FUNCTION trg_orders_daily_metrics();

CREATE INDEX IF NOT EXISTS "orders_order_status_is_express_created_at_idx"
  ON "orders"("order_status", "is_express", "created_at");
CREATE INDEX IF NOT EXISTS "delivery_order_id_delivery_type_idx"
  ON "delivery"("order_id", "delivery_type");
CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_delivery_id_status_idx"
  ON "delivery_assignment_requests"("delivery_id", "status");
CREATE INDEX IF NOT EXISTS "service_queue_service_man_id_queue_status_idx"
  ON "service_queue"("service_man_id", "queue_status");
