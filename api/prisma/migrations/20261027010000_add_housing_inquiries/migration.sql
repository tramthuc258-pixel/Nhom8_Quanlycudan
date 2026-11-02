CREATE TYPE "HousingInquiryStatus" AS ENUM ('NEW', 'CONTACTED', 'CLOSED');

CREATE TABLE "housing_inquiries" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" VARCHAR(30) NOT NULL,
    "listing_id" UUID NOT NULL,
    "full_name" VARCHAR(150) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "email" VARCHAR(255),
    "message" TEXT,
    "status" "HousingInquiryStatus" NOT NULL DEFAULT 'NEW',
    "handled_by_id" UUID,
    "handled_at" TIMESTAMPTZ(6),
    "staff_note" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "housing_inquiries_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "housing_inquiries_code_key" ON "housing_inquiries"("code");
CREATE INDEX "housing_inquiries_listing_id_status_idx" ON "housing_inquiries"("listing_id", "status");
CREATE INDEX "housing_inquiries_status_created_at_idx" ON "housing_inquiries"("status", "created_at");
CREATE INDEX "housing_inquiries_phone_idx" ON "housing_inquiries"("phone");

ALTER TABLE "housing_inquiries"
ADD CONSTRAINT "housing_inquiries_listing_id_fkey"
FOREIGN KEY ("listing_id") REFERENCES "housing_listings"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "housing_inquiries"
ADD CONSTRAINT "housing_inquiries_handled_by_id_fkey"
FOREIGN KEY ("handled_by_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
