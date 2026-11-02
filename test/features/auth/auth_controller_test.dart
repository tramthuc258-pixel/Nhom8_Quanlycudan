import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/auth/services/auth_mock_data_source.dart';
import 'package:homie/features/auth/services/auth_repository_impl.dart';
import 'package:homie/features/auth/services/login.dart';
import 'package:homie/features/auth/services/register.dart';
import 'package:homie/features/auth/controllers/auth_controller.dart';

void main() {
  late AuthController controller;
  late AuthRepositoryImpl repository;

  setUp(() {
    repository = AuthRepositoryImpl(
      AuthMockDataSource(responseDelay: Duration.zero),
    );
    controller = AuthController(
      Login(repository),
      Register(repository),
      repository,
    );
  });

  tearDown(() => controller.dispose());

  test('xác minh OTP mới tạo cư dân chưa có căn hộ và tự đăng nhập', () async {
    final otpResult = await controller.requestRegistrationOtp(
      fullName: '  Lê Thanh Bình  ',
      email: '  BINH@EXAMPLE.COM ',
      password: '12345678',
    );
    expect(otpResult?.developmentCode, '123456');
    expect(controller.isAuthenticated, isFalse);

    final user = await controller.verifyRegistrationOtp(
      email: 'binh@example.com',
      code: '123456',
    );

    expect(user, isNotNull);
    expect(user!.id, 'resident-100');
    expect(user.fullName, 'Lê Thanh Bình');
    expect(user.email, 'binh@example.com');
    expect(user.role, UserRole.resident);
    expect(user.apartmentCode, isNull);
    expect(controller.currentUser, user);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.errorMessage, isNull);

    controller.logout();
    final loggedIn = await controller.login(
      email: 'binh@example.com',
      password: '12345678',
    );
    expect(loggedIn, user);
  });

  test(
    'không cho đăng ký email đã tồn tại, không phân biệt hoa thường',
    () async {
      final result = await controller.requestRegistrationOtp(
        fullName: 'Người dùng mới',
        email: 'ANH.RESIDENT@HOMIE.COM',
        password: '12345678',
      );

      expect(result, isNull);
      expect(controller.currentUser, isNull);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, 'Email này đã được sử dụng.');
    },
  );

  test('gửi mã và đặt lại mật khẩu bằng mã xác nhận', () async {
    final result = await controller.requestPasswordReset(
      email: 'anh.resident@homie.com',
    );

    expect(result, isNotNull);
    expect(result!.developmentCode, '123456');
    expect(
      await controller.resetPassword(
        email: 'anh.resident@homie.com',
        code: '123456',
        newPassword: 'mat-khau-moi',
      ),
      isTrue,
    );

    final user = await controller.login(
      email: 'anh.resident@homie.com',
      password: 'mat-khau-moi',
    );
    expect(user, isNotNull);
  });
}
