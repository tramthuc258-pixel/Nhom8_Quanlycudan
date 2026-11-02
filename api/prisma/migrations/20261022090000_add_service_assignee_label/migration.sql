-- Lưu tên đơn vị hoặc đội được phân công khi chưa chọn một tài khoản nhân viên cụ thể.
ALTER TABLE "service_requests"
ADD COLUMN "assigned_to_name" VARCHAR(150);
