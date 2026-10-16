ALTER TABLE "service_queue"
  ADD COLUMN "is_express" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX "service_queue_service_id_queue_status_is_express_assigned_at_idx"
  ON "service_queue"("service_id", "queue_status", "is_express", "assigned_at");
