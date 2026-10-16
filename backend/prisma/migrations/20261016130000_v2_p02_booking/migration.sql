-- CreateEnum
CREATE TYPE "ScheduleMode" AS ENUM ('instant', 'scheduled');

-- AlterTable orders
ALTER TABLE "orders" ADD COLUMN "is_express" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "orders" ADD COLUMN "pickup_mode" "ScheduleMode" NOT NULL DEFAULT 'instant';
ALTER TABLE "orders" ADD COLUMN "delivery_mode" "ScheduleMode" NOT NULL DEFAULT 'instant';
ALTER TABLE "orders" ADD COLUMN "cancel_reason" TEXT;
ALTER TABLE "orders" ADD COLUMN "cancelled_at" TIMESTAMP(3);
ALTER TABLE "orders" ADD COLUMN "items_confirmed_at" TIMESTAMP(3);
ALTER TABLE "orders" ALTER COLUMN "pricing_model" DROP NOT NULL;
ALTER TABLE "orders" ALTER COLUMN "total_amount" SET DEFAULT 0;

-- AlterTable order_items
ALTER TABLE "order_items" ALTER COLUMN "unit_price" DROP NOT NULL;
ALTER TABLE "order_items" ALTER COLUMN "subtotal" SET DEFAULT 0;

-- Drop cart selections (v2 books services only)
DROP TABLE IF EXISTS "cart_item_selections";

-- Drop weight from cart items
ALTER TABLE "cart_items" DROP COLUMN IF EXISTS "weight_kg";

-- One line per service: keep the newest row per (cart_id, service_id)
DELETE FROM "cart_items" a
USING "cart_items" b
WHERE a.cart_id = b.cart_id
  AND a.service_id = b.service_id
  AND a.created_at < b.created_at;

CREATE UNIQUE INDEX IF NOT EXISTS "cart_items_cart_id_service_id_key" ON "cart_items"("cart_id", "service_id");
