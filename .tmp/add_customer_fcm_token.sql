-- Adds an FCM token column to customers for push notifications.
-- Safe to run multiple times.
ALTER TABLE IF EXISTS "customers"
  ADD COLUMN IF NOT EXISTS "fcm_token" VARCHAR(255);


