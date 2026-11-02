-- MEMBER đã được chuyển sang bảng household_members ở migration trước.
-- Quan hệ tài khoản với căn hộ từ đây chỉ còn OWNER và TENANT.
DROP INDEX IF EXISTS "one_active_owner_per_apartment";
DROP INDEX IF EXISTS "one_active_tenant_per_apartment";

DROP TYPE IF EXISTS "MembershipType_new";
CREATE TYPE "MembershipType_new" AS ENUM ('OWNER', 'TENANT');

ALTER TABLE "apartment_memberships"
ALTER COLUMN "type" TYPE "MembershipType_new"
USING ("type"::text::"MembershipType_new");

DROP TYPE "MembershipType";
ALTER TYPE "MembershipType_new" RENAME TO "MembershipType";

CREATE UNIQUE INDEX "one_active_owner_per_apartment"
ON "apartment_memberships"("apartment_id")
WHERE "type" = 'OWNER' AND "status" = 'ACTIVE';

CREATE UNIQUE INDEX "one_active_tenant_per_apartment"
ON "apartment_memberships"("apartment_id")
WHERE "type" = 'TENANT' AND "status" = 'ACTIVE';
