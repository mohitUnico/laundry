-- AlterTable
ALTER TABLE "order_items" ALTER COLUMN "unit_price" DROP NOT NULL,
ALTER COLUMN "subtotal" DROP NOT NULL;

-- AlterTable
ALTER TABLE "orders" ALTER COLUMN "total_amount" DROP NOT NULL;
