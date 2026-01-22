-- Drop cross-side fields so pickup_for_delivery stores only pickup details,
-- and drop_for_delivery stores only drop details.

ALTER TABLE pickup_for_delivery
    DROP COLUMN IF EXISTS drop_address,
    DROP COLUMN IF EXISTS drop_lat,
    DROP COLUMN IF EXISTS drop_lng;

ALTER TABLE drop_for_delivery
    DROP COLUMN IF EXISTS pickup_address,
    DROP COLUMN IF EXISTS pickup_lat,
    DROP COLUMN IF EXISTS pickup_lng;

