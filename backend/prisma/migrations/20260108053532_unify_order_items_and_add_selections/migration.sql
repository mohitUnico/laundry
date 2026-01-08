/*
  Warnings:

  - You are about to drop the `order_items_kg` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `pricing_type` to the `order_items` table without a default value. This is not possible if the table is not empty.
  - Added the required column `service_id` to the `order_items` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "order_items" DROP CONSTRAINT "order_items_clothes_id_fkey";

-- DropForeignKey
ALTER TABLE "order_items_kg" DROP CONSTRAINT "order_items_kg_order_id_fkey";

-- DropForeignKey
ALTER TABLE "staff" DROP CONSTRAINT "staff_service_id_fkey";

-- AlterTable
ALTER TABLE "order_items" ADD COLUMN     "pricing_type" "PricingModel" NOT NULL,
ADD COLUMN     "service_id" TEXT NOT NULL,
ADD COLUMN     "weight_kg" DECIMAL(10,2),
ALTER COLUMN "clothes_id" DROP NOT NULL,
ALTER COLUMN "quantity" DROP NOT NULL;

-- DropTable
DROP TABLE "order_items_kg";

-- CreateTable
CREATE TABLE "order_item_selections" (
    "selection_id" TEXT NOT NULL,
    "order_item_id" TEXT NOT NULL,
    "cloth_id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_item_selections_pkey" PRIMARY KEY ("selection_id")
);

-- CreateIndex
CREATE INDEX "order_item_selections_order_item_id_idx" ON "order_item_selections"("order_item_id");

-- CreateIndex
CREATE INDEX "order_item_selections_cloth_id_idx" ON "order_item_selections"("cloth_id");

-- CreateIndex
CREATE INDEX "order_items_service_id_idx" ON "order_items"("service_id");

-- CreateIndex
CREATE INDEX "order_items_pricing_type_idx" ON "order_items"("pricing_type");

-- AddForeignKey
ALTER TABLE "staff" ADD CONSTRAINT "staff_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("service_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_clothes_id_fkey" FOREIGN KEY ("clothes_id") REFERENCES "clothes_items"("cloth_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("service_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_item_selections" ADD CONSTRAINT "order_item_selections_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("item_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_item_selections" ADD CONSTRAINT "order_item_selections_cloth_id_fkey" FOREIGN KEY ("cloth_id") REFERENCES "clothes_items"("cloth_id") ON DELETE RESTRICT ON UPDATE CASCADE;
