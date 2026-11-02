-- Khung giờ do ban quản lý khóa không thuộc một căn hộ cụ thể.
ALTER TABLE "amenity_bookings"
ALTER COLUMN "apartment_id" DROP NOT NULL;
