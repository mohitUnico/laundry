-- AlterTable
ALTER TABLE "cart_item_selections"
    ADD COLUMN "unit_price" DECIMAL(10,2) NOT NULL DEFAULT 0,
    ADD COLUMN "subtotal" DECIMAL(10,2) NOT NULL DEFAULT 0;

