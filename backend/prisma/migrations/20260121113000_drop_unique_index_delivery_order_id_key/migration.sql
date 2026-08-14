-- Allow multiple delivery rows per order (pickup + drop).
-- The init migration created a UNIQUE INDEX on delivery(order_id) named "delivery_order_id_key".
-- That prevents creating both pickup and drop deliveries for the same order.

-- Drop unique INDEX (this is what actually exists in DB from init migration).
DROP INDEX IF EXISTS "delivery_order_id_key";

-- Safety: if a constraint exists with this name in some environments, drop it too.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'delivery_order_id_key'
    ) THEN
        ALTER TABLE "delivery" DROP CONSTRAINT "delivery_order_id_key";
    END IF;
END $$;

