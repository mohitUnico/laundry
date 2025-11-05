-- AlterTable
ALTER TABLE "otp_sessions" ADD COLUMN     "mart_email" VARCHAR(255),
ADD COLUMN     "mart_email_verified" BOOLEAN NOT NULL DEFAULT false;
