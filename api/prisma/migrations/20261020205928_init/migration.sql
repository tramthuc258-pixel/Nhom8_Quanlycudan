-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'LOCKED');

-- CreateEnum
CREATE TYPE "RoleCode" AS ENUM ('RESIDENT', 'MANAGEMENT', 'ADMIN', 'ACCOUNTANT', 'RECEPTIONIST', 'SECURITY', 'TECHNICIAN');

-- CreateEnum
CREATE TYPE "ApartmentStatus" AS ENUM ('OCCUPIED', 'VACANT', 'UNDER_MAINTENANCE');

-- CreateEnum
CREATE TYPE "MembershipType" AS ENUM ('OWNER', 'TENANT', 'MEMBER');

-- CreateEnum
CREATE TYPE "MembershipStatus" AS ENUM ('ACTIVE', 'ENDED');

-- CreateEnum
CREATE TYPE "HousingTransactionType" AS ENUM ('RENT', 'PURCHASE');

-- CreateEnum
CREATE TYPE "HousingListingStatus" AS ENUM ('PENDING_APPROVAL', 'AVAILABLE', 'REJECTED', 'CLOSED');

-- CreateEnum
CREATE TYPE "HousingApplicationStatus" AS ENUM ('PENDING', 'COMPLETED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "HousingContractStatus" AS ENUM ('SIGNED', 'ACTIVE', 'ENDED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "TemporaryStayStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "SecurityIncidentType" AS ENUM ('NOISE', 'DISORDER', 'SUSPICIOUS_PERSON', 'PROPERTY_DAMAGE', 'FIRE_SAFETY', 'DISPUTE', 'LOST_AND_FOUND', 'OTHER');

-- CreateEnum
CREATE TYPE "SecurityIncidentStatus" AS ENUM ('REPORTED', 'REVIEWING', 'RESOLVED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "FeeCalculationType" AS ENUM ('FIXED', 'BY_AREA', 'BY_QUANTITY');

-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('DRAFT', 'UNPAID', 'PAID', 'CANCELLED', 'OVERDUE');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'BANK_TRANSFER', 'OTHER');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "MaintenanceCategory" AS ENUM ('ELECTRICAL', 'PLUMBING', 'ELEVATOR', 'COMMON_AREA', 'SECURITY', 'OTHER');

-- CreateEnum
CREATE TYPE "MaintenancePriority" AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');

-- CreateEnum
CREATE TYPE "MaintenanceStatus" AS ENUM ('SUBMITTED', 'RECEIVED', 'IN_PROGRESS', 'WAITING_RESIDENT', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ServiceCategory" AS ENUM ('CLEANING', 'LAUNDRY', 'TECHNICAL', 'TRANSPORTATION', 'CONVENIENCE');

-- CreateEnum
CREATE TYPE "ServiceRequestStatus" AS ENUM ('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "AmenityCategory" AS ENUM ('POOL', 'GYM', 'COMMUNITY_ROOM', 'SPORT', 'BARBECUE');

-- CreateEnum
CREATE TYPE "AmenityBookingStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "AnnouncementCategory" AS ENUM ('GENERAL', 'MAINTENANCE', 'BILLING', 'EVENT', 'EMERGENCY');

-- CreateEnum
CREATE TYPE "AnnouncementPriority" AS ENUM ('NORMAL', 'IMPORTANT', 'URGENT');

-- CreateEnum
CREATE TYPE "AnnouncementAudience" AS ENUM ('ALL', 'RESIDENTS', 'MANAGERS');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('INVOICE', 'MAINTENANCE', 'HOUSING', 'AMENITY', 'SERVICE', 'SYSTEM');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "full_name" VARCHAR(150) NOT NULL,
    "phone" VARCHAR(20),
    "date_of_birth" DATE,
    "contact_address" VARCHAR(500),
    "avatar_url" TEXT,
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" UUID NOT NULL,
    "code" "RoleCode" NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "description" VARCHAR(500),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_roles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "assigned_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "buildings" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "address" VARCHAR(500) NOT NULL,
    "floors" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "buildings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "apartments" (
    "id" UUID NOT NULL,
    "building_id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "floor" INTEGER NOT NULL,
    "area" DECIMAL(10,2) NOT NULL,
    "bedrooms" INTEGER NOT NULL,
    "status" "ApartmentStatus" NOT NULL DEFAULT 'VACANT',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "apartments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "apartment_memberships" (
    "id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" "MembershipType" NOT NULL,
    "status" "MembershipStatus" NOT NULL DEFAULT 'ACTIVE',
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "start_date" DATE NOT NULL,
    "end_date" DATE,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "apartment_memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "housing_listings" (
    "id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "submitted_by_id" UUID NOT NULL,
    "reviewed_by_id" UUID,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "transaction_type" "HousingTransactionType" NOT NULL,
    "price" DECIMAL(15,2) NOT NULL,
    "deposit" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "available_from" DATE NOT NULL,
    "image_urls" JSONB,
    "owner_submitted" BOOLEAN NOT NULL DEFAULT false,
    "status" "HousingListingStatus" NOT NULL DEFAULT 'PENDING_APPROVAL',
    "review_note" TEXT,
    "reviewed_at" TIMESTAMPTZ(6),
    "closed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "housing_listings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "housing_applications" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "listing_id" UUID NOT NULL,
    "applicant_id" UUID NOT NULL,
    "preferred_start_date" DATE NOT NULL,
    "preferred_end_date" DATE,
    "note" TEXT,
    "status" "HousingApplicationStatus" NOT NULL DEFAULT 'PENDING',
    "reviewed_by_id" UUID,
    "reviewed_at" TIMESTAMPTZ(6),
    "review_note" TEXT,
    "submitted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "housing_applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "housing_contracts" (
    "id" UUID NOT NULL,
    "contract_number" VARCHAR(50) NOT NULL,
    "application_id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "recorded_by_id" UUID NOT NULL,
    "transaction_type" "HousingTransactionType" NOT NULL,
    "agreed_price" DECIMAL(15,2) NOT NULL,
    "deposit" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "signed_at" DATE NOT NULL,
    "effective_start_date" DATE NOT NULL,
    "effective_end_date" DATE,
    "status" "HousingContractStatus" NOT NULL DEFAULT 'SIGNED',
    "note" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "housing_contracts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "temporary_stays" (
    "id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "declared_by_id" UUID NOT NULL,
    "reviewed_by_id" UUID,
    "guest_full_name" VARCHAR(150) NOT NULL,
    "guest_date_of_birth" DATE,
    "guest_phone" VARCHAR(20),
    "relationship_to_resident" VARCHAR(100),
    "start_date" DATE NOT NULL,
    "end_date" DATE NOT NULL,
    "purpose" VARCHAR(500),
    "status" "TemporaryStayStatus" NOT NULL DEFAULT 'PENDING',
    "review_note" TEXT,
    "reviewed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "temporary_stays_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "security_incidents" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "building_id" UUID NOT NULL,
    "apartment_id" UUID,
    "reported_by_id" UUID NOT NULL,
    "resolved_by_id" UUID,
    "type" "SecurityIncidentType" NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "location" VARCHAR(255),
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "status" "SecurityIncidentStatus" NOT NULL DEFAULT 'REPORTED',
    "resolution_note" TEXT,
    "resolved_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "security_incidents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fee_types" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" VARCHAR(500),
    "calculation_type" "FeeCalculationType" NOT NULL,
    "default_unit_price" DECIMAL(15,2) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "fee_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "apartment_id" UUID NOT NULL,
    "payer_id" UUID NOT NULL,
    "billing_month" DATE NOT NULL,
    "issued_at" TIMESTAMPTZ(6) NOT NULL,
    "due_date" DATE NOT NULL,
    "status" "InvoiceStatus" NOT NULL DEFAULT 'DRAFT',
    "total_amount" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "note" TEXT,
    "paid_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoice_items" (
    "id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "fee_type_id" UUID,
    "name" VARCHAR(150) NOT NULL,
    "quantity" DECIMAL(12,2) NOT NULL DEFAULT 1,
    "unit_price" DECIMAL(15,2) NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "recorded_by_id" UUID NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "transaction_code" VARCHAR(100),
    "proof_url" TEXT,
    "note" TEXT,
    "paid_at" TIMESTAMPTZ(6) NOT NULL,
    "confirmed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maintenance_requests" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "apartment_id" UUID NOT NULL,
    "requested_by_id" UUID NOT NULL,
    "created_by_id" UUID,
    "assigned_technician_id" UUID,
    "assigned_by_id" UUID,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "location" VARCHAR(255),
    "category" "MaintenanceCategory" NOT NULL,
    "priority" "MaintenancePriority" NOT NULL DEFAULT 'NORMAL',
    "status" "MaintenanceStatus" NOT NULL DEFAULT 'SUBMITTED',
    "image_urls" JSONB,
    "assigned_at" TIMESTAMPTZ(6),
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "maintenance_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maintenance_updates" (
    "id" UUID NOT NULL,
    "maintenance_request_id" UUID NOT NULL,
    "actor_id" UUID NOT NULL,
    "status" "MaintenanceStatus" NOT NULL,
    "note" TEXT,
    "image_urls" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "maintenance_updates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "services" (
    "id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" TEXT,
    "category" "ServiceCategory" NOT NULL,
    "unit_label" VARCHAR(50) NOT NULL,
    "unit_price" DECIMAL(15,2) NOT NULL,
    "estimated_duration_minutes" INTEGER,
    "provider_name" VARCHAR(150),
    "contact_phone" VARCHAR(20),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_requests" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "service_id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "requested_by_id" UUID NOT NULL,
    "created_by_id" UUID,
    "assigned_to_id" UUID,
    "quantity" DECIMAL(12,2) NOT NULL DEFAULT 1,
    "unit_price" DECIMAL(15,2) NOT NULL,
    "scheduled_at" TIMESTAMPTZ(6) NOT NULL,
    "note" TEXT,
    "status" "ServiceRequestStatus" NOT NULL DEFAULT 'PENDING',
    "management_note" TEXT,
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "service_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "amenities" (
    "id" UUID NOT NULL,
    "building_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" TEXT,
    "category" "AmenityCategory" NOT NULL,
    "capacity" INTEGER NOT NULL,
    "slot_duration_minutes" INTEGER NOT NULL,
    "opening_hour" INTEGER NOT NULL,
    "closing_hour" INTEGER NOT NULL,
    "fee" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "amenities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "amenity_bookings" (
    "id" UUID NOT NULL,
    "code" VARCHAR(30) NOT NULL,
    "amenity_id" UUID NOT NULL,
    "apartment_id" UUID NOT NULL,
    "resident_id" UUID NOT NULL,
    "reviewed_by_id" UUID,
    "start_at" TIMESTAMPTZ(6) NOT NULL,
    "end_at" TIMESTAMPTZ(6) NOT NULL,
    "attendee_count" INTEGER NOT NULL,
    "note" TEXT,
    "status" "AmenityBookingStatus" NOT NULL DEFAULT 'PENDING',
    "management_note" TEXT,
    "reviewed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "amenity_bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "announcements" (
    "id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "content" TEXT NOT NULL,
    "category" "AnnouncementCategory" NOT NULL DEFAULT 'GENERAL',
    "priority" "AnnouncementPriority" NOT NULL DEFAULT 'NORMAL',
    "audience" "AnnouncementAudience" NOT NULL DEFAULT 'ALL',
    "published_at" TIMESTAMPTZ(6),
    "expires_at" TIMESTAMPTZ(6),
    "is_pinned" BOOLEAN NOT NULL DEFAULT false,
    "is_published" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "announcements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "message" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "reference_type" VARCHAR(50),
    "reference_id" UUID,
    "read_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_status_idx" ON "users"("status");

-- CreateIndex
CREATE UNIQUE INDEX "roles_code_key" ON "roles"("code");

-- CreateIndex
CREATE INDEX "user_roles_role_id_idx" ON "user_roles"("role_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_roles_user_id_role_id_key" ON "user_roles"("user_id", "role_id");

-- CreateIndex
CREATE UNIQUE INDEX "buildings_code_key" ON "buildings"("code");

-- CreateIndex
CREATE INDEX "apartments_status_idx" ON "apartments"("status");

-- CreateIndex
CREATE UNIQUE INDEX "apartments_building_id_code_key" ON "apartments"("building_id", "code");

-- CreateIndex
CREATE INDEX "apartment_memberships_apartment_id_status_idx" ON "apartment_memberships"("apartment_id", "status");

-- CreateIndex
CREATE INDEX "apartment_memberships_user_id_status_idx" ON "apartment_memberships"("user_id", "status");

-- CreateIndex
CREATE INDEX "housing_listings_apartment_id_status_idx" ON "housing_listings"("apartment_id", "status");

-- CreateIndex
CREATE INDEX "housing_listings_transaction_type_status_idx" ON "housing_listings"("transaction_type", "status");

-- CreateIndex
CREATE INDEX "housing_listings_submitted_by_id_idx" ON "housing_listings"("submitted_by_id");

-- CreateIndex
CREATE UNIQUE INDEX "housing_applications_code_key" ON "housing_applications"("code");

-- CreateIndex
CREATE INDEX "housing_applications_listing_id_status_idx" ON "housing_applications"("listing_id", "status");

-- CreateIndex
CREATE INDEX "housing_applications_applicant_id_status_idx" ON "housing_applications"("applicant_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "housing_contracts_contract_number_key" ON "housing_contracts"("contract_number");

-- CreateIndex
CREATE UNIQUE INDEX "housing_contracts_application_id_key" ON "housing_contracts"("application_id");

-- CreateIndex
CREATE INDEX "housing_contracts_apartment_id_status_idx" ON "housing_contracts"("apartment_id", "status");

-- CreateIndex
CREATE INDEX "housing_contracts_owner_id_idx" ON "housing_contracts"("owner_id");

-- CreateIndex
CREATE INDEX "housing_contracts_customer_id_idx" ON "housing_contracts"("customer_id");

-- CreateIndex
CREATE INDEX "temporary_stays_apartment_id_start_date_end_date_idx" ON "temporary_stays"("apartment_id", "start_date", "end_date");

-- CreateIndex
CREATE INDEX "temporary_stays_status_idx" ON "temporary_stays"("status");

-- CreateIndex
CREATE UNIQUE INDEX "security_incidents_code_key" ON "security_incidents"("code");

-- CreateIndex
CREATE INDEX "security_incidents_building_id_status_idx" ON "security_incidents"("building_id", "status");

-- CreateIndex
CREATE INDEX "security_incidents_apartment_id_idx" ON "security_incidents"("apartment_id");

-- CreateIndex
CREATE INDEX "security_incidents_occurred_at_idx" ON "security_incidents"("occurred_at");

-- CreateIndex
CREATE UNIQUE INDEX "fee_types_code_key" ON "fee_types"("code");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_code_key" ON "invoices"("code");

-- CreateIndex
CREATE INDEX "invoices_payer_id_status_idx" ON "invoices"("payer_id", "status");

-- CreateIndex
CREATE INDEX "invoices_due_date_status_idx" ON "invoices"("due_date", "status");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_apartment_id_billing_month_key" ON "invoices"("apartment_id", "billing_month");

-- CreateIndex
CREATE INDEX "invoice_items_invoice_id_idx" ON "invoice_items"("invoice_id");

-- CreateIndex
CREATE INDEX "invoice_items_fee_type_id_idx" ON "invoice_items"("fee_type_id");

-- CreateIndex
CREATE INDEX "payments_invoice_id_status_idx" ON "payments"("invoice_id", "status");

-- CreateIndex
CREATE INDEX "payments_transaction_code_idx" ON "payments"("transaction_code");

-- CreateIndex
CREATE UNIQUE INDEX "maintenance_requests_code_key" ON "maintenance_requests"("code");

-- CreateIndex
CREATE INDEX "maintenance_requests_apartment_id_status_idx" ON "maintenance_requests"("apartment_id", "status");

-- CreateIndex
CREATE INDEX "maintenance_requests_requested_by_id_status_idx" ON "maintenance_requests"("requested_by_id", "status");

-- CreateIndex
CREATE INDEX "maintenance_requests_assigned_technician_id_status_idx" ON "maintenance_requests"("assigned_technician_id", "status");

-- CreateIndex
CREATE INDEX "maintenance_updates_maintenance_request_id_created_at_idx" ON "maintenance_updates"("maintenance_request_id", "created_at");

-- CreateIndex
CREATE INDEX "services_category_is_active_idx" ON "services"("category", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "service_requests_code_key" ON "service_requests"("code");

-- CreateIndex
CREATE INDEX "service_requests_service_id_status_idx" ON "service_requests"("service_id", "status");

-- CreateIndex
CREATE INDEX "service_requests_apartment_id_status_idx" ON "service_requests"("apartment_id", "status");

-- CreateIndex
CREATE INDEX "service_requests_requested_by_id_status_idx" ON "service_requests"("requested_by_id", "status");

-- CreateIndex
CREATE INDEX "service_requests_assigned_to_id_status_idx" ON "service_requests"("assigned_to_id", "status");

-- CreateIndex
CREATE INDEX "amenities_building_id_category_is_active_idx" ON "amenities"("building_id", "category", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "amenity_bookings_code_key" ON "amenity_bookings"("code");

-- CreateIndex
CREATE INDEX "amenity_bookings_amenity_id_start_at_end_at_idx" ON "amenity_bookings"("amenity_id", "start_at", "end_at");

-- CreateIndex
CREATE INDEX "amenity_bookings_resident_id_status_idx" ON "amenity_bookings"("resident_id", "status");

-- CreateIndex
CREATE INDEX "announcements_is_published_audience_published_at_idx" ON "announcements"("is_published", "audience", "published_at");

-- CreateIndex
CREATE INDEX "announcements_is_pinned_priority_idx" ON "announcements"("is_pinned", "priority");

-- CreateIndex
CREATE INDEX "notifications_user_id_read_at_created_at_idx" ON "notifications"("user_id", "read_at", "created_at");

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apartments" ADD CONSTRAINT "apartments_building_id_fkey" FOREIGN KEY ("building_id") REFERENCES "buildings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apartment_memberships" ADD CONSTRAINT "apartment_memberships_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apartment_memberships" ADD CONSTRAINT "apartment_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_listings" ADD CONSTRAINT "housing_listings_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_listings" ADD CONSTRAINT "housing_listings_submitted_by_id_fkey" FOREIGN KEY ("submitted_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_listings" ADD CONSTRAINT "housing_listings_reviewed_by_id_fkey" FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_applications" ADD CONSTRAINT "housing_applications_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "housing_listings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_applications" ADD CONSTRAINT "housing_applications_applicant_id_fkey" FOREIGN KEY ("applicant_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_applications" ADD CONSTRAINT "housing_applications_reviewed_by_id_fkey" FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_contracts" ADD CONSTRAINT "housing_contracts_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "housing_applications"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_contracts" ADD CONSTRAINT "housing_contracts_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_contracts" ADD CONSTRAINT "housing_contracts_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_contracts" ADD CONSTRAINT "housing_contracts_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "housing_contracts" ADD CONSTRAINT "housing_contracts_recorded_by_id_fkey" FOREIGN KEY ("recorded_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "temporary_stays" ADD CONSTRAINT "temporary_stays_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "temporary_stays" ADD CONSTRAINT "temporary_stays_declared_by_id_fkey" FOREIGN KEY ("declared_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "temporary_stays" ADD CONSTRAINT "temporary_stays_reviewed_by_id_fkey" FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "security_incidents" ADD CONSTRAINT "security_incidents_building_id_fkey" FOREIGN KEY ("building_id") REFERENCES "buildings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "security_incidents" ADD CONSTRAINT "security_incidents_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "security_incidents" ADD CONSTRAINT "security_incidents_reported_by_id_fkey" FOREIGN KEY ("reported_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "security_incidents" ADD CONSTRAINT "security_incidents_resolved_by_id_fkey" FOREIGN KEY ("resolved_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_payer_id_fkey" FOREIGN KEY ("payer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_fee_type_id_fkey" FOREIGN KEY ("fee_type_id") REFERENCES "fee_types"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_recorded_by_id_fkey" FOREIGN KEY ("recorded_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_requests" ADD CONSTRAINT "maintenance_requests_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_requests" ADD CONSTRAINT "maintenance_requests_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_requests" ADD CONSTRAINT "maintenance_requests_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_requests" ADD CONSTRAINT "maintenance_requests_assigned_technician_id_fkey" FOREIGN KEY ("assigned_technician_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_requests" ADD CONSTRAINT "maintenance_requests_assigned_by_id_fkey" FOREIGN KEY ("assigned_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_updates" ADD CONSTRAINT "maintenance_updates_maintenance_request_id_fkey" FOREIGN KEY ("maintenance_request_id") REFERENCES "maintenance_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_updates" ADD CONSTRAINT "maintenance_updates_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_assigned_to_id_fkey" FOREIGN KEY ("assigned_to_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amenities" ADD CONSTRAINT "amenities_building_id_fkey" FOREIGN KEY ("building_id") REFERENCES "buildings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amenity_bookings" ADD CONSTRAINT "amenity_bookings_amenity_id_fkey" FOREIGN KEY ("amenity_id") REFERENCES "amenities"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amenity_bookings" ADD CONSTRAINT "amenity_bookings_apartment_id_fkey" FOREIGN KEY ("apartment_id") REFERENCES "apartments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amenity_bookings" ADD CONSTRAINT "amenity_bookings_resident_id_fkey" FOREIGN KEY ("resident_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amenity_bookings" ADD CONSTRAINT "amenity_bookings_reviewed_by_id_fkey" FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "announcements" ADD CONSTRAINT "announcements_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
