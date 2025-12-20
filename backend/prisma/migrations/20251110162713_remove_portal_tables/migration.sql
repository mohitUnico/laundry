-- Remove portal-specific tables that are no longer needed
-- Portal authentication now uses OtpVerification and OtpSession tables

-- Drop portal tables
DROP TABLE IF EXISTS "portal_registration_sessions" CASCADE;
DROP TABLE IF EXISTS "portal_otp_verifications" CASCADE;
DROP TABLE IF EXISTS "portal_users" CASCADE;

