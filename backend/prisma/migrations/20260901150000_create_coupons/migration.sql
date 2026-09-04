-- CreateTable
CREATE TABLE IF NOT EXISTS "coupons" (
    "id" SERIAL NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "discount_type" VARCHAR(50) NOT NULL,
    "discount_value" DECIMAL(12,2) NOT NULL,
    "max_discount" DECIMAL(12,2),
    "min_order_value" DECIMAL(12,2),
    "usage_limit" INTEGER,
    "usage_per_user" INTEGER,
    "valid_from" TIMESTAMP(3),
    "valid_till" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "coupons_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "coupons_code_idx" ON "coupons"("code");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "coupons_is_active_idx" ON "coupons"("is_active");
