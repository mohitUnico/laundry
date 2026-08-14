-- Add new enum value for order_status: submitted_to_cm
-- Note: Postgres enum values are append-only (ordering doesn't matter for correctness).
ALTER TYPE "OrderStatus" ADD VALUE IF NOT EXISTS 'submitted_to_cm';


