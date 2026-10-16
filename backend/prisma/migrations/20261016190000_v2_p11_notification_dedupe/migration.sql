CREATE TABLE "notification_deliveries" (
  "id" TEXT NOT NULL,
  "order_id" TEXT NOT NULL,
  "event" VARCHAR(60) NOT NULL,
  "recipient_key" VARCHAR(120) NOT NULL,
  "channel" VARCHAR(20) NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "notification_deliveries_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "notification_deliveries_order_id_event_recipient_key_channel_key"
  ON "notification_deliveries"("order_id", "event", "recipient_key", "channel");

CREATE INDEX "notification_deliveries_order_id_event_idx"
  ON "notification_deliveries"("order_id", "event");
