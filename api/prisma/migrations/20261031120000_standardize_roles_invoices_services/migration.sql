ALTER TYPE "ServiceRequestStatus"
ADD VALUE IF NOT EXISTS 'WAITING_RESIDENT' BEFORE 'COMPLETED';

ALTER TABLE "invoices"
ADD COLUMN "published_by_id" UUID,
ADD COLUMN "published_at" TIMESTAMPTZ(6);

UPDATE "invoices"
SET
  "published_by_id" = "created_by_id",
  "published_at" = "issued_at"
WHERE "status" <> 'DRAFT';

CREATE INDEX "invoices_published_by_id_idx"
ON "invoices"("published_by_id");

ALTER TABLE "invoices"
ADD CONSTRAINT "invoices_published_by_id_fkey"
FOREIGN KEY ("published_by_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE "service_request_updates" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "service_request_id" UUID NOT NULL,
  "actor_id" UUID NOT NULL,
  "status" "ServiceRequestStatus" NOT NULL,
  "note" TEXT,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "service_request_updates_pkey" PRIMARY KEY ("id")
);

INSERT INTO "service_request_updates" (
  "service_request_id",
  "actor_id",
  "status",
  "note",
  "created_at"
)
SELECT
  "id",
  COALESCE("assigned_to_id", "created_by_id", "requested_by_id"),
  "status",
  COALESCE("management_note", 'Khởi tạo lịch sử từ dữ liệu hiện có.'),
  "updated_at"
FROM "service_requests";

CREATE INDEX "service_request_updates_service_request_id_created_at_idx"
ON "service_request_updates"("service_request_id", "created_at");

CREATE INDEX "service_request_updates_actor_id_idx"
ON "service_request_updates"("actor_id");

ALTER TABLE "service_request_updates"
ADD CONSTRAINT "service_request_updates_service_request_id_fkey"
FOREIGN KEY ("service_request_id") REFERENCES "service_requests"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "service_request_updates"
ADD CONSTRAINT "service_request_updates_actor_id_fkey"
FOREIGN KEY ("actor_id") REFERENCES "users"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
