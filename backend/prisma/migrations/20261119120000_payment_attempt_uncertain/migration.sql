-- Add a non-destructive attempt status for unknown gateway outcomes.
-- A new enum value cannot be used in the same migration transaction, so the
-- partial unique index that references it lives in the next migration.
ALTER TYPE "PaymentAttemptStatus" ADD VALUE IF NOT EXISTS 'uncertain';
