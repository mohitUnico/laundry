-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "source_cart_id" TEXT;

-- CreateIndex
CREATE INDEX "orders_source_cart_id_idx" ON "orders"("source_cart_id");
