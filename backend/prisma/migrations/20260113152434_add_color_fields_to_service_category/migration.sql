-- Add background_color and foreground_color fields to service_categories
ALTER TABLE "service_categories" ADD COLUMN "background_color" VARCHAR(7);
ALTER TABLE "service_categories" ADD COLUMN "foreground_color" VARCHAR(7);

