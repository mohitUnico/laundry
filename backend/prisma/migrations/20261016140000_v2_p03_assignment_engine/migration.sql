ALTER TABLE "delivery_assignment_requests"
  ADD COLUMN "slice_count" INTEGER NOT NULL DEFAULT 5,
  ADD COLUMN "current_slice" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "max_range_km" DECIMAL(8,2),
  ADD COLUMN "next_slice_at" TIMESTAMP(3),
  ADD COLUMN "ended_reason" VARCHAR(30);

ALTER TABLE "delivery_assignment_recipients"
  ADD COLUMN "slice_index" INTEGER,
  ADD COLUMN "distance_km" DECIMAL(8,2);
