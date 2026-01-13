/*
  Warnings:

  - The values [pending,in_progress] on the enum `OrderItemStatus` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `assigned_at` on the `order_items` table. All the data in the column will be lost.
  - You are about to drop the column `clothes_id` on the `order_items` table. All the data in the column will be lost.
  - You are about to drop the column `completed_at` on the `order_items` table. All the data in the column will be lost.
  - You are about to drop the column `item_status` on the `order_items` table. All the data in the column will be lost.
  - You are about to drop the column `unit_price` on the `order_items` table. All the data in the column will be lost.
  - You are about to drop the column `customer_rating` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `customer_review` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `delivery_date` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `dispatched_at` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `dispatched_by_distribution_manager_id` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `payment_confirmed_at` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `pickup_date` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `received_at` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `received_by_collection_manager_id` on the `orders` table. All the data in the column will be lost.
  - Added the required column `subtotal` to the `order_item_selections` table without a default value. This is not possible if the table is not empty.
  - Added the required column `unit_price` to the `order_item_selections` table without a default value. This is not possible if the table is not empty.

*/
-- AlterEnum
BEGIN;
-- Use a transitional enum that includes old + new values so we can migrate data safely.
CREATE TYPE "OrderItemStatus_new" AS ENUM ('pending', 'in_progress', 'assigned', 'on_process', 'completed');
ALTER TABLE "order_items" ALTER COLUMN "item_status" DROP DEFAULT;
ALTER TABLE "order_items" ALTER COLUMN "item_status" TYPE "OrderItemStatus_new" USING ("item_status"::text::"OrderItemStatus_new");
ALTER TYPE "OrderItemStatus" RENAME TO "OrderItemStatus_old";
ALTER TYPE "OrderItemStatus_new" RENAME TO "OrderItemStatus";
DROP TYPE "OrderItemStatus_old";
COMMIT;

-- Normalize existing rows to the new semantics before narrowing the enum.
UPDATE "order_items" SET "item_status" = 'on_process' WHERE "item_status" = 'in_progress';
UPDATE "order_items" SET "item_status" = 'assigned' WHERE "item_status" = 'pending';

-- Narrow enum to final values after data has been migrated.
BEGIN;
CREATE TYPE "OrderItemStatus_new" AS ENUM ('assigned', 'on_process', 'completed');
ALTER TABLE "order_items" ALTER COLUMN "item_status" TYPE "OrderItemStatus_new" USING ("item_status"::text::"OrderItemStatus_new");
ALTER TYPE "OrderItemStatus" RENAME TO "OrderItemStatus_old";
ALTER TYPE "OrderItemStatus_new" RENAME TO "OrderItemStatus";
DROP TYPE "OrderItemStatus_old";
COMMIT;

-- Rename the column to match the Prisma schema.
ALTER TABLE "order_items" RENAME COLUMN "item_status" TO "order_item_status";
ALTER TABLE "order_items" ALTER COLUMN "order_item_status" SET DEFAULT 'assigned';

-- DropForeignKey
ALTER TABLE "order_items" DROP CONSTRAINT "order_items_clothes_id_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_dispatched_by_distribution_manager_id_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_received_by_collection_manager_id_fkey";

-- DropIndex
DROP INDEX "order_items_item_status_idx";

-- DropIndex
DROP INDEX "orders_dispatched_by_distribution_manager_id_idx";

-- DropIndex
DROP INDEX "orders_received_by_collection_manager_id_idx";

-- AlterTable
ALTER TABLE "order_item_selections" ADD COLUMN     "subtotal" DECIMAL(10,2) NOT NULL,
ADD COLUMN     "unit_price" DECIMAL(10,2) NOT NULL;

-- AlterTable
ALTER TABLE "order_items" DROP COLUMN "assigned_at",
DROP COLUMN "clothes_id",
DROP COLUMN "completed_at",
DROP COLUMN "unit_price";

-- AlterTable
ALTER TABLE "orders" DROP COLUMN "customer_rating",
DROP COLUMN "customer_review",
DROP COLUMN "delivery_date",
DROP COLUMN "dispatched_at",
DROP COLUMN "dispatched_by_distribution_manager_id",
DROP COLUMN "payment_confirmed_at",
DROP COLUMN "pickup_date",
DROP COLUMN "received_at",
DROP COLUMN "received_by_collection_manager_id";

-- CreateTable
CREATE TABLE "customer_reviews" (
    "review_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "rating" DECIMAL(3,2) NOT NULL,
    "review" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customer_reviews_pkey" PRIMARY KEY ("review_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "customer_reviews_order_id_key" ON "customer_reviews"("order_id");

-- CreateIndex
CREATE INDEX "customer_reviews_customer_id_idx" ON "customer_reviews"("customer_id");

-- CreateIndex
CREATE INDEX "order_items_order_item_status_idx" ON "order_items"("order_item_status");

-- AddForeignKey
ALTER TABLE "customer_reviews" ADD CONSTRAINT "customer_reviews_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_reviews" ADD CONSTRAINT "customer_reviews_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id") ON DELETE CASCADE ON UPDATE CASCADE;
