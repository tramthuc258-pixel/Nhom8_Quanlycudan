import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/theme/app_theme.dart';
import 'package:homie/features/auth/controllers/auth_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/screens/login_page.dart';
import 'package:homie/features/auth/services/auth_mock_data_source.dart';
import 'package:homie/features/auth/services/auth_repository_impl.dart';
import 'package:homie/features/auth/services/login.dart';
import 'package:homie/features/auth/services/register.dart';

void main() {
  Future<void> pumpAuthAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final repository = AuthRepositoryImpl(
      AuthMockDataSource(responseDelay: Duration.zero),
    );
    final controller = AuthController(Login(repository), Register(repository));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginPage(controller: controller, onLoginSuccess: (User _) {}),
      ),
    );
    await tester.pump();
  }

  Future<void> expectBothAuthModesRender(WidgetTester tester) async {
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final toggle = find.byKey(const ValueKey<String>('toggle-auth-mode'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();

    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('đăng nhập và đăng ký hiển thị tốt trên mobile', (tester) async {
    await pumpAuthAtSize(tester, const Size(390, 844));
    await expectBothAuthModesRender(tester);
  });

  testWidgets('đăng nhập và đăng ký hiển thị tốt trên desktop', (tester) async {
    await pumpAuthAtSize(tester, const Size(1440, 900));
    await expectBothAuthModesRender(tester);
  });
}
