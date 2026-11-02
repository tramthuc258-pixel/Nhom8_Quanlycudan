ALTER TABLE "users"
ADD COLUMN "google_subject" VARCHAR(255),
ADD COLUMN "password_reset_code_hash" VARCHAR(255),
ADD COLUMN "password_reset_expires_at" TIMESTAMPTZ(6);

CREATE UNIQUE INDEX "users_google_subject_key" ON "users"("google_subject");
