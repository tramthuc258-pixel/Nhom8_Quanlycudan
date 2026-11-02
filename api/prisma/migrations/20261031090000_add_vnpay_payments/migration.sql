ALTER TYPE "PaymentMethod" ADD VALUE IF NOT EXISTS 'VNPAY';

ALTER TABLE "payments"
ALTER COLUMN "paid_at" DROP NOT NULL;

DROP INDEX IF EXISTS "payments_transaction_code_idx";
CREATE UNIQUE INDEX "payments_transaction_code_key"
ON "payments"("transaction_code");
