CREATE TYPE "PaymentAttemptStatus" AS ENUM ('initiated', 'pending', 'succeeded', 'failed', 'cancelled', 'expired');

CREATE TABLE "payment_attempts" (
  "attempt_id" SERIAL NOT NULL,
  "order_id" TEXT NOT NULL,
  "bill_id" TEXT NOT NULL,
  "provider" VARCHAR(30) NOT NULL,
  "provider_ref" VARCHAR(100),
  "idempotency_key" VARCHAR(100) NOT NULL,
  "amount" DECIMAL(10,2) NOT NULL,
  "status" "PaymentAttemptStatus" NOT NULL DEFAULT 'initiated',
  "intent_payload" JSONB,
  "failure_reason" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "payment_attempts_pkey" PRIMARY KEY ("attempt_id")
);

CREATE UNIQUE INDEX "payment_attempts_idempotency_key_key" ON "payment_attempts"("idempotency_key");
CREATE INDEX "payment_attempts_order_id_status_idx" ON "payment_attempts"("order_id", "status");
CREATE INDEX "payment_attempts_provider_ref_idx" ON "payment_attempts"("provider_ref");

ALTER TABLE "payment_attempts"
  ADD CONSTRAINT "payment_attempts_order_id_fkey"
  FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "payment_attempts"
  ADD CONSTRAINT "payment_attempts_bill_id_fkey"
  FOREIGN KEY ("bill_id") REFERENCES "bills"("bill_id") ON DELETE CASCADE ON UPDATE CASCADE;
