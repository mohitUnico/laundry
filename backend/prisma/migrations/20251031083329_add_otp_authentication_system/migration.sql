/*
  Warnings:

  - A unique constraint covering the columns `[contact_phone]` on the table `laundry_mart` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[phone]` on the table `users` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "customers" ADD COLUMN     "is_phone_verified" BOOLEAN NOT NULL DEFAULT false,
ALTER COLUMN "password" DROP NOT NULL;

-- AlterTable
ALTER TABLE "delivery_staffs" ADD COLUMN     "is_phone_verified" BOOLEAN NOT NULL DEFAULT false,
ALTER COLUMN "password" DROP NOT NULL;

-- AlterTable
ALTER TABLE "laundry_mart" ADD COLUMN     "is_phone_verified" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "is_phone_verified" BOOLEAN NOT NULL DEFAULT false,
ALTER COLUMN "password" DROP NOT NULL;

-- CreateTable
CREATE TABLE "otp_verifications" (
    "otp_id" TEXT NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "otp_code" VARCHAR(6) NOT NULL,
    "otp_type" VARCHAR(30) NOT NULL,
    "user_type" VARCHAR(30) NOT NULL,
    "user_data" JSONB,
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "max_attempts" INTEGER NOT NULL DEFAULT 5,

    CONSTRAINT "otp_verifications_pkey" PRIMARY KEY ("otp_id")
);

-- CreateIndex
CREATE INDEX "otp_verifications_phone_otp_type_idx" ON "otp_verifications"("phone", "otp_type");

-- CreateIndex
CREATE INDEX "otp_verifications_expires_at_idx" ON "otp_verifications"("expires_at");

-- CreateIndex
CREATE INDEX "otp_verifications_is_verified_idx" ON "otp_verifications"("is_verified");

-- CreateIndex
CREATE INDEX "customers_phone_idx" ON "customers"("phone");

-- CreateIndex
CREATE INDEX "delivery_staffs_phone_idx" ON "delivery_staffs"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "laundry_mart_contact_phone_key" ON "laundry_mart"("contact_phone");

-- CreateIndex
CREATE INDEX "laundry_mart_contact_phone_idx" ON "laundry_mart"("contact_phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE INDEX "users_phone_idx" ON "users"("phone");
