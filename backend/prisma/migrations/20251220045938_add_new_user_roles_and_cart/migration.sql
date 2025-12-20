/*
  Warnings:

  - The values [pending,in_progress,wash_completed] on the enum `OrderStatus` will be removed. If these variants are still used in the database, this will fail.
  - The `payment_status` column on the `bills` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `clothes_items` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `item_id` on the `clothes_items` table. All the data in the column will be lost.
  - You are about to drop the column `mart_id` on the `delivery_staffs` table. All the data in the column will be lost.
  - The `verification_status` column on the `delivery_staffs` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the column `mart_id` on the `orders` table. All the data in the column will be lost.
  - You are about to drop the column `mart_email` on the `otp_sessions` table. All the data in the column will be lost.
  - You are about to drop the column `mart_email_verified` on the `otp_sessions` table. All the data in the column will be lost.
  - You are about to drop the column `mart_id` on the `services` table. All the data in the column will be lost.
  - You are about to drop the column `mart_id` on the `users` table. All the data in the column will be lost.
  - The `role` column on the `users` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the `customer_mart_profile` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `laundry_mart` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `mart_daily_metrics` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[service_id,item_name]` on the table `clothes_items` will be added. If there are existing duplicate values, this will fail.
  - The required column `cloth_id` was added to the `clothes_items` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.
  - Added the required column `service_id` to the `clothes_items` table without a default value. This is not possible if the table is not empty.
  - Added the required column `delivery_type` to the `delivery` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `order_items` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `pricing_model` on the `orders` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('admin', 'owner');

-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('pending', 'verified', 'rejected');

-- CreateEnum
CREATE TYPE "PricingModel" AS ENUM ('per_unit', 'per_kg');

-- CreateEnum
CREATE TYPE "OrderType" AS ENUM ('pickup_only', 'drop_only', 'both', 'express_delivery');

-- CreateEnum
CREATE TYPE "OrderItemStatus" AS ENUM ('pending', 'in_progress', 'completed');

-- CreateEnum
CREATE TYPE "QueueStatus" AS ENUM ('pending', 'in_progress', 'completed');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- CreateEnum
CREATE TYPE "DeliveryType" AS ENUM ('pickup', 'drop');

-- AlterEnum
BEGIN;
CREATE TYPE "OrderStatus_new" AS ENUM ('placed', 'pickup_assigned', 'picked_up', 'received_by_collection', 'submitted_to_services', 'services_in_progress', 'services_completed', 'dispatch_assigned', 'out_for_delivery', 'payment_pending', 'delivered', 'closed', 'cancelled');
ALTER TABLE "orders" ALTER COLUMN "order_status" TYPE "OrderStatus_new" USING ("order_status"::text::"OrderStatus_new");
ALTER TYPE "OrderStatus" RENAME TO "OrderStatus_old";
ALTER TYPE "OrderStatus_new" RENAME TO "OrderStatus";
DROP TYPE "OrderStatus_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "customer_mart_profile" DROP CONSTRAINT "customer_mart_profile_customer_id_fkey";

-- DropForeignKey
ALTER TABLE "customer_mart_profile" DROP CONSTRAINT "customer_mart_profile_mart_id_fkey";

-- DropForeignKey
ALTER TABLE "delivery_staffs" DROP CONSTRAINT "delivery_staffs_mart_id_fkey";

-- DropForeignKey
ALTER TABLE "mart_daily_metrics" DROP CONSTRAINT "mart_daily_metrics_mart_id_fkey";

-- DropForeignKey
ALTER TABLE "order_items" DROP CONSTRAINT "order_items_clothes_id_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_mart_id_fkey";

-- DropForeignKey
ALTER TABLE "services" DROP CONSTRAINT "services_mart_id_fkey";

-- DropForeignKey
ALTER TABLE "users" DROP CONSTRAINT "users_mart_id_fkey";

-- DropIndex
DROP INDEX "delivery_staffs_mart_id_idx";

-- DropIndex
DROP INDEX "orders_mart_id_idx";

-- DropIndex
DROP INDEX "services_mart_id_idx";

-- DropIndex
DROP INDEX "users_mart_id_idx";

-- AlterTable
ALTER TABLE "bills" DROP COLUMN "payment_status",
ADD COLUMN     "payment_status" "PaymentStatus" NOT NULL DEFAULT 'pending';

-- AlterTable
ALTER TABLE "clothes_items" DROP CONSTRAINT "clothes_items_pkey",
DROP COLUMN "item_id",
ADD COLUMN     "cloth_id" TEXT NOT NULL,
ADD COLUMN     "service_id" TEXT NOT NULL,
ADD CONSTRAINT "clothes_items_pkey" PRIMARY KEY ("cloth_id");

-- AlterTable
ALTER TABLE "customers" ADD COLUMN     "total_orders" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "total_spent" DECIMAL(10,2) NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "delivery" ADD COLUMN     "delivery_type" "DeliveryType" NOT NULL,
ADD COLUMN     "needs_weight_machine" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "delivery_staffs" DROP COLUMN "mart_id",
ADD COLUMN     "id_proof_type" VARCHAR(50),
ADD COLUMN     "id_proof_url" VARCHAR(500),
ADD COLUMN     "is_verified_by_admin" BOOLEAN NOT NULL DEFAULT false,
DROP COLUMN "verification_status",
ADD COLUMN     "verification_status" "VerificationStatus" NOT NULL DEFAULT 'pending';

-- AlterTable
ALTER TABLE "drop_for_delivery" ALTER COLUMN "drop_proof" DROP NOT NULL;

-- AlterTable
ALTER TABLE "order_items" ADD COLUMN     "assigned_at" TIMESTAMP(3),
ADD COLUMN     "completed_at" TIMESTAMP(3),
ADD COLUMN     "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "item_status" "OrderItemStatus" NOT NULL DEFAULT 'pending',
ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "orders" DROP COLUMN "mart_id",
ADD COLUMN     "dispatched_at" TIMESTAMP(3),
ADD COLUMN     "dispatched_by_distribution_manager_id" TEXT,
ADD COLUMN     "order_type" "OrderType" NOT NULL DEFAULT 'both',
ADD COLUMN     "payment_confirmed_at" TIMESTAMP(3),
ADD COLUMN     "received_at" TIMESTAMP(3),
ADD COLUMN     "received_by_collection_manager_id" TEXT,
ADD COLUMN     "submitted_to_services_at" TIMESTAMP(3),
DROP COLUMN "pricing_model",
ADD COLUMN     "pricing_model" "PricingModel" NOT NULL;

-- AlterTable
ALTER TABLE "otp_sessions" DROP COLUMN "mart_email",
DROP COLUMN "mart_email_verified",
ADD COLUMN     "business_email" VARCHAR(255),
ADD COLUMN     "business_email_verified" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "pickup_for_delivery" ALTER COLUMN "pickup_proof" DROP NOT NULL;

-- AlterTable
ALTER TABLE "services" DROP COLUMN "mart_id";

-- AlterTable
ALTER TABLE "users" DROP COLUMN "mart_id",
DROP COLUMN "role",
ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'admin';

-- DropTable
DROP TABLE "customer_mart_profile";

-- DropTable
DROP TABLE "laundry_mart";

-- DropTable
DROP TABLE "mart_daily_metrics";

-- CreateTable
CREATE TABLE "laundry_config" (
    "config_id" TEXT NOT NULL,
    "business_name" VARCHAR(255) NOT NULL,
    "contact_email" VARCHAR(255) NOT NULL,
    "contact_phone" VARCHAR(20) NOT NULL,
    "address" TEXT NOT NULL,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "service_radius_km" JSONB NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "logo_url" TEXT,

    CONSTRAINT "laundry_config_pkey" PRIMARY KEY ("config_id")
);

-- CreateTable
CREATE TABLE "collection_managers" (
    "manager_id" TEXT NOT NULL,
    "full_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "collection_managers_pkey" PRIMARY KEY ("manager_id")
);

-- CreateTable
CREATE TABLE "service_men" (
    "service_man_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "full_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "service_men_pkey" PRIMARY KEY ("service_man_id")
);

-- CreateTable
CREATE TABLE "distribution_managers" (
    "manager_id" TEXT NOT NULL,
    "full_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "distribution_managers_pkey" PRIMARY KEY ("manager_id")
);

-- CreateTable
CREATE TABLE "carts" (
    "cart_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "carts_pkey" PRIMARY KEY ("cart_id")
);

-- CreateTable
CREATE TABLE "cart_items" (
    "cart_item_id" TEXT NOT NULL,
    "cart_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "pricing_type" "PricingModel" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "weight_kg" DECIMAL(10,2),

    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("cart_item_id")
);

-- CreateTable
CREATE TABLE "cart_item_selections" (
    "selection_id" TEXT NOT NULL,
    "cart_item_id" TEXT NOT NULL,
    "cloth_id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cart_item_selections_pkey" PRIMARY KEY ("selection_id")
);

-- CreateTable
CREATE TABLE "service_queue" (
    "queue_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "service_man_id" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "item_name" VARCHAR(255) NOT NULL,
    "quantity" INTEGER NOT NULL,
    "queue_status" "QueueStatus" NOT NULL DEFAULT 'pending',
    "priority" INTEGER NOT NULL DEFAULT 0,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "comments" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "service_queue_pkey" PRIMARY KEY ("queue_id")
);

-- CreateTable
CREATE TABLE "daily_metrics" (
    "metric_id" TEXT NOT NULL,
    "metric_date" DATE NOT NULL,
    "total_orders" INTEGER NOT NULL DEFAULT 0,
    "completed_orders" INTEGER NOT NULL DEFAULT 0,
    "cancelled_orders" INTEGER NOT NULL DEFAULT 0,
    "total_revenue" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total_customers" INTEGER NOT NULL DEFAULT 0,
    "new_customers" INTEGER NOT NULL DEFAULT 0,
    "avg_order_value" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "completion_rate" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "avg_delivery_duration" INTEGER,

    CONSTRAINT "daily_metrics_pkey" PRIMARY KEY ("metric_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "laundry_config_contact_email_key" ON "laundry_config"("contact_email");

-- CreateIndex
CREATE UNIQUE INDEX "collection_managers_email_key" ON "collection_managers"("email");

-- CreateIndex
CREATE UNIQUE INDEX "service_men_service_id_key" ON "service_men"("service_id");

-- CreateIndex
CREATE UNIQUE INDEX "service_men_email_key" ON "service_men"("email");

-- CreateIndex
CREATE INDEX "service_men_service_id_idx" ON "service_men"("service_id");

-- CreateIndex
CREATE UNIQUE INDEX "distribution_managers_email_key" ON "distribution_managers"("email");

-- CreateIndex
CREATE INDEX "carts_customer_id_idx" ON "carts"("customer_id");

-- CreateIndex
CREATE INDEX "cart_items_cart_id_idx" ON "cart_items"("cart_id");

-- CreateIndex
CREATE INDEX "cart_items_service_id_idx" ON "cart_items"("service_id");

-- CreateIndex
CREATE INDEX "cart_item_selections_cart_item_id_idx" ON "cart_item_selections"("cart_item_id");

-- CreateIndex
CREATE INDEX "cart_item_selections_cloth_id_idx" ON "cart_item_selections"("cloth_id");

-- CreateIndex
CREATE INDEX "service_queue_service_id_queue_status_priority_idx" ON "service_queue"("service_id", "queue_status", "priority");

-- CreateIndex
CREATE INDEX "service_queue_order_id_idx" ON "service_queue"("order_id");

-- CreateIndex
CREATE INDEX "service_queue_service_man_id_idx" ON "service_queue"("service_man_id");

-- CreateIndex
CREATE INDEX "daily_metrics_metric_date_idx" ON "daily_metrics"("metric_date");

-- CreateIndex
CREATE UNIQUE INDEX "daily_metrics_metric_date_key" ON "daily_metrics"("metric_date");

-- CreateIndex
CREATE INDEX "bills_payment_status_idx" ON "bills"("payment_status");

-- CreateIndex
CREATE INDEX "clothes_items_service_id_idx" ON "clothes_items"("service_id");

-- CreateIndex
CREATE UNIQUE INDEX "clothes_items_service_id_item_name_key" ON "clothes_items"("service_id", "item_name");

-- CreateIndex
CREATE INDEX "delivery_delivery_type_idx" ON "delivery"("delivery_type");

-- CreateIndex
CREATE INDEX "delivery_staffs_verification_status_idx" ON "delivery_staffs"("verification_status");

-- CreateIndex
CREATE INDEX "delivery_staffs_is_verified_by_admin_idx" ON "delivery_staffs"("is_verified_by_admin");

-- CreateIndex
CREATE INDEX "order_items_item_status_idx" ON "order_items"("item_status");

-- CreateIndex
CREATE INDEX "orders_received_by_collection_manager_id_idx" ON "orders"("received_by_collection_manager_id");

-- CreateIndex
CREATE INDEX "orders_dispatched_by_distribution_manager_id_idx" ON "orders"("dispatched_by_distribution_manager_id");

-- CreateIndex
CREATE INDEX "users_role_idx" ON "users"("role");

-- AddForeignKey
ALTER TABLE "service_men" ADD CONSTRAINT "service_men_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("service_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clothes_items" ADD CONSTRAINT "clothes_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("service_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "carts" ADD CONSTRAINT "carts_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_cart_id_fkey" FOREIGN KEY ("cart_id") REFERENCES "carts"("cart_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("service_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_item_selections" ADD CONSTRAINT "cart_item_selections_cart_item_id_fkey" FOREIGN KEY ("cart_item_id") REFERENCES "cart_items"("cart_item_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_item_selections" ADD CONSTRAINT "cart_item_selections_cloth_id_fkey" FOREIGN KEY ("cloth_id") REFERENCES "clothes_items"("cloth_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_received_by_collection_manager_id_fkey" FOREIGN KEY ("received_by_collection_manager_id") REFERENCES "collection_managers"("manager_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_dispatched_by_distribution_manager_id_fkey" FOREIGN KEY ("dispatched_by_distribution_manager_id") REFERENCES "distribution_managers"("manager_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_clothes_id_fkey" FOREIGN KEY ("clothes_id") REFERENCES "clothes_items"("cloth_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_queue" ADD CONSTRAINT "service_queue_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_queue" ADD CONSTRAINT "service_queue_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("service_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_queue" ADD CONSTRAINT "service_queue_service_man_id_fkey" FOREIGN KEY ("service_man_id") REFERENCES "service_men"("service_man_id") ON DELETE RESTRICT ON UPDATE CASCADE;
