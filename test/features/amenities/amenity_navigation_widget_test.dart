import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/app.dart';
import 'package:homie/dependencies.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      HomieApp(dependencies: AppDependencies.create(useMockData: true)),
    );
  }

  Future<void> loginAs(WidgetTester tester, String email) async {
    if (email == 'nam.management@homie.com') {
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

  testWidgets('cư dân mở trang tiện ích từ trang chủ', (tester) async {
    await pumpApp(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    final amenities = find.text('Tiện ích');
    await tester.ensureVisible(amenities);
    await tester.tap(amenities);
    await tester.pumpAndSettle();

    expect(find.text('Tiện ích chung'), findsOneWidget);
    expect(find.text('Hồ bơi tầng 1'), findsOneWidget);
  });

  testWidgets('ban quản lý mở trang điều phối tiện ích', (tester) async {
    await pumpApp(tester);
    await loginAs(tester, 'nam.management@homie.com');

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiện ích'));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý tiện ích'), findsOneWidget);
    expect(find.text('Điều phối tiện ích'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsWidgets);
  });
}
