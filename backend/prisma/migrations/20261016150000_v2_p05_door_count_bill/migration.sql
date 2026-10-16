ALTER TABLE "order_items"
  ADD COLUMN "photo_url" VARCHAR(500);

ALTER TABLE "order_item_selections"
  ADD COLUMN "unit_price" DECIMAL(10,2);

ALTER TABLE "bills"
  ADD COLUMN "express_fee" DECIMAL(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN "coupon_id" INTEGER,
  ADD COLUMN "coupon_code" VARCHAR(255),
  ADD COLUMN "cash_recorded_by" VARCHAR(100);

ALTER TABLE "bills"
  ALTER COLUMN "payment_method" DROP NOT NULL;

ALTER TABLE "bills"
  ADD CONSTRAINT "bills_coupon_id_fkey"
  FOREIGN KEY ("coupon_id") REFERENCES "coupons"("id") ON DELETE SET NULL ON UPDATE CASCADE;
