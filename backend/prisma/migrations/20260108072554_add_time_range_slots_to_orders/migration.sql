-- CreateEnum
CREATE TYPE "BillingStatus" AS ENUM ('pending', 'generated');

-- AlterEnum
ALTER TYPE "OrderStatus" ADD VALUE 'draft';

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "billing_status" "BillingStatus" NOT NULL DEFAULT 'pending',
ADD COLUMN     "preferred_delivery_slot_from" TIMESTAMP(3),
ADD COLUMN     "preferred_delivery_slot_to" TIMESTAMP(3),
ADD COLUMN     "preferred_pickup_slot_from" TIMESTAMP(3),
ADD COLUMN     "preferred_pickup_slot_to" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "orders_billing_status_idx" ON "orders"("billing_status");
