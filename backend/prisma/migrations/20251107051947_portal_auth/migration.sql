-- CreateTable
CREATE TABLE "portal_users" (
    "id" TEXT NOT NULL,
    "name" VARCHAR(255),
    "email" VARCHAR(255),
    "phone" VARCHAR(20),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "portal_users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portal_otp_verifications" (
    "id" TEXT NOT NULL,
    "identifier" VARCHAR(255) NOT NULL,
    "otp" VARCHAR(6) NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "portal_otp_verifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "portal_users_email_key" ON "portal_users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "portal_users_phone_key" ON "portal_users"("phone");

-- CreateIndex
CREATE INDEX "portal_otp_verifications_identifier_idx" ON "portal_otp_verifications"("identifier");
