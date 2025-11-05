/*
  Warnings:

  - You are about to drop the column `is_phone_verified` on the `customers` table. All the data in the column will be lost.
  - You are about to drop the column `is_phone_verified` on the `delivery_staffs` table. All the data in the column will be lost.
  - You are about to drop the column `is_phone_verified` on the `laundry_mart` table. All the data in the column will be lost.
  - You are about to drop the column `phone` on the `otp_sessions` table. All the data in the column will be lost.
  - You are about to drop the column `phone` on the `otp_verifications` table. All the data in the column will be lost.
  - You are about to drop the column `is_phone_verified` on the `users` table. All the data in the column will be lost.
  - Made the column `email` on table `delivery_staffs` required. This step will fail if there are existing NULL values in that column.
  - Added the required column `email` to the `otp_sessions` table without a default value. This is not possible if the table is not empty.
  - Added the required column `email` to the `otp_verifications` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "customers_phone_idx";

-- DropIndex
DROP INDEX "customers_phone_key";

-- DropIndex
DROP INDEX "delivery_staffs_phone_idx";

-- DropIndex
DROP INDEX "delivery_staffs_phone_key";

-- DropIndex
DROP INDEX "laundry_mart_contact_phone_idx";

-- DropIndex
DROP INDEX "laundry_mart_contact_phone_key";

-- DropIndex
DROP INDEX "otp_sessions_phone_idx";

-- DropIndex
DROP INDEX "otp_verifications_phone_purpose_idx";

-- DropIndex
DROP INDEX "users_phone_idx";

-- DropIndex
DROP INDEX "users_phone_key";

-- AlterTable
ALTER TABLE "customers" DROP COLUMN "is_phone_verified",
ALTER COLUMN "phone" DROP NOT NULL;

-- AlterTable
ALTER TABLE "delivery_staffs" DROP COLUMN "is_phone_verified",
ALTER COLUMN "phone" DROP NOT NULL,
ALTER COLUMN "email" SET NOT NULL;

-- AlterTable
ALTER TABLE "laundry_mart" DROP COLUMN "is_phone_verified";

-- AlterTable
ALTER TABLE "otp_sessions" DROP COLUMN "phone",
ADD COLUMN     "email" VARCHAR(255) NOT NULL;

-- AlterTable
ALTER TABLE "otp_verifications" DROP COLUMN "phone",
ADD COLUMN     "email" VARCHAR(255) NOT NULL;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "is_phone_verified",
ALTER COLUMN "phone" DROP NOT NULL;

-- CreateIndex
CREATE INDEX "otp_sessions_email_idx" ON "otp_sessions"("email");

-- CreateIndex
CREATE INDEX "otp_verifications_email_purpose_idx" ON "otp_verifications"("email", "purpose");
