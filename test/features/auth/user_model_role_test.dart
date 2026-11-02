import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/auth/models/user_model.dart';

void main() {
  test('API giữ nguyên vai trò nghiệp vụ của từng actor', () {
    const expected = <String, UserRole>{
      'RESIDENT': UserRole.resident,
      'MANAGEMENT': UserRole.manager,
      'ADMIN': UserRole.admin,
      'ACCOUNTANT': UserRole.accountant,
      'RECEPTIONIST': UserRole.receptionist,
      'SECURITY': UserRole.security,
      'TECHNICIAN': UserRole.technician,
    };

    for (final entry in expected.entries) {
      final user = UserModel.fromApiMap({
        'id': '11111111-1111-4111-8111-111111111111',
        'fullName': 'Người dùng kiểm thử',
        'email': 'test.user@homie.com',
        'roles': [entry.key],
      });
      expect(user.role, entry.value);
      expect(user.role.label, isNotEmpty);
    }
  });

  test('quyền giao diện bám theo nhiệm vụ của actor', () {
    expect(UserRole.accountant.canManageInvoices, isTrue);
    expect(UserRole.accountant.canManageApartments, isFalse);
    expect(UserRole.receptionist.canReviewTemporaryStays, isTrue);
    expect(UserRole.security.canManageTemporaryStays, isTrue);
    expect(UserRole.security.canReviewTemporaryStays, isFalse);
    expect(UserRole.technician.canManageMaintenance, isTrue);
  });
}
