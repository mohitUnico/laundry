-- Option C v2: one master assignment request + many recipients
-- - Make delivery_assignment_requests.staff_id nullable
-- - Add delivery_assignment_recipients table

-- 1) Make staff_id nullable on delivery_assignment_requests
ALTER TABLE "delivery_assignment_requests" ALTER COLUMN "staff_id" DROP NOT NULL;

-- Update FK to allow NULL staff_id
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'delivery_assignment_requests_staff_id_fkey'
    ) THEN
        ALTER TABLE "delivery_assignment_requests" DROP CONSTRAINT "delivery_assignment_requests_staff_id_fkey";
    END IF;
END $$;

ALTER TABLE "delivery_assignment_requests"
    ADD CONSTRAINT "delivery_assignment_requests_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 2) Create enum for recipients if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DeliveryAssignmentRecipientStatus') THEN
        CREATE TYPE "DeliveryAssignmentRecipientStatus" AS ENUM ('pending', 'accepted', 'rejected', 'expired', 'cancelled');
    END IF;
END $$;

-- 3) Create recipients table
CREATE TABLE IF NOT EXISTS "delivery_assignment_recipients" (
    "recipient_id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "request_id" TEXT NOT NULL,
    "staff_id" TEXT NOT NULL,
    "status" "DeliveryAssignmentRecipientStatus" NOT NULL DEFAULT 'pending',
    "responded_at" TIMESTAMPTZ,
    "rejection_note" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "delivery_assignment_recipients_request_id_fkey"
        FOREIGN KEY ("request_id") REFERENCES "delivery_assignment_requests"("request_id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "delivery_assignment_recipients_staff_id_fkey"
        FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Uniqueness per request+staff
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'delivery_assignment_recipients_request_id_staff_id_key'
    ) THEN
        ALTER TABLE "delivery_assignment_recipients"
            ADD CONSTRAINT "delivery_assignment_recipients_request_id_staff_id_key"
            UNIQUE ("request_id", "staff_id");
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS "delivery_assignment_recipients_staff_id_status_idx"
    ON "delivery_assignment_recipients" ("staff_id", "status");
CREATE INDEX IF NOT EXISTS "delivery_assignment_recipients_request_id_status_idx"
    ON "delivery_assignment_recipients" ("request_id", "status");

-- 4) Backfill recipients for existing per-staff requests (best-effort)
INSERT INTO "delivery_assignment_recipients" ("recipient_id", "request_id", "staff_id", "status", "responded_at", "rejection_note", "created_at", "updated_at")
SELECT
    gen_random_uuid()::text,
    dar.request_id,
    dar.staff_id,
    CASE dar.status
        WHEN 'pending' THEN 'pending'::"DeliveryAssignmentRecipientStatus"
        WHEN 'accepted' THEN 'accepted'::"DeliveryAssignmentRecipientStatus"
        WHEN 'rejected' THEN 'rejected'::"DeliveryAssignmentRecipientStatus"
        WHEN 'expired' THEN 'expired'::"DeliveryAssignmentRecipientStatus"
        WHEN 'cancelled' THEN 'cancelled'::"DeliveryAssignmentRecipientStatus"
        ELSE 'pending'::"DeliveryAssignmentRecipientStatus"
    END,
    dar.responded_at,
    dar.rejection_note,
    dar.created_at,
    dar.updated_at
FROM "delivery_assignment_requests" dar
WHERE dar.staff_id IS NOT NULL
ON CONFLICT ("request_id", "staff_id") DO NOTHING;

