import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/app.dart';
import 'package:homie/dependencies.dart';
import 'package:homie/features/residents/models/membership_type.dart';

void main() {
  testWidgets('cư dân có hai căn chọn và đổi căn dùng chung', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final dependencies = AppDependencies.create(useMockData: true);
    final apartments = dependencies.apartmentMembershipController;
    await tester.runAsync(apartments.load);
    final owner = apartments.residents.singleWhere(
      (item) => item.email == 'trang.owner@homie.com',
    );
    final secondApartment = apartments.apartments.singleWhere(
      (item) => item.code == 'B-0803',
    );
    expect(
      await tester.runAsync(
        () => apartments.addMembership(
          residentId: owner.id,
          apartmentId: secondApartment.id,
          fullName: owner.fullName,
          phone: owner.phone,
          email: owner.email,
          type: MembershipType.owner,
          startDate: DateTime(2026, 10, 1),
        ),
      ),
      isTrue,
    );

    await tester.pumpWidget(HomieApp(dependencies: dependencies));
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      owner.email,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      '12345678',
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn căn hộ đang sử dụng'), findsOneWidget);
    await tester.tap(find.text('B-0803'));
    await tester.pumpAndSettle();
    expect(find.text('B-0803 · Tòa B'), findsOneWidget);

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('B-0803'), findsOneWidget);

    await tester.tap(find.text('Đổi căn hộ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D-0602'));
    await tester.pumpAndSettle();
    expect(find.text('D-0602'), findsOneWidget);
  });
}
