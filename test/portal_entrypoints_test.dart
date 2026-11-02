import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/apps/admin/admin_app.dart';
import 'package:homie/apps/resident/resident_app.dart';
import 'package:homie/dependencies.dart';

void main() {
  testWidgets('cổng cư dân mở đăng nhập trước và cho phép tiếp tục như khách', (
    tester,
  ) async {
    await tester.pumpWidget(
      ResidentPortalApp(
        dependencies: AppDependencies.create(useMockData: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('continue-as-guest')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('toggle-auth-mode')),
      findsOneWidget,
    );
    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-email')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('continue-as-guest')));
    await tester.pumpAndSettle();

    expect(find.text('Khám phá không gian sống tại Homie'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('resident-login-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('auth-email')), findsNothing);
  });

  testWidgets('cổng cư dân chuyển từ đăng nhập sang đăng ký và quay lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      ResidentPortalApp(
        dependencies: AppDependencies.create(useMockData: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('toggle-auth-mode')));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản mới'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('register-full-name')),
      findsOneWidget,
    );
    expect(find.text('Gửi mã xác minh email'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('toggle-auth-mode')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('toggle-auth-mode')));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });

  testWidgets('khách gửi yêu cầu liên hệ không cần tài khoản', (tester) async {
    await tester.pumpWidget(
      ResidentPortalApp(
        dependencies: AppDependencies.create(useMockData: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('continue-as-guest')));
    await tester.pumpAndSettle();

    final inquiryButton = find.text('Gửi yêu cầu').first;
    await tester.ensureVisible(inquiryButton);
    await tester.pumpAndSettle();
    await tester.tap(inquiryButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('guest-inquiry-full-name')),
      'Nguyễn Văn Khách',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('guest-inquiry-phone')),
      '0901234567',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('guest-inquiry-message')),
      'Tôi muốn xem căn hộ vào cuối tuần.',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('submit-guest-inquiry')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ban quản lý sẽ liên hệ'), findsOneWidget);
  });

  testWidgets('cổng quản trị mở thẳng đăng nhập nội bộ', (tester) async {
    await tester.pumpWidget(
      AdminPortalApp(dependencies: AppDependencies.create(useMockData: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cổng quản lý Homie'), findsOneWidget);
    expect(find.text('Đăng nhập quản lý'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-email')), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsNothing);
  });

  testWidgets('menu cư dân không tràn ở cửa sổ desktop thấp', (tester) async {
    tester.view.physicalSize = const Size(1365, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ResidentPortalApp(
        dependencies: AppDependencies.create(useMockData: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'anh.resident@homie.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      '12345678',
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
