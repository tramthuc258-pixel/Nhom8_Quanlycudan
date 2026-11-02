import 'package:homie/features/auth/models/user.dart';

/// Các quy tắc truy cập màn hình theo phiên đăng nhập và vai trò.
abstract final class RouteGuard {
  static bool isAuthenticated(User? user) => user != null;

  static bool canOpenResidentArea(User user) => user.role.isResident;

  static bool canOpenManagementArea(User user) => user.role.isStaff;
}
