# Homie API

NestJS REST API cho ứng dụng Homie. API dùng Prisma 7, PostgreSQL/Supabase,
JWT, SMTP và Firebase Admin SDK.

## Khởi động

Chạy các lệnh sau trong thư mục `api`. Mỗi máy cần có `.env` riêng.

```powershell
Copy-Item .env.example .env
# Điền cấu hình riêng vào .env trước khi chạy lệnh tiếp theo.
npm ci
npx prisma generate --config prisma7.config.ts
npx prisma migrate deploy --config prisma7.config.ts
npm run start:dev
```

API mặc định chạy tại `http://localhost:3000/api`; Swagger ở
`http://localhost:3000/docs`.

## Cấu hình

Sao chép `.env.example` thành `.env` rồi cấu hình:

- `DATABASE_URL`, `DIRECT_URL`: kết nối Supabase PostgreSQL.
- `JWT_SECRET`: khóa ký JWT.
- `CORS_ORIGINS`: các địa chỉ Flutter Web được phép gọi API, phân cách bằng
  dấu phẩy. Khi phát hành production phải cấu hình rõ, không mở toàn bộ origin.
- `SMTP_*`: gửi OTP, mã quên mật khẩu và thư mời nhân viên.
- `GOOGLE_APPLICATION_CREDENTIALS`: đường dẫn đến JSON dịch vụ Firebase; file
  này phải được giữ bí mật. Có thể cấu hình bằng `FIREBASE_PROJECT_ID`,
  `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` thay cho đường dẫn.
- `SUPABASE_URL`, `SUPABASE_SECRET_KEY`, `SUPABASE_STORAGE_BUCKET`: tải ảnh/PDF
  lên Supabase Storage. Secret key chỉ đặt ở API, tuyệt đối không đưa vào mã
  Flutter. `SUPABASE_SERVICE_ROLE_KEY` chỉ là phương án tương thích project cũ.
- `VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`: thông tin merchant VNPAY Sandbox.
  `VNPAY_RETURN_URL` mở trang kết quả cho người dùng. `VNPAY_IPN_URL` là địa chỉ
  cần đăng ký với VNPAY để máy chủ của họ xác nhận giao dịch; chỉ ghi vào `.env`
  không tự đăng ký địa chỉ này với VNPAY.
- `SEED_ADMIN_*`: tài khoản quản trị khởi tạo lần đầu.
- `SEED_INITIAL_ACCOUNT_PASSWORD`: chỉ dùng khi chủ động nạp bộ dữ liệu nghiệm
  thu; không phải cơ chế quản lý mật khẩu trong vận hành.
- `SHOWCASE_RESIDENT_EMAIL`: tùy chọn, chỉ dùng khi chạy script tạo dữ liệu
  minh họa cho một cư dân; không ghi email cá nhân trực tiếp vào source.

## Lệnh thường dùng

```powershell
npm run build
npm test -- --runInBand
npm run test:e2e -- --runInBand
npx prisma validate --config prisma7.config.ts
npx prisma migrate deploy --config prisma7.config.ts
npm run db:seed
```

## Thử VNPAY Sandbox trên máy local

Mở ba terminal tại thư mục `api`, rồi lần lượt chạy API, cổng callback giới
hạn đường dẫn và ngrok:

```powershell
npm run start:dev
```

```powershell
npm run vnpay:proxy
```

```powershell
ngrok http 3001
```

Đặt `VNPAY_RETURN_URL` thành `https://<ngrok-domain>/api/payments/vnpay/return`
và `VNPAY_IPN_URL` thành `https://<ngrok-domain>/api/payments/vnpay/ipn`.
Đăng ký URL IPN tương ứng trong cấu hình merchant VNPAY. Nếu ngrok đổi domain,
cập nhật cả hai URL rồi khởi động lại API. Cổng 3001 chỉ chuyển tiếp hai đường
callback VNPAY; các API khác trả về 404.

Mặc định Return chỉ hiển thị kết quả cho cư dân; IPN xác minh chữ ký và số tiền
rồi cập nhật giao dịch, hóa đơn và gửi thông báo. Riêng khi kiểm thử Sandbox,
có thể đặt `VNPAY_SANDBOX_RETURN_CONFIRMATION="true"` để Return đã ký hợp lệ
cũng xác nhận giao dịch nếu IPN chưa tới. Cờ này chỉ hoạt động với URL thanh
toán Sandbox và phải tắt khi chuyển sang merchant thật. Nếu cư dân đóng trình
duyệt trước khi Return mà IPN chưa được VNPAY cấu hình, hóa đơn vẫn chờ xác
nhận. Sau khi thanh toán trên trình duyệt, quay lại ứng dụng và làm mới hóa đơn.

## Cấu trúc

- `src/auth`: đăng ký, OTP, đăng nhập, JWT và mật khẩu.
- `src/storage`: upload ảnh/PDF vào bucket riêng tư và tạo URL ký có thời hạn.
- `src/invoices/vnpay.*`: tạo URL thanh toán, xác minh checksum Return/IPN và
  cập nhật giao dịch VNPAY.
- `src/staff-building-assignments`: tài khoản nhân viên và phạm vi tòa nhà.
- `src/building-access`: chính sách lọc dữ liệu theo tòa.
- Các module nghiệp vụ còn lại tương ứng với căn hộ, cư dân, hóa đơn, bảo trì,
  dịch vụ, tiện ích, cư trú, an ninh và thông báo.
- `prisma/schema.prisma`: mô hình dữ liệu nguồn.
- `prisma/migrations`: lịch sử thay đổi cấu trúc PostgreSQL.
- `prisma/seed.ts`: dữ liệu khởi tạo/nghiệm thu có tính lặp an toàn.

Không commit `.env`, service-account JSON, access token hoặc mật khẩu thật.
