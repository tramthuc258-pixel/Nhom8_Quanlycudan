CREATE TABLE "audit_logs" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "actor_id" UUID NOT NULL,
  "action" VARCHAR(20) NOT NULL,
  "resource" VARCHAR(100) NOT NULL,
  "target_id" VARCHAR(100),
  "path" VARCHAR(500) NOT NULL,
  "status_code" INTEGER NOT NULL,
  "metadata" JSONB,
  "ip_address" VARCHAR(64),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "audit_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "audit_logs_actor_id_created_at_idx" ON "audit_logs"("actor_id", "created_at");
CREATE INDEX "audit_logs_resource_created_at_idx" ON "audit_logs"("resource", "created_at");
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");
