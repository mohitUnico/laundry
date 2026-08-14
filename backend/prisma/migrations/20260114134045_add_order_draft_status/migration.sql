-- Add draft status for order draft creation -> confirmation flow
DO $$
BEGIN
  -- Place draft before placed for readability; works on modern Postgres.
  ALTER TYPE "OrderStatus" ADD VALUE IF NOT EXISTS 'draft' BEFORE 'placed';
EXCEPTION
  WHEN duplicate_object THEN
    -- Enum value already exists, ignore.
    NULL;
END $$;

