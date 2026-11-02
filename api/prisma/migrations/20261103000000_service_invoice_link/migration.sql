ALTER TABLE "service_requests" ADD COLUMN "billed_invoice_item_id" UUID;
CREATE UNIQUE INDEX "service_requests_billed_invoice_item_id_key" ON "service_requests"("billed_invoice_item_id");
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_billed_invoice_item_id_fkey"
  FOREIGN KEY ("billed_invoice_item_id") REFERENCES "invoice_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;
