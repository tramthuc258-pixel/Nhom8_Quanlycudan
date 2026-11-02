-- Lưu tên đội hoặc bộ phận được phân công khi chưa chọn một tài khoản kỹ thuật viên cụ thể.
ALTER TABLE "maintenance_requests"
ADD COLUMN "assigned_team_name" VARCHAR(150);
