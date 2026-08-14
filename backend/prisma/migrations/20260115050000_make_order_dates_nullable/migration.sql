-- Make pickup_date and delivery_date optional (nullable)
-- This matches schema.prisma where both fields are DateTime?

ALTER TABLE "orders" ALTER COLUMN "pickup_date" DROP NOT NULL;
ALTER TABLE "orders" ALTER COLUMN "delivery_date" DROP NOT NULL;

