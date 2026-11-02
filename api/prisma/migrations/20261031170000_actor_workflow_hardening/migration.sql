-- One account has one primary role. Keep the same priority previously used by Flutter.
WITH ranked_roles AS (
  SELECT ur.id,
         ROW_NUMBER() OVER (
           PARTITION BY ur.user_id
           ORDER BY CASE r.code::text
             WHEN 'ADMIN' THEN 1
             WHEN 'MANAGEMENT' THEN 2
             WHEN 'ACCOUNTANT' THEN 3
             WHEN 'RECEPTIONIST' THEN 4
             WHEN 'SECURITY' THEN 5
             WHEN 'TECHNICIAN' THEN 6
             ELSE 7
           END,
           ur.assigned_at
         ) AS position
  FROM user_roles ur
  JOIN roles r ON r.id = ur.role_id
)
DELETE FROM user_roles
WHERE id IN (SELECT id FROM ranked_roles WHERE position > 1);

ALTER TABLE "user_roles" DROP CONSTRAINT IF EXISTS "user_roles_user_id_role_id_key";
CREATE UNIQUE INDEX IF NOT EXISTS "user_roles_user_id_key" ON "user_roles"("user_id");

ALTER TYPE "TemporaryStayStatus" ADD VALUE IF NOT EXISTS 'CHECKED_IN';
ALTER TYPE "TemporaryStayStatus" ADD VALUE IF NOT EXISTS 'CHECKED_OUT';
ALTER TYPE "AmenityBookingStatus" ADD VALUE IF NOT EXISTS 'CHECKED_IN';
ALTER TYPE "AmenityBookingStatus" ADD VALUE IF NOT EXISTS 'COMPLETED';
ALTER TYPE "AmenityBookingStatus" ADD VALUE IF NOT EXISTS 'NO_SHOW';

ALTER TABLE "temporary_stays"
  ADD COLUMN "checked_in_by_id" UUID,
  ADD COLUMN "checked_out_by_id" UUID,
  ADD COLUMN "checked_in_at" TIMESTAMPTZ(6),
  ADD COLUMN "checked_out_at" TIMESTAMPTZ(6);

ALTER TABLE "temporary_stays"
  ADD CONSTRAINT "temporary_stays_checked_in_by_id_fkey"
    FOREIGN KEY ("checked_in_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT "temporary_stays_checked_out_by_id_fkey"
    FOREIGN KEY ("checked_out_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "security_incidents"
  ADD COLUMN "assigned_to_id" UUID,
  ADD COLUMN "assigned_by_id" UUID,
  ADD COLUMN "assigned_at" TIMESTAMPTZ(6);

ALTER TABLE "security_incidents"
  ADD CONSTRAINT "security_incidents_assigned_to_id_fkey"
    FOREIGN KEY ("assigned_to_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT "security_incidents_assigned_by_id_fkey"
    FOREIGN KEY ("assigned_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "security_incidents_assigned_to_id_status_idx"
  ON "security_incidents"("assigned_to_id", "status");

CREATE TABLE "security_incident_updates" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "security_incident_id" UUID NOT NULL,
  "actor_id" UUID NOT NULL,
  "status" "SecurityIncidentStatus" NOT NULL,
  "note" TEXT,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "security_incident_updates_pkey" PRIMARY KEY ("id")
);

INSERT INTO "security_incident_updates" (
  "security_incident_id", "actor_id", "status", "note", "created_at"
)
SELECT "id", "reported_by_id", 'REPORTED', 'Sự cố đã được ghi nhận.', "created_at"
FROM "security_incidents";

CREATE INDEX "security_incident_updates_security_incident_id_created_at_idx"
  ON "security_incident_updates"("security_incident_id", "created_at");
CREATE INDEX "security_incident_updates_actor_id_idx"
  ON "security_incident_updates"("actor_id");

ALTER TABLE "security_incident_updates"
  ADD CONSTRAINT "security_incident_updates_security_incident_id_fkey"
    FOREIGN KEY ("security_incident_id") REFERENCES "security_incidents"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT "security_incident_updates_actor_id_fkey"
    FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "amenity_bookings"
  ADD COLUMN "processed_by_id" UUID,
  ADD COLUMN "checked_in_at" TIMESTAMPTZ(6),
  ADD COLUMN "completed_at" TIMESTAMPTZ(6);

ALTER TABLE "amenity_bookings"
  ADD CONSTRAINT "amenity_bookings_processed_by_id_fkey"
    FOREIGN KEY ("processed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
