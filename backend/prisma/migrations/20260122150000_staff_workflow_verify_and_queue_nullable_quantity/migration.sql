-- Corrected:
-- staff.staff_id is TEXT in this DB, so verification uses TEXT (not UUID).
-- Add distribution manager verification fields
ALTER TABLE "orders"
    ADD COLUMN IF NOT EXISTS "verified_by_distribution_manager_id" TEXT,
    ADD COLUMN IF NOT EXISTS "verified_at" TIMESTAMP(3);

-- FK + index for verification
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'orders_verified_by_distribution_manager_id_fkey'
    ) THEN
        ALTER TABLE "orders"
            ADD CONSTRAINT "orders_verified_by_distribution_manager_id_fkey"
            FOREIGN KEY ("verified_by_distribution_manager_id") REFERENCES "staff"("staff_id")
            ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS "orders_verified_by_distribution_manager_id_idx"
    ON "orders" ("verified_by_distribution_manager_id");

-- Service queue: allow nullable quantity, add weight_kg, add index for service man FIFO
ALTER TABLE "service_queue"
    ALTER COLUMN "quantity" DROP NOT NULL;

ALTER TABLE "service_queue"
    ADD COLUMN IF NOT EXISTS "weight_kg" NUMERIC(10,2);

CREATE INDEX IF NOT EXISTS "service_queue_service_man_id_queue_status_priority_idx"
    ON "service_queue" ("service_man_id", "queue_status", "priority");

-- Enforce service_queue.item_id -> order_items.item_id (both TEXT in this DB)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'service_queue_item_id_fkey'
    ) THEN
        ALTER TABLE "service_queue"
            ADD CONSTRAINT "service_queue_item_id_fkey"
            FOREIGN KEY ("item_id") REFERENCES "order_items"("item_id")
            ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

