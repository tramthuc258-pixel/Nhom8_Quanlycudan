import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/app.dart';
import 'package:homie/dependencies.dart';
import 'package:homie/features/housing/widgets/housing_listing_widgets.dart';

void main() {
  Future<void> pumpHomie(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      HomieApp(dependencies: AppDependencies.create(useMockData: true)),
    );
  }

  Future<void> loginAs(WidgetTester tester, {required String role}) async {
    final email = switch (role) {
      'Ban quản lý' => 'nam.management@homie.com',
      'Chủ căn hộ' => 'trang.owner@homie.com',
      _ => 'anh.resident@homie.com',
    };
    if (role == 'Ban quản lý') {
      await tester.tap(find.byKey(const ValueKey<String>('portal-staff-tab')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      email,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      '12345678',
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
  }

  testWidgets('cư dân mở danh sách thuê mua từ lối tắt trang chủ', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, role: 'Cư dân');

    final housingShortcut = find.text('Thuê / mua căn hộ');
    await tester.ensureVisible(housingShortcut);
    await tester.tap(housingShortcut);
    await tester.pumpAndSettle();

    expect(find.text('Thuê và mua căn hộ'), findsOneWidget);
    expect(find.text('Tin của tôi (0)'), findsNothing);
    expect(
      find.text('Khám phá căn hộ đang cho thuê hoặc mở bán trong khu dân cư.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm căn hộ'),
      'A-1002',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(HousingListingCard),
        matching: find.text('A-1002'),
      ),
      findsOneWidget,
    );
    expect(find.text('Căn hộ 2 phòng ngủ, nội thất cơ bản'), findsOneWidget);
  });

  testWidgets('thanh điều hướng mobile dùng mục Tài khoản thay cho Nhà ở', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, role: 'Cư dân');

    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('Nhà ở'), findsNothing);

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản'), findsWidgets);
    expect(find.text('Giao diện'), findsNothing);
  });

  testWidgets('ban quản lý mở trang hồ sơ thuê mua và thấy hồ sơ chờ', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, role: 'Ban quản lý');

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ thuê/mua'));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý thuê và mua căn hộ'), findsOneWidget);
    expect(find.text('Tiếp nhận hồ sơ căn hộ'), findsOneWidget);
    expect(find.text('Chờ xét duyệt'), findsWidgets);

    final pendingApplication = find.text('HS-2026-1001');
    await tester.scrollUntilVisible(
      pendingApplication,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(pendingApplication, findsOneWidget);
    expect(find.text('Nguyễn Hoài Nam'), findsOneWidget);
  });

  testWidgets('người dùng mới chưa có căn hộ vẫn mở được trang thuê mua', (
    tester,
  ) async {
    await pumpHomie(tester);

    await tester.tap(find.byKey(const ValueKey<String>('toggle-auth-mode')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('register-full-name')),
      'Lê Thanh Bình',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'binh.housing@example.com',
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

    await tester.enterText(
      find.byKey(const ValueKey<String>('register-otp-code')),
      '123456',
    );
    final verify = find.text('Xác minh và tạo tài khoản');
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(find.text('Xin chào, Lê Thanh Bình'), findsOneWidget);
    expect(find.text('Tìm căn hộ'), findsOneWidget);

    await tester.tap(find.text('Tìm căn hộ'));
    await tester.pumpAndSettle();

    expect(find.text('Thuê và mua căn hộ'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm căn hộ'),
      'A-1002',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(HousingListingCard),
        matching: find.text('A-1002'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('chủ căn hộ thấy chức năng gửi bài đăng của mình', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, role: 'Chủ căn hộ');

    final assetShortcut = find.text('Thuê / mua căn hộ');
    await tester.ensureVisible(assetShortcut);
    await tester.tap(assetShortcut);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Đăng căn hộ của tôi'), findsOneWidget);
    expect(find.text('Quản lý và giao dịch căn hộ'), findsOneWidget);
    expect(find.text('Tin của tôi (0)'), findsOneWidget);
  });
}
