CREATE TYPE "ResidenceVerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

CREATE TABLE "residence_verification_requests" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "type" "MembershipType" NOT NULL,
    "status" "ResidenceVerificationStatus" NOT NULL DEFAULT 'PENDING',
    "start_date" DATE NOT NULL,
    "reference_code" VARCHAR(100),
    "note" TEXT,
    "review_note" TEXT,
    "reviewed_by_id" UUID,
    "reviewed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "residence_verification_requests_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "residence_verification_requests_user_id_created_at_idx"
ON "residence_verification_requests"("user_id", "created_at");

CREATE INDEX "residence_verification_requests_apartment_id_status_idx"
ON "residence_verification_requests"("apartment_id", "status");

CREATE INDEX "residence_verification_requests_status_created_at_idx"
ON "residence_verification_requests"("status", "created_at");

CREATE UNIQUE INDEX "residence_verification_requests_one_pending_per_user"
ON "residence_verification_requests"("user_id")
WHERE "status" = 'PENDING';

ALTER TABLE "residence_verification_requests"
ADD CONSTRAINT "residence_verification_requests_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "residence_verification_requests"
ADD CONSTRAINT "residence_verification_requests_reviewed_by_id_fkey"
FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "residence_verification_requests"
ADD CONSTRAINT "residence_verification_requests_apartment_id_fkey"
FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
