-- Add preferred pickup/delivery time windows on orders and delivery leg tables.
-- This supports creating delivery + pickup_for_delivery/drop_for_delivery immediately on order confirmation.

ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS pickup_time_from TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS pickup_time_to   TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS delivery_time_from TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS delivery_time_to   TIMESTAMPTZ NULL;

ALTER TABLE pickup_for_delivery
    ADD COLUMN IF NOT EXISTS preferred_pickup_from TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS preferred_pickup_to   TIMESTAMPTZ NULL;

ALTER TABLE drop_for_delivery
    ADD COLUMN IF NOT EXISTS preferred_drop_from TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS preferred_drop_to   TIMESTAMPTZ NULL;

