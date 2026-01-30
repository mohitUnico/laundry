-- Remove payment_pending from OrderStatus enum
-- Step 1: Update any existing orders with payment_pending status to delivered
UPDATE orders
SET order_status = 'delivered'
WHERE order_status = 'payment_pending';

-- Step 2: Drop the trigger that depends on order_status column
DROP TRIGGER IF EXISTS orders_daily_metrics_trigger ON "orders";

-- Step 3: Create new enum without payment_pending
CREATE TYPE "OrderStatus_new" AS ENUM (
    'draft',
    'placed',
    'pickup_assigned',
    'picked_up',
    'submitted_to_cm',
    'received_by_collection',
    'submitted_to_services',
    'services_in_progress',
    'services_completed',
    'dispatch_assigned',
    'out_for_delivery',
    'delivered',
    'closed',
    'cancelled'
);

-- Step 4: Alter the orders table to use the new enum
ALTER TABLE orders
    ALTER COLUMN order_status TYPE "OrderStatus_new"
    USING order_status::text::"OrderStatus_new";

-- Step 5: Drop the old enum and rename the new one
DROP TYPE "OrderStatus";
ALTER TYPE "OrderStatus_new" RENAME TO "OrderStatus";

-- Step 6: Recreate the trigger (function already exists, just need to recreate trigger)
CREATE TRIGGER orders_daily_metrics_trigger
AFTER INSERT OR UPDATE OF "order_status" ON "orders"
FOR EACH ROW
EXECUTE FUNCTION trg_orders_daily_metrics();

