-- Rename pickup_for_delivery table to pickup and restructure to match Delivery table

-- Step 1: Drop the foreign key constraint to delivery table
ALTER TABLE "pickup_for_delivery" DROP CONSTRAINT IF EXISTS "pickup_for_delivery_delivery_id_fkey";

-- Step 2: Drop old columns that are no longer needed
ALTER TABLE "pickup_for_delivery" DROP COLUMN IF EXISTS "pickup_address";
ALTER TABLE "pickup_for_delivery" DROP COLUMN IF EXISTS "pickup_lat";
ALTER TABLE "pickup_for_delivery" DROP COLUMN IF EXISTS "pickup_lng";
ALTER TABLE "pickup_for_delivery" DROP COLUMN IF EXISTS "pickup_time";

-- Step 3: Rename delivery_id to order_id (we'll populate it from delivery.order_id)
-- First, add the new order_id column
ALTER TABLE "pickup_for_delivery" ADD COLUMN "order_id" TEXT;

-- Populate order_id from delivery table before dropping delivery_id
UPDATE "pickup_for_delivery" pfd
SET "order_id" = d."order_id"
FROM "delivery" d
WHERE pfd."delivery_id" = d."delivery_id";

-- Make order_id NOT NULL and unique
ALTER TABLE "pickup_for_delivery" ALTER COLUMN "order_id" SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "pickup_for_delivery_order_id_key" ON "pickup_for_delivery"("order_id");

-- Drop the old delivery_id column
ALTER TABLE "pickup_for_delivery" DROP COLUMN "delivery_id";

-- Step 4: Add new columns to match Delivery table structure
ALTER TABLE "pickup_for_delivery" ADD COLUMN "staff_id" TEXT;
ALTER TABLE "pickup_for_delivery" ADD COLUMN "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "pickup_for_delivery" ADD COLUMN "completed_at" TIMESTAMP(3);
ALTER TABLE "pickup_for_delivery" ADD COLUMN "pickup_rating" DECIMAL(3,2);
ALTER TABLE "pickup_for_delivery" ADD COLUMN "pickup_review" TEXT;
ALTER TABLE "pickup_for_delivery" ADD COLUMN "pickup_fee" DECIMAL(10,2) NOT NULL DEFAULT 0;
ALTER TABLE "pickup_for_delivery" ADD COLUMN "distance_km" DECIMAL(10,2);
ALTER TABLE "pickup_for_delivery" ADD COLUMN "estimated_duration" INTEGER;
ALTER TABLE "pickup_for_delivery" ADD COLUMN "actual_duration" INTEGER;
ALTER TABLE "pickup_for_delivery" ADD COLUMN "needs_weight_machine" BOOLEAN NOT NULL DEFAULT false;

-- Step 5: Populate staff_id from delivery table (if delivery exists)
-- Update staff_id from delivery records where delivery_type is 'pickup'
UPDATE "pickup_for_delivery" pfd
SET "staff_id" = d."staff_id"
FROM "delivery" d
WHERE d."order_id" = pfd."order_id" AND d."delivery_type" = 'pickup';

-- Step 6: Add foreign key constraints
ALTER TABLE "pickup_for_delivery" ADD CONSTRAINT "pickup_for_delivery_order_id_fkey" 
    FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Add foreign key for staff_id (allows NULL initially for migration safety)
ALTER TABLE "pickup_for_delivery" ADD CONSTRAINT "pickup_for_delivery_staff_id_fkey" 
    FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Step 7: Rename table
ALTER TABLE "pickup_for_delivery" RENAME TO "pickup";

-- Step 8: Update indexes
-- Drop old index on pickup_status (will recreate with new name)
DROP INDEX IF EXISTS "pickup_for_delivery_pickup_status_idx";

-- Create new indexes
CREATE INDEX "pickup_staff_id_idx" ON "pickup"("staff_id");
CREATE INDEX "pickup_pickup_status_idx" ON "pickup"("pickup_status");

-- Step 9: Rename constraint names to match new table name
ALTER TABLE "pickup" RENAME CONSTRAINT "pickup_for_delivery_pkey" TO "pickup_pkey";
ALTER TABLE "pickup" RENAME CONSTRAINT "pickup_for_delivery_order_id_key" TO "pickup_order_id_key";
ALTER TABLE "pickup" RENAME CONSTRAINT "pickup_for_delivery_order_id_fkey" TO "pickup_order_id_fkey";
ALTER TABLE "pickup" RENAME CONSTRAINT "pickup_for_delivery_staff_id_fkey" TO "pickup_staff_id_fkey";

-- Step 10: Set staff_id to NOT NULL if all records have staff_id
-- Uncomment the following line only after ensuring all pickup records have staff_id assigned
-- If you have existing records without staff_id, you need to assign them first or delete those records
-- ALTER TABLE "pickup" ALTER COLUMN "staff_id" SET NOT NULL;

