-- Thành viên trong hộ là hồ sơ cư trú, không phải tài khoản đăng nhập.
CREATE TYPE "HouseholdMemberStatus" AS ENUM ('ACTIVE', 'ENDED');

CREATE TABLE "household_members" (
    "id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "created_by_id" UUID NOT NULL,
    "full_name" VARCHAR(150) NOT NULL,
    "date_of_birth" DATE,
    "phone" VARCHAR(20),
    "relationship" VARCHAR(100) NOT NULL,
    "start_date" DATE NOT NULL,
    "end_date" DATE,
    "status" "HouseholdMemberStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "household_members_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "household_members_apartment_id_status_idx"
ON "household_members"("apartment_id", "status");

CREATE INDEX "household_members_created_by_id_idx"
ON "household_members"("created_by_id");

ALTER TABLE "household_members"
ADD CONSTRAINT "household_members_apartment_id_fkey"
FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "household_members"
ADD CONSTRAINT "household_members_created_by_id_fkey"
FOREIGN KEY ("created_by_id") REFERENCES "users"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- Chuyển dữ liệu MEMBER cũ thành hồ sơ thành viên không có tài khoản.
INSERT INTO "household_members" (
    "id", "apartment_id", "created_by_id", "full_name", "date_of_birth",
    "phone", "relationship", "start_date", "end_date", "status",
    "created_at", "updated_at"
)
SELECT
    membership."id",
    membership."apartment_id",
    COALESCE(owner_membership."user_id", membership."user_id"),
    account."full_name",
    account."date_of_birth",
    account."phone",
    'Thành viên gia đình',
    membership."start_date",
    membership."end_date",
    CASE
        WHEN membership."status" = 'ACTIVE' THEN 'ACTIVE'::"HouseholdMemberStatus"
        ELSE 'ENDED'::"HouseholdMemberStatus"
    END,
    membership."created_at",
    membership."updated_at"
FROM "apartment_memberships" membership
JOIN "users" account ON account."id" = membership."user_id"
LEFT JOIN LATERAL (
    SELECT owner."user_id"
    FROM "apartment_memberships" owner
    WHERE owner."apartment_id" = membership."apartment_id"
      AND owner."type" = 'OWNER'
      AND owner."status" = 'ACTIVE'
    LIMIT 1
) owner_membership ON TRUE
WHERE membership."type" = 'MEMBER';

DELETE FROM "apartment_memberships" WHERE "type" = 'MEMBER';

-- Mỗi căn hộ chỉ có tối đa một chủ sở hữu và một người thuê đại diện đang hiệu lực.
CREATE UNIQUE INDEX "one_active_owner_per_apartment"
ON "apartment_memberships"("apartment_id")
WHERE "type" = 'OWNER' AND "status" = 'ACTIVE';

CREATE UNIQUE INDEX "one_active_tenant_per_apartment"
ON "apartment_memberships"("apartment_id")
WHERE "type" = 'TENANT' AND "status" = 'ACTIVE';
