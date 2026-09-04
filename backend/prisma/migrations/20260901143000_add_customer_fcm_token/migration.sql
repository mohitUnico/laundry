-- AlterTable
ALTER TABLE "customers" ADD COLUMN IF NOT EXISTS "fcm_token" VARCHAR(255);
