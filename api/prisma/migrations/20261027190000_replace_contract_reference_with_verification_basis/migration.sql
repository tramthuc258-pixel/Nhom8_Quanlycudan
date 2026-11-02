ALTER TABLE "residence_verification_requests"
DROP COLUMN "reference_code",
ADD COLUMN "verification_basis" VARCHAR(100);
