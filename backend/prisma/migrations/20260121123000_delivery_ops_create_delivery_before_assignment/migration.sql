-- Delivery Ops v2: create Delivery before assignment request
-- - Make delivery.staff_id nullable so a delivery can exist before staff accepts.
-- - Add delivery_id FK to delivery_assignment_requests.

-- 1) Make delivery.staff_id nullable
ALTER TABLE "delivery" ALTER COLUMN "staff_id" DROP NOT NULL;

-- Drop and recreate FK to allow NULL staff_id
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'delivery_staff_id_fkey'
    ) THEN
        ALTER TABLE "delivery" DROP CONSTRAINT "delivery_staff_id_fkey";
    END IF;
END $$;

ALTER TABLE "delivery"
    ADD CONSTRAINT "delivery_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 2) Add delivery_id to delivery_assignment_requests
ALTER TABLE "delivery_assignment_requests"
    ADD COLUMN IF NOT EXISTS "delivery_id" TEXT;

-- Backfill delivery_id for any existing rows (match latest delivery by order_id + type)
UPDATE "delivery_assignment_requests" dar
SET "delivery_id" = d.delivery_id
FROM (
    SELECT DISTINCT ON (order_id, delivery_type)
        order_id,
        delivery_type,
        delivery_id
    FROM "delivery"
    ORDER BY order_id, delivery_type, assigned_at DESC
) d
WHERE dar.delivery_id IS NULL
  AND d.order_id = dar.order_id
  AND d.delivery_type = dar.delivery_type;

-- For any remaining NULLs (e.g., legacy rows without a matching delivery),
-- generate a delivery_id and create a minimal delivery row for it.
UPDATE "delivery_assignment_requests"
SET "delivery_id" = gen_random_uuid()::text
WHERE "delivery_id" IS NULL;

INSERT INTO "delivery" (
    "delivery_id",
    "order_id",
    "staff_id",
    "delivery_type",
    "delivery_status",
    "delivery_fee"
)
SELECT
    dar.delivery_id,
    dar.order_id,
    NULL,
    dar.delivery_type,
    'unassigned',
    0
FROM "delivery_assignment_requests" dar
WHERE NOT EXISTS (
    SELECT 1 FROM "delivery" d WHERE d.delivery_id = dar.delivery_id
);

-- Make delivery_id required after backfill
ALTER TABLE "delivery_assignment_requests" ALTER COLUMN "delivery_id" SET NOT NULL;

-- FK + index
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'delivery_assignment_requests_delivery_id_fkey'
    ) THEN
        ALTER TABLE "delivery_assignment_requests" DROP CONSTRAINT "delivery_assignment_requests_delivery_id_fkey";
    END IF;
END $$;

ALTER TABLE "delivery_assignment_requests"
    ADD CONSTRAINT "delivery_assignment_requests_delivery_id_fkey"
    FOREIGN KEY ("delivery_id") REFERENCES "delivery"("delivery_id")
    ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_delivery_id_idx"
    ON "delivery_assignment_requests" ("delivery_id");

