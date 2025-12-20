-- CreateTable
CREATE TABLE "portal_registration_sessions" (
    "id" TEXT NOT NULL,
    "identifier" VARCHAR(255) NOT NULL,
    "identifier_type" VARCHAR(20) NOT NULL,
    "session_token" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "portal_registration_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "portal_registration_sessions_identifier_key" ON "portal_registration_sessions"("identifier");

-- CreateIndex
CREATE UNIQUE INDEX "portal_registration_sessions_session_token_key" ON "portal_registration_sessions"("session_token");

-- CreateIndex
CREATE INDEX "portal_registration_sessions_expires_at_idx" ON "portal_registration_sessions"("expires_at");

