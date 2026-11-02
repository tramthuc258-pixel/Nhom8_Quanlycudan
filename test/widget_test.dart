import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/app.dart';
import 'package:homie/dependencies.dart';

void main() {
  Future<void> pumpHomie(WidgetTester tester) async {
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

  testWidgets('hiển thị màn hình đăng nhập Homie', (tester) async {
    await pumpHomie(tester);

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('portal-resident-tab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('portal-staff-tab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('continue-as-guest')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('auth-email')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-password')), findsOneWidget);
  });

  testWidgets('chuyển tab quản lý sẽ ẩn đăng ký và chế độ khách', (
    tester,
  ) async {
    await pumpHomie(tester);

    await tester.tap(find.byKey(const ValueKey<String>('portal-staff-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập quản lý'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('toggle-auth-mode')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('continue-as-guest')),
      findsNothing,
    );
  });

  testWidgets('tài khoản quản lý đăng nhập nhầm tab cư dân sẽ bị từ chối', (
    tester,
  ) async {
    await pumpHomie(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'nam.management@homie.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      '12345678',
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.textContaining('chuyển sang tab Quản lý'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-email')), findsOneWidget);
  });

  testWidgets('đăng nhập cư dân và mở đúng dashboard', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    expect(find.text('Xin chào, Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Người thuê'), findsWidgets);
    expect(find.text('Căn đang sử dụng'), findsOneWidget);
    expect(find.text('A-1205'), findsWidgets);

    await tester.ensureVisible(find.text('Xem căn hộ'));
    await tester.tap(find.text('Xem căn hộ'));
    await tester.pumpAndSettle();

    expect(find.text('Căn hộ của tôi'), findsOneWidget);
    expect(find.text('Quan hệ cư trú của bạn'), findsOneWidget);
    expect(find.text('Chủ sở hữu căn hộ'), findsOneWidget);
    expect(find.text('an.owner@homie.com'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);
  });

  testWidgets('dashboard cư dân hiển thị dữ liệu tổng hợp từ các phân hệ', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    expect(find.text('Công nợ hiện tại'), findsOneWidget);
    expect(find.text('Dịch vụ đang xử lý'), findsOneWidget);
    expect(find.text('Lịch tiện ích sắp tới'), findsOneWidget);

    final announcement = find.text('Tạm ngưng cấp nước khẩn cấp tại tòa A');
    expect(announcement, findsWidgets);
    expect(find.text('Vòi nước bếp bị rò rỉ'), findsOneWidget);
  });

  testWidgets('đăng nhập ban quản lý và mở đúng dashboard', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'nam.management@homie.com');

    expect(find.text('Tổng quan vận hành'), findsOneWidget);
    expect(find.text('BẢNG ĐIỀU KHIỂN HOMIE'), findsOneWidget);

    final manageApartments = find.text('Quản lý căn hộ');
    await tester.ensureVisible(manageApartments);
    await tester.tap(manageApartments);
    await tester.pumpAndSettle();

    expect(find.text('Danh sách căn hộ'), findsOneWidget);
  });

  testWidgets('cư dân mở danh sách thông báo', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    final allAnnouncements = find.text('Xem tất cả');
    await tester.ensureVisible(allAnnouncements);
    await tester.tap(allAnnouncements);
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Tổng thông báo'), findsOneWidget);
    expect(find.text('Chưa đọc'), findsWidgets);
    expect(find.text('Đã ghim'), findsOneWidget);
  });

  testWidgets('ban quản lý mở trang quản lý thông báo', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'nam.management@homie.com');

    final createAnnouncement = find.text('Tạo thông báo');
    await tester.ensureVisible(createAnnouncement);
    await tester.tap(createAnnouncement);
    await tester.pumpAndSettle();

    expect(find.text('Quản lý thông báo'), findsOneWidget);
  });

  testWidgets('cư dân mở danh sách và chi tiết hóa đơn của căn hộ', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    final openInvoices = find.text('Xem chi tiết hóa đơn');
    await tester.ensureVisible(openInvoices);
    await tester.tap(openInvoices);
    await tester.pumpAndSettle();

    expect(find.text('Tổng công nợ hiện tại'), findsOneWidget);
    final invoiceCode = find.textContaining('HD-202610-A1205');
    await tester.scrollUntilVisible(invoiceCode, 300);
    expect(invoiceCode, findsOneWidget);

    await tester.ensureVisible(invoiceCode);
    await tester.tap(invoiceCode);
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết hóa đơn'), findsOneWidget);
    final payButton = find.text('Thanh toán hóa đơn');
    expect(payButton, findsOneWidget);
    await tester.ensureVisible(payButton);
    await tester.pumpAndSettle();
    await tester.tap(payButton);
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán trực tuyến qua VNPAY'), findsOneWidget);
    expect(find.text('Chuyển khoản thủ công'), findsOneWidget);
  });

  testWidgets('ban quản lý mở trang hóa đơn và công nợ', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'nam.management@homie.com');

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hóa đơn & công nợ'));
    await tester.pumpAndSettle();

    expect(find.text('Hóa đơn và công nợ'), findsOneWidget);
    expect(find.text('Tổng hóa đơn'), findsOneWidget);
    expect(find.text('Công nợ hiện tại'), findsOneWidget);
  });

  testWidgets('cư dân mở trang yêu cầu sửa chữa', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    final openMaintenance = find.text('Gửi phản ánh');
    await tester.ensureVisible(openMaintenance);
    await tester.tap(openMaintenance);
    await tester.pumpAndSettle();

    expect(find.text('Yêu cầu sửa chữa'), findsOneWidget);
    expect(find.text('Hỗ trợ căn A-1205'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('YC-2026-1001'), findsWidgets);
  });

  testWidgets('ban quản lý mở trang điều phối yêu cầu sửa chữa', (
    tester,
  ) async {
    await pumpHomie(tester);
    await loginAs(tester, 'nam.management@homie.com');

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yêu cầu sửa chữa'));
    await tester.pumpAndSettle();

    expect(find.text('Điều phối yêu cầu cư dân'), findsOneWidget);
    expect(find.text('Khẩn cấp'), findsWidgets);
    expect(find.text('Chưa phân công'), findsWidgets);
  });

  testWidgets('cư dân mở danh mục dịch vụ', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'anh.resident@homie.com');

    final openServices = find.text('Đặt dịch vụ cư dân');
    await tester.ensureVisible(openServices);
    await tester.tap(openServices);
    await tester.pumpAndSettle();

    expect(find.text('Dịch vụ cư dân'), findsOneWidget);
    expect(find.text('Danh mục dịch vụ'), findsOneWidget);
    expect(find.text('Vệ sinh căn hộ'), findsOneWidget);
  });

  testWidgets('ban quản lý mở trang quản lý dịch vụ', (tester) async {
    await pumpHomie(tester);
    await loginAs(tester, 'nam.management@homie.com');

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dịch vụ'));
    await tester.pumpAndSettle();

    expect(find.text('Dịch vụ cư dân'), findsOneWidget);
    expect(find.text('Chờ tiếp nhận'), findsOneWidget);
    expect(find.text('Dịch vụ đang mở'), findsOneWidget);
  });
}
