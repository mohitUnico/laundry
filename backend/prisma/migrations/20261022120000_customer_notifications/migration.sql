-- Customer inbox for GET /api/v1/notifications.
-- notification_deliveries stays the push dedupe log.

CREATE TABLE "customer_notifications" (
    "notification_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "event" VARCHAR(60) NOT NULL,
    "title" VARCHAR(120) NOT NULL,
    "order_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customer_notifications_pkey" PRIMARY KEY ("notification_id")
);

CREATE INDEX "customer_notifications_customer_id_created_at_idx"
    ON "customer_notifications"("customer_id", "created_at");

ALTER TABLE "customer_notifications"
    ADD CONSTRAINT "customer_notifications_customer_id_fkey"
    FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id")
    ON DELETE CASCADE ON UPDATE CASCADE;
