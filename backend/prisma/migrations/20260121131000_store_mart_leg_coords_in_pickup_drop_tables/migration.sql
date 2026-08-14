-- Store mart-leg coordinates inside pickup_for_delivery / drop_for_delivery for convenience
-- - pickup deliveries: pickup = customer, drop = mart (store drop_* on pickup_for_delivery)
-- - drop deliveries: pickup = mart (store pickup_* on drop_for_delivery), drop = customer

ALTER TABLE "pickup_for_delivery"
    ADD COLUMN IF NOT EXISTS "drop_address" TEXT,
    ADD COLUMN IF NOT EXISTS "drop_lat" DECIMAL(10,8),
    ADD COLUMN IF NOT EXISTS "drop_lng" DECIMAL(11,8);

ALTER TABLE "drop_for_delivery"
    ADD COLUMN IF NOT EXISTS "pickup_address" TEXT,
    ADD COLUMN IF NOT EXISTS "pickup_lat" DECIMAL(10,8),
    ADD COLUMN IF NOT EXISTS "pickup_lng" DECIMAL(11,8);

