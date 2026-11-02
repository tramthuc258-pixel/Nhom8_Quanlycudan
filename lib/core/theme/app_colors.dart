import 'package:flutter/material.dart';

/// Bảng màu dùng chung của ứng dụng Homie.
///
/// Các feature nên dùng màu từ [Theme.of] trước. Những hằng số ở đây hữu ích
/// cho các thành phần mang ý nghĩa cố định như trạng thái thành công/cảnh báo.
abstract final class AppColors {
  // Bảng màu Homie: xanh dương rõ ràng, xanh ngọc cho trạng thái tích cực
  // và cam ấm làm điểm nhấn nhỏ. Nền xanh rất nhạt giúp giao diện sáng, sạch.
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF173B76);
  static const Color primaryLight = Color(0xFFEAF1FF);
  static const Color secondary = Color(0xFF149B91);
  static const Color secondaryLight = Color(0xFFE6F7F5);
  static const Color accent = Color(0xFFFFA45B);
  static const Color accentSoft = Color(0xFFFFF1E5);

  // Màu nhận diện theo phân hệ. Các màu đậm dùng cho icon/trạng thái, màu
  // `Soft` dùng làm nền để dashboard đa dạng nhưng vẫn giữ độ tương phản tốt.
  static const Color billing = Color(0xFF3568E8);
  static const Color billingSoft = Color(0xFFEAF0FF);
  static const Color maintenance = Color(0xFFEA7137);
  static const Color maintenanceSoft = Color(0xFFFFEEE5);
  static const Color service = Color(0xFF0E9270);
  static const Color serviceSoft = Color(0xFFE3F7F0);
  static const Color amenity = Color(0xFF7657D6);
  static const Color amenitySoft = Color(0xFFF0EBFF);
  static const Color community = Color(0xFFC9508D);
  static const Color communitySoft = Color(0xFFFFEAF4);
  static const Color security = Color(0xFFD4485C);
  static const Color securitySoft = Color(0xFFFFE9ED);

  static const Color background = Color(0xFFF5F8FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F6FC);
  static const Color border = Color(0xFFDDE6F2);
  static const Color divider = Color(0xFFE8EEF7);

  static const Color textPrimary = Color(0xFF1C2942);
  static const Color textSecondary = Color(0xFF6C7890);
  static const Color textDisabled = Color(0xFFA1ADBF);

  static const Color success = Color(0xFF15803D);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoContainer = Color(0xFFDBEAFE);

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceMuted = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
}
