/*
  Purpose:
  - Unify CollectionManager, DistributionManager, and ServiceMan into a single `staff` table.
  - Preserve existing data by copying rows before dropping old tables.
  - Rewire foreign keys on `orders` and `service_queue` to reference `staff`.
*/

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "orders_received_by_collection_manager_id_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "orders_dispatched_by_distribution_manager_id_fkey";

-- DropForeignKey
ALTER TABLE "service_queue" DROP CONSTRAINT IF EXISTS "service_queue_service_man_id_fkey";

-- DropForeignKey
ALTER TABLE "service_men" DROP CONSTRAINT IF EXISTS "service_men_service_id_fkey";

-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "StaffRole" AS ENUM ('collection_manager', 'distribution_manager', 'service_man');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- CreateTable
CREATE TABLE "staff" (
  "staff_id" TEXT NOT NULL,
  "role" "StaffRole" NOT NULL,
  "full_name" VARCHAR(255) NOT NULL,
  "email" VARCHAR(255) NOT NULL,
  "phone" VARCHAR(20),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "service_id" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "staff_pkey" PRIMARY KEY ("staff_id")
);

-- Indexes / Uniques
CREATE UNIQUE INDEX "staff_email_key" ON "staff"("email");
CREATE UNIQUE INDEX "staff_service_id_key" ON "staff"("service_id");
CREATE INDEX "staff_role_idx" ON "staff"("role");
CREATE INDEX "staff_service_id_idx" ON "staff"("service_id");

-- Data migration: preserve IDs so existing FK values remain valid
INSERT INTO "staff" ("staff_id","role","full_name","email","phone","is_active","service_id","created_at","updated_at")
SELECT "manager_id",'collection_manager',"full_name","email","phone","is_active",NULL,"created_at","updated_at"
FROM "collection_managers"
ON CONFLICT ("email") DO NOTHING;

INSERT INTO "staff" ("staff_id","role","full_name","email","phone","is_active","service_id","created_at","updated_at")
SELECT "manager_id",'distribution_manager',"full_name","email","phone","is_active",NULL,"created_at","updated_at"
FROM "distribution_managers"
ON CONFLICT ("email") DO NOTHING;

INSERT INTO "staff" ("staff_id","role","full_name","email","phone","is_active","service_id","created_at","updated_at")
SELECT "service_man_id",'service_man',"full_name","email","phone","is_active","service_id","created_at","updated_at"
FROM "service_men"
ON CONFLICT ("email") DO NOTHING;

-- Foreign keys
ALTER TABLE "staff"
  ADD CONSTRAINT "staff_service_id_fkey"
  FOREIGN KEY ("service_id") REFERENCES "services"("service_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "orders"
  ADD CONSTRAINT "orders_received_by_collection_manager_id_fkey"
  FOREIGN KEY ("received_by_collection_manager_id") REFERENCES "staff"("staff_id")
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "orders"
  ADD CONSTRAINT "orders_dispatched_by_distribution_manager_id_fkey"
  FOREIGN KEY ("dispatched_by_distribution_manager_id") REFERENCES "staff"("staff_id")
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "service_queue"
  ADD CONSTRAINT "service_queue_service_man_id_fkey"
  FOREIGN KEY ("service_man_id") REFERENCES "staff"("staff_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Drop old tables
DROP TABLE "collection_managers";
DROP TABLE "distribution_managers";
DROP TABLE "service_men";


