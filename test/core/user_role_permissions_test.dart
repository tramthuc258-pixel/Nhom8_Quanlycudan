import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/enums/user_role.dart';

void main() {
  group('ma trận quyền nhân viên', () {
    test('kế toán chỉ mở nhóm nghiệp vụ hóa đơn', () {
      expect(UserRole.accountant.canViewInvoices, isTrue);
      expect(UserRole.accountant.canManageInvoices, isTrue);
      expect(UserRole.accountant.canManageMaintenance, isFalse);
      expect(UserRole.accountant.canManageHousing, isFalse);
    });

    test('ban quản lý chỉ giám sát hóa đơn, không thao tác kế toán', () {
      expect(UserRole.manager.canViewInvoices, isTrue);
      expect(UserRole.manager.canManageInvoices, isFalse);
    });

    test('lễ tân tiếp nhận vận hành nhưng không quản lý nhân sự', () {
      expect(UserRole.receptionist.canManageServices, isTrue);
      expect(UserRole.receptionist.canManageAmenities, isTrue);
      expect(UserRole.receptionist.canManageTemporaryStays, isTrue);
      expect(UserRole.receptionist.canManageStaffAssignments, isFalse);
    });

    test('kỹ thuật viên thấy bảo trì và dịch vụ kỹ thuật', () {
      expect(UserRole.technician.canManageMaintenance, isTrue);
      expect(UserRole.technician.canManageServices, isTrue);
      expect(UserRole.technician.canManageInvoices, isFalse);
    });

    test('bảo vệ chỉ mở nghiệp vụ lưu trú và an ninh', () {
      expect(UserRole.security.canManageTemporaryStays, isTrue);
      expect(UserRole.security.canManageSecurityIncidents, isTrue);
      expect(UserRole.security.canManageInvoices, isFalse);
      expect(UserRole.security.canManageServices, isFalse);
    });

    test('chỉ quản trị viên quản lý tài khoản nhân viên', () {
      expect(UserRole.admin.canManageStaffAssignments, isTrue);
      expect(UserRole.manager.canManageStaffAssignments, isFalse);
    });
  });
}
