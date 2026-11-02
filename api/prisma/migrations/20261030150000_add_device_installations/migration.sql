CREATE TYPE "DevicePlatform" AS ENUM ('ANDROID', 'IOS', 'WEB');

CREATE TABLE "device_installations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "firebase_token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "device_name" VARCHAR(150),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_seen_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "device_installations_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "device_installations_firebase_token_key"
ON "device_installations"("firebase_token");

CREATE INDEX "device_installations_user_id_is_active_idx"
ON "device_installations"("user_id", "is_active");

ALTER TABLE "device_installations"
ADD CONSTRAINT "device_installations_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
