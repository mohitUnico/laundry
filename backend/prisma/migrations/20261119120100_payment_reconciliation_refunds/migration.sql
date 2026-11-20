-- AlterTable
ALTER TABLE "payment_attempts"
ADD COLUMN "razorpay_payment_id" VARCHAR(100),
ADD COLUMN "last_checked_at" TIMESTAMP(3),
ADD COLUMN "check_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "reconciliation_status" VARCHAR(30);

-- CreateIndex
CREATE UNIQUE INDEX "payment_attempts_razorpay_payment_id_key" ON "payment_attempts"("razorpay_payment_id");
CREATE INDEX "payment_attempts_status_last_checked_at_idx" ON "payment_attempts"("status", "last_checked_at");

-- One open checkout per order. Failed, cancelled, expired, and succeeded rows stay insertable.
CREATE UNIQUE INDEX "payment_attempts_one_live_per_order"
ON "payment_attempts" ("order_id")
WHERE "status" IN ('initiated', 'pending', 'uncertain');

-- CreateTable
CREATE TABLE "payment_webhook_events" (
    "id" TEXT NOT NULL,
    "event_id" VARCHAR(120) NOT NULL,
    "event_name" VARCHAR(80) NOT NULL,
    "status" VARCHAR(20) NOT NULL,
    "attempt_id" INTEGER,
    "error" VARCHAR(300),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processed_at" TIMESTAMP(3),

    CONSTRAINT "payment_webhook_events_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "payment_webhook_events_event_id_key" ON "payment_webhook_events"("event_id");
CREATE INDEX "payment_webhook_events_status_idx" ON "payment_webhook_events"("status");

ALTER TABLE "payment_webhook_events"
ADD CONSTRAINT "payment_webhook_events_attempt_id_fkey"
FOREIGN KEY ("attempt_id") REFERENCES "payment_attempts"("attempt_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "payment_refunds" (
    "id" TEXT NOT NULL,
    "attempt_id" INTEGER NOT NULL,
    "bill_id" TEXT NOT NULL,
    "razorpay_payment_id" VARCHAR(100) NOT NULL,
    "razorpay_refund_id" VARCHAR(100),
    "amount" DECIMAL(10,2) NOT NULL,
    "status" VARCHAR(20) NOT NULL,
    "reason" VARCHAR(255) NOT NULL,
    "idempotency_key" VARCHAR(120) NOT NULL,
    "created_by" VARCHAR(100),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_refunds_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "payment_refunds_razorpay_refund_id_key" ON "payment_refunds"("razorpay_refund_id");
CREATE UNIQUE INDEX "payment_refunds_idempotency_key_key" ON "payment_refunds"("idempotency_key");
CREATE INDEX "payment_refunds_razorpay_payment_id_idx" ON "payment_refunds"("razorpay_payment_id");
CREATE INDEX "payment_refunds_status_idx" ON "payment_refunds"("status");

ALTER TABLE "payment_refunds"
ADD CONSTRAINT "payment_refunds_attempt_id_fkey"
FOREIGN KEY ("attempt_id") REFERENCES "payment_attempts"("attempt_id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "payment_refunds"
ADD CONSTRAINT "payment_refunds_bill_id_fkey"
FOREIGN KEY ("bill_id") REFERENCES "bills"("bill_id") ON DELETE CASCADE ON UPDATE CASCADE;
