# Homie

Homie là hệ thống quản lý chung cư gồm một ứng dụng Flutter dùng chung và một
NestJS API. Dữ liệu được lưu trong PostgreSQL trên Supabase; Firebase Cloud
Messaging dùng để gửi thông báo đẩy đến Android.

## Luồng tài khoản

- Màn hình đầu tiên có hai tab **Cư dân** và **Quản lý & nhân viên**.
- Khách không cần tài khoản vẫn có thể xem căn hộ đang bán/cho thuê và gửi
  thông tin liên hệ cho ban quản lý.
- Cư dân đăng ký bằng email, xác minh OTP rồi chờ ban quản lý liên kết đúng căn
  hộ và tư cách chủ sở hữu/người thuê.
- Quản trị viên toàn quyền tạo tài khoản nhân viên, chọn vai trò và các tòa phụ
  trách. Mật khẩu tạm được gửi qua email; nhân viên bắt buộc đổi mật khẩu ngay
  lần đăng nhập đầu tiên.
- Quản trị viên có thể sửa vai trò, phân công thêm tòa, kết thúc phân công,
  khóa/mở tài khoản và cấp lại mật khẩu nhân viên.
- Hệ thống không dùng đăng nhập Google. Firebase trong project chỉ phục vụ
  thông báo đẩy.

## Phân quyền chính

| Vai trò | Phạm vi chính |
| --- | --- |
| `ADMIN` | Toàn hệ thống, tài khoản nhân viên và phân quyền |
| `MANAGEMENT` | Nghiệp vụ vận hành tại các tòa được phân công |
| `ACCOUNTANT` | Hóa đơn, công nợ và thanh toán tại tòa phụ trách |
| `RECEPTIONIST` | Tiếp nhận dịch vụ, tiện ích, khách lưu trú và yêu cầu kỹ thuật |
| `SECURITY` | Khách lưu trú và sự cố an ninh |
| `TECHNICIAN` | Yêu cầu bảo trì và các dịch vụ kỹ thuật được phân công |
| `RESIDENT` | Dữ liệu và dịch vụ thuộc căn hộ được liên kết |

Mọi nghiệp vụ nhân viên đều được giới hạn theo `StaffBuildingAssignment`, nên
yêu cầu của cư dân tòa A không xuất hiện cho nhân viên chỉ phụ trách tòa B.

## Chạy project

Các lệnh dưới đây bắt đầu từ thư mục chứa project `homie`. Mỗi người tải
source cần tạo `api/.env` riêng; file này không được đưa lên Git.

Terminal 1 – API:

```powershell
cd homie\api
Copy-Item .env.example .env
# Điền thông tin Supabase, JWT, SMTP và Firebase của bạn vào .env.
npm ci
npx prisma generate --config prisma7.config.ts
npx prisma migrate deploy --config prisma7.config.ts
npm run start:dev
```

Terminal 2 – Flutter (Android Emulator):

```powershell
cd homie
flutter pub get
flutter run -d emulator-5554
```

Flutter Web:

```powershell
flutter run -d chrome --web-port 8080
```

Chỉ dùng `lib/main.dart` làm entrypoint. Sau khi đăng nhập, ứng dụng tự điều
hướng theo vai trò; không cần chạy hai file cư dân/quản trị riêng.

## Swagger và cơ sở dữ liệu

- Swagger: `http://localhost:3000/docs`
- OpenAPI JSON: `http://localhost:3000/docs/openapi.json`
- Prisma schema: `api/prisma/schema.prisma`
- Migration: `api/prisma/migrations/`
- Seed: `api/prisma/seed.ts`

Để thử API có ổ khóa, gọi `POST /api/auth/login`, sao chép `accessToken`, bấm
**Authorize** trên Swagger và nhập token.

Các lệnh Prisma chạy trong thư mục `api`:

```powershell
npx prisma validate --config prisma7.config.ts
npx prisma migrate deploy --config prisma7.config.ts
npm run db:seed
```

Không đưa `api/.env`, Firebase service-account JSON hoặc mật khẩu thật vào git.

## Kiểm tra chất lượng

```powershell
# Flutter
flutter analyze
flutter test

# API
cd api
npm run build
npm test -- --runInBand
npm run test:e2e -- --runInBand
```

## Chức năng đã có

- Đăng ký/xác minh email, đăng nhập, quên/đổi mật khẩu và hồ sơ cá nhân.
- Lưu JWT trong kho bảo mật và tự khôi phục phiên hợp lệ khi mở lại ứng dụng.
- Cư dân, căn hộ, chủ sở hữu, người thuê, thành viên hộ và xác minh cư trú.
- Phân công nhân viên theo tòa và vai trò.
- Thông báo, hóa đơn, bảo trì, dịch vụ cư dân, tiện ích và đặt lịch.
- Khách lưu trú, sự cố an ninh, mua bán/cho thuê và yêu cầu của khách.
- Dashboard/báo cáo, trung tâm thông báo nội bộ và Firebase push notification.
- Chạm thông báo đẩy sẽ mở đúng phân hệ; hóa đơn và yêu cầu sửa chữa của cư
  dân được mở thẳng theo mã bản ghi.
- Cư dân tải ảnh/PDF biên lai và ảnh hiện trường lên Supabase Storage; tệp
  được đặt trong bucket riêng tư và phát qua đường dẫn ký có thời hạn; ảnh hiện
  trường hiển thị cho cả cư dân và nhân viên xử lý.
- Tin bán/cho thuê hỗ trợ tối đa 5 ảnh căn hộ; khách, cư dân và ban quản lý xem
  cùng một thư viện ảnh đã được duyệt.
- Kế toán xem/phóng to biên lai trước khi xác nhận thanh toán; kỹ thuật viên
  truy cập được yêu cầu bảo trì và dịch vụ kỹ thuật được phân công.
- Cư dân có thể chọn thanh toán trực tuyến qua VNPAY Sandbox; backend ký và
  xác minh HMAC-SHA512, nhận Return/IPN rồi tự động cập nhật hóa đơn thành đã
  thanh toán. Chuyển khoản kèm biên lai vẫn được giữ làm phương án đối soát.
- Nhật ký audit tự động cho thao tác của nhân viên; chỉ quản trị viên được tra
  cứu, dữ liệu mật khẩu/OTP/token được che trước khi lưu.
- API có giới hạn tần suất, HTTP security headers, CORS theo môi trường và
  health check cơ sở dữ liệu tại `GET /api/health`.

## Hạng mục cần nhà cung cấp bên ngoài

- VNPAY Sandbox dùng mã merchant thử nghiệm để kiểm tra luồng thanh toán trực
  tuyến; chưa đại diện cho thanh toán tiền thật. Chuyển khoản kèm biên lai và
  kế toán xác nhận vẫn là phương thức đối soát riêng.
