CREATE TABLE "staff_building_assignments" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "building_id" UUID NOT NULL,
    "assigned_by_id" UUID,
    "start_date" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "end_date" TIMESTAMPTZ(6),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_building_assignments_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "staff_building_assignments_user_id_building_id_key"
ON "staff_building_assignments"("user_id", "building_id");

CREATE INDEX "staff_building_assignments_user_id_is_active_idx"
ON "staff_building_assignments"("user_id", "is_active");

CREATE INDEX "staff_building_assignments_building_id_is_active_idx"
ON "staff_building_assignments"("building_id", "is_active");

ALTER TABLE "staff_building_assignments"
ADD CONSTRAINT "staff_building_assignments_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "staff_building_assignments"
ADD CONSTRAINT "staff_building_assignments_building_id_fkey"
FOREIGN KEY ("building_id") REFERENCES "buildings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "staff_building_assignments"
ADD CONSTRAINT "staff_building_assignments_assigned_by_id_fkey"
FOREIGN KEY ("assigned_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
