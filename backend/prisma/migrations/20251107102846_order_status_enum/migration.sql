/*
  Warnings:

  - Changed the type of `order_status` on the `orders` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('pending', 'pickup_assigned', 'picked_up', 'in_progress', 'wash_completed', 'out_for_delivery', 'delivered', 'cancelled');

-- AlterTable
ALTER TABLE "orders" DROP COLUMN "order_status",
ADD COLUMN     "order_status" "OrderStatus" NOT NULL;

-- CreateIndex
CREATE INDEX "orders_order_status_idx" ON "orders"("order_status");
