-- Delivery Ops: shifts, live locations, assignment requests, notifications
-- Also updates delivery table to allow multiple deliveries per order (pickup & drop can be separate).

-- 1) delivery: remove unique constraint on order_id (Prisma schema moved to non-unique)
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

-- Ensure order_id is indexed (Prisma adds @@index([order_id]))
CREATE INDEX IF NOT EXISTS "delivery_order_id_idx" ON "delivery" ("order_id");

-- 2) delivery_staff_shifts
CREATE TABLE IF NOT EXISTS "delivery_staff_shifts" (
    "shift_id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "staff_id" TEXT NOT NULL,
    "started_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "ended_at" TIMESTAMPTZ,
    "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
    "last_latitude" DECIMAL(10,8),
    "last_longitude" DECIMAL(11,8),
    "last_location_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "delivery_staff_shifts_staff_id_fkey"
        FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "delivery_staff_shifts_staff_id_idx" ON "delivery_staff_shifts" ("staff_id");
CREATE INDEX IF NOT EXISTS "delivery_staff_shifts_is_active_idx" ON "delivery_staff_shifts" ("is_active");

-- 3) delivery_staff_locations
CREATE TABLE IF NOT EXISTS "delivery_staff_locations" (
    "location_id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "staff_id" TEXT NOT NULL,
    "shift_id" TEXT,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "recorded_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "delivery_staff_locations_staff_id_fkey"
        FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "delivery_staff_locations_shift_id_fkey"
        FOREIGN KEY ("shift_id") REFERENCES "delivery_staff_shifts"("shift_id")
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "delivery_staff_locations_staff_id_recorded_at_idx"
    ON "delivery_staff_locations" ("staff_id", "recorded_at");
CREATE INDEX IF NOT EXISTS "delivery_staff_locations_shift_id_idx" ON "delivery_staff_locations" ("shift_id");

-- 4) delivery_assignment_requests
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DeliveryAssignmentStatus') THEN
        CREATE TYPE "DeliveryAssignmentStatus" AS ENUM ('pending', 'accepted', 'rejected', 'expired', 'cancelled');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS "delivery_assignment_requests" (
    "request_id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "order_id" TEXT NOT NULL,
    "staff_id" TEXT NOT NULL,
    "delivery_type" "DeliveryType" NOT NULL,
    "status" "DeliveryAssignmentStatus" NOT NULL DEFAULT 'pending',
    "offered_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "responded_at" TIMESTAMPTZ,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "pickup_address" TEXT NOT NULL,
    "pickup_lat" DECIMAL(10,8) NOT NULL,
    "pickup_lng" DECIMAL(11,8) NOT NULL,
    "drop_address" TEXT NOT NULL,
    "drop_lat" DECIMAL(10,8) NOT NULL,
    "drop_lng" DECIMAL(11,8) NOT NULL,
    "rejection_note" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "delivery_assignment_requests_order_id_fkey"
        FOREIGN KEY ("order_id") REFERENCES "orders"("order_id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "delivery_assignment_requests_staff_id_fkey"
        FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_order_id_idx" ON "delivery_assignment_requests" ("order_id");
CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_staff_id_idx" ON "delivery_assignment_requests" ("staff_id");
CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_status_idx" ON "delivery_assignment_requests" ("status");
CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_delivery_type_idx" ON "delivery_assignment_requests" ("delivery_type");
CREATE INDEX IF NOT EXISTS "delivery_assignment_requests_expires_at_idx" ON "delivery_assignment_requests" ("expires_at");

-- 5) delivery_staff_notifications
CREATE TABLE IF NOT EXISTS "delivery_staff_notifications" (
    "notification_id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "staff_id" TEXT NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "body" TEXT,
    "payload" JSONB,
    "is_read" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "delivery_staff_notifications_staff_id_fkey"
        FOREIGN KEY ("staff_id") REFERENCES "delivery_staffs"("staff_id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "delivery_staff_notifications_staff_id_created_at_idx"
    ON "delivery_staff_notifications" ("staff_id", "created_at");
CREATE INDEX IF NOT EXISTS "delivery_staff_notifications_is_read_idx"
    ON "delivery_staff_notifications" ("is_read");

