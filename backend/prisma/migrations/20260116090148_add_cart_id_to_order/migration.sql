-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "cart_id" TEXT;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_cart_id_fkey" FOREIGN KEY ("cart_id") REFERENCES "carts"("cart_id") ON DELETE SET NULL ON UPDATE CASCADE;
