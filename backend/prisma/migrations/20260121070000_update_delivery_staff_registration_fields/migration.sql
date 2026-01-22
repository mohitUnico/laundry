-- Update delivery_staffs table to support new delivery-staff registration flow
-- - store address + current coordinates
-- - store document/profile URLs
-- - remove obsolete password/license_number/document_url fields (OTP auth + license document upload)

ALTER TABLE "delivery_staffs"
    ADD COLUMN IF NOT EXISTS "address" VARCHAR(500),
    ADD COLUMN IF NOT EXISTS "current_latitude" DECIMAL(10,8),
    ADD COLUMN IF NOT EXISTS "current_longitude" DECIMAL(11,8),
    ADD COLUMN IF NOT EXISTS "profile_image_url" VARCHAR(500),
    ADD COLUMN IF NOT EXISTS "driving_license_url" VARCHAR(500);

ALTER TABLE "delivery_staffs"
    DROP COLUMN IF EXISTS "password",
    DROP COLUMN IF EXISTS "license_number",
    DROP COLUMN IF EXISTS "document_url";

