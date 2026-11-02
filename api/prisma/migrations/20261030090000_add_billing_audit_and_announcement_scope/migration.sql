ALTER TABLE "invoices"
ADD COLUMN "created_by_id" UUID;

ALTER TABLE "payments"
ADD COLUMN "confirmed_by_id" UUID;

ALTER TABLE "announcements"
ADD COLUMN "building_id" UUID;

ALTER TABLE "invoices"
ADD CONSTRAINT "invoices_created_by_id_fkey"
FOREIGN KEY ("created_by_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "payments"
ADD CONSTRAINT "payments_confirmed_by_id_fkey"
FOREIGN KEY ("confirmed_by_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "announcements"
ADD CONSTRAINT "announcements_building_id_fkey"
FOREIGN KEY ("building_id") REFERENCES "buildings"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX "invoices_created_by_id_idx" ON "invoices"("created_by_id");
CREATE INDEX "payments_confirmed_by_id_idx" ON "payments"("confirmed_by_id");
CREATE INDEX "announcements_building_id_is_published_published_at_idx"
ON "announcements"("building_id", "is_published", "published_at");
