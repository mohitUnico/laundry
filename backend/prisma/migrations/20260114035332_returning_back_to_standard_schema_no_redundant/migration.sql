-- CreateEnum
CREATE TYPE "BillingStatus" AS ENUM ('pending', 'generated');

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "billing_status" "BillingStatus" NOT NULL DEFAULT 'pending';

-- CreateIndex
CREATE INDEX "orders_billing_status_idx" ON "orders"("billing_status");
