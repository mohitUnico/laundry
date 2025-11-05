/*
  Warnings:

  - You are about to drop the column `otp_type` on the `otp_verifications` table. All the data in the column will be lost.
  - You are about to drop the column `user_data` on the `otp_verifications` table. All the data in the column will be lost.
  - Added the required column `purpose` to the `otp_verifications` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "otp_verifications_phone_otp_type_idx";

-- AlterTable
ALTER TABLE "otp_verifications" DROP COLUMN "otp_type",
DROP COLUMN "user_data",
ADD COLUMN     "purpose" VARCHAR(50) NOT NULL;

-- CreateTable
CREATE TABLE "otp_sessions" (
    "session_id" TEXT NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "user_type" VARCHAR(30) NOT NULL,
    "is_new_user" BOOLEAN NOT NULL,
    "user_id" TEXT,
    "session_token" VARCHAR(500) NOT NULL,
    "is_completed" BOOLEAN NOT NULL DEFAULT false,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "otp_sessions_pkey" PRIMARY KEY ("session_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "otp_sessions_session_token_key" ON "otp_sessions"("session_token");

-- CreateIndex
CREATE INDEX "otp_sessions_phone_idx" ON "otp_sessions"("phone");

-- CreateIndex
CREATE INDEX "otp_sessions_session_token_idx" ON "otp_sessions"("session_token");

-- CreateIndex
CREATE INDEX "otp_sessions_expires_at_idx" ON "otp_sessions"("expires_at");

-- CreateIndex
CREATE INDEX "otp_verifications_phone_purpose_idx" ON "otp_verifications"("phone", "purpose");
