UPDATE "invoices"
SET "code" = REPLACE("code", 'DEMO', 'INIT'),
    "note" = CASE WHEN "note" IS NULL THEN NULL ELSE REPLACE("note", 'demo', 'khởi tạo') END
WHERE "code" LIKE '%DEMO%' OR "note" ILIKE '%demo%';

UPDATE "maintenance_requests"
SET "code" = REPLACE("code", 'DEMO', 'INIT'),
    "description" = REPLACE("description", 'demo', 'khởi tạo')
WHERE "code" LIKE '%DEMO%' OR "description" ILIKE '%demo%';

UPDATE "service_requests"
SET "code" = REPLACE("code", 'DEMO', 'INIT'),
    "note" = CASE WHEN "note" IS NULL THEN NULL ELSE REPLACE("note", 'demo', 'khởi tạo') END,
    "management_note" = CASE WHEN "management_note" IS NULL THEN NULL ELSE REPLACE("management_note", 'demo', 'khởi tạo') END
WHERE "code" LIKE '%DEMO%' OR "note" ILIKE '%demo%' OR "management_note" ILIKE '%demo%';

UPDATE "amenity_bookings"
SET "code" = REPLACE("code", 'DEMO', 'INIT'),
    "note" = CASE WHEN "note" IS NULL THEN NULL ELSE REPLACE("note", 'demo', 'khởi tạo') END,
    "management_note" = CASE WHEN "management_note" IS NULL THEN NULL ELSE REPLACE("management_note", 'demo', 'khởi tạo') END
WHERE "code" LIKE '%DEMO%' OR "note" ILIKE '%demo%' OR "management_note" ILIKE '%demo%';

UPDATE "security_incidents"
SET "code" = REPLACE("code", 'DEMO', 'INIT'),
    "description" = REPLACE("description", 'demo', 'khởi tạo'),
    "resolution_note" = CASE WHEN "resolution_note" IS NULL THEN NULL ELSE REPLACE("resolution_note", 'demo', 'khởi tạo') END
WHERE "code" LIKE '%DEMO%' OR "description" ILIKE '%demo%' OR "resolution_note" ILIKE '%demo%';

UPDATE "payments"
SET "transaction_code" = CASE WHEN "transaction_code" IS NULL THEN NULL ELSE REPLACE("transaction_code", 'DEMO', 'INIT') END,
    "proof_url" = CASE WHEN "proof_url" IS NULL THEN NULL ELSE REPLACE("proof_url", 'demo', 'initial') END,
    "note" = CASE WHEN "note" IS NULL THEN NULL ELSE REPLACE("note", 'demo', 'khởi tạo') END
WHERE "transaction_code" LIKE '%DEMO%' OR "proof_url" ILIKE '%demo%' OR "note" ILIKE '%demo%';
