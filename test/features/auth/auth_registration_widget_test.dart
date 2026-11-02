import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/auth/services/auth_mock_data_source.dart';
import 'package:homie/features/auth/services/auth_repository_impl.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/services/login.dart';
import 'package:homie/features/auth/services/register.dart';
import 'package:homie/features/auth/controllers/auth_controller.dart';
import 'package:homie/features/auth/screens/login_page.dart';

void main() {
  testWidgets('người dùng chuyển sang đăng ký và tạo tài khoản thành công', (
    tester,
  ) async {
    final repository = AuthRepositoryImpl(
      AuthMockDataSource(responseDelay: Duration.zero),
    );
    final controller = AuthController(Login(repository), Register(repository));
    addTearDown(controller.dispose);
    User? registeredUser;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          controller: controller,
          onLoginSuccess: (user) => registeredUser = user,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('toggle-auth-mode')));
    await tester.pump();

    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('register-full-name')),
      'Lê Thanh Bình',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'binh@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      '12345678',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('register-confirm-password')),
      '12345678',
    );

    final submit = find.text('Gửi mã xác minh email');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('registration-development-code')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('register-otp-code')),
      '123456',
    );
    final verify = find.text('Xác minh và tạo tài khoản');
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(registeredUser?.email, 'binh@example.com');
    expect(registeredUser?.apartmentCode, isNull);
    expect(controller.isAuthenticated, isTrue);
  });
}
