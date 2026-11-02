import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/services/service_mock_data_source.dart';
import 'package:homie/features/resident_services/services/service_repository_impl.dart';
import 'package:homie/features/resident_services/controllers/service_controller.dart';

void main() {
  final now = DateTime(2026, 10, 16, 9);
  late ServiceController controller;

  setUp(() {
    controller = ServiceController(
      repository: ServiceRepositoryImpl(
        ServiceMockDataSource(referenceTime: now),
      ),
    );
  });

  tearDown(() => controller.dispose());

  test('tải danh mục và đăng ký dịch vụ của cư dân A-1205', () async {
    await controller.load();

    expect(controller.services, hasLength(6));
    expect(controller.activeServices, hasLength(5));
    expect(controller.bookingsForResident('resident-001'), hasLength(3));
    expect(controller.activeBookingCountForResident('resident-001'), 2);
  });

  test('cư dân tạo đăng ký hợp lệ và hệ thống tính đúng chi phí', () async {
    await controller.load();

    final success = await controller.createBooking(
      serviceId: 'service-003',
      apartmentId: 'apartment-001',
      residentId: 'resident-001',
      residentName: 'Nguyễn Minh Anh',
      quantity: 2,
      scheduledAt: DateTime(2026, 10, 17, 14),
      note: 'Vệ sinh hai máy lạnh trong phòng ngủ.',
    );

    expect(success, isTrue);
    final created = controller.bookings.firstWhere(
      (item) => item.code == 'DV-2026-2007',
    );
    expect(created.status, ServiceBookingStatus.pending);
    expect(created.totalAmount, 360000);
  });

  test('không đặt dịch vụ tạm ngừng hoặc lịch không ở tương lai', () async {
    await controller.load();

    final inactive = await controller.createBooking(
      serviceId: 'service-006',
      apartmentId: 'apartment-001',
      residentId: 'resident-001',
      residentName: 'Nguyễn Minh Anh',
      quantity: 1,
      scheduledAt: DateTime(2026, 10, 18, 9),
    );
    expect(inactive, isFalse);
    expect(controller.errorMessage, contains('tạm ngừng'));

    final tooSoon = await controller.createBooking(
      serviceId: 'service-001',
      apartmentId: 'apartment-001',
      residentId: 'resident-001',
      residentName: 'Nguyễn Minh Anh',
      quantity: 1,
      scheduledAt: DateTime(2026, 10, 16, 9),
    );
    expect(tooSoon, isFalse);
    expect(controller.errorMessage, contains('trong tương lai'));
  });

  test('nhân viên gửi kết quả và cư dân xác nhận hoàn tất', () async {
    await controller.load();

    expect(
      await controller.assignBooking(
        bookingId: 'service-booking-001',
        assigneeId: 'technician-001',
        assigneeName: 'Lê Hoàng Kỹ Thuật',
      ),
      isTrue,
    );
    expect(
      controller.bookingById('service-booking-001')?.status,
      ServiceBookingStatus.confirmed,
    );

    expect(
      await controller.updateBookingStatus(
        bookingId: 'service-booking-001',
        status: ServiceBookingStatus.inProgress,
        note: 'Nhân viên đã đến căn hộ.',
      ),
      isTrue,
    );
    expect(
      await controller.updateBookingStatus(
        bookingId: 'service-booking-001',
        status: ServiceBookingStatus.waitingResident,
        note: 'Đã hoàn tất vệ sinh và bàn giao căn hộ.',
      ),
      isTrue,
    );
    expect(
      controller.bookingById('service-booking-001')?.status,
      ServiceBookingStatus.waitingResident,
    );

    expect(
      await controller.respondToResult(
        bookingId: 'service-booking-001',
        confirmed: true,
      ),
      isTrue,
    );
    expect(
      controller.bookingById('service-booking-001')?.status,
      ServiceBookingStatus.completed,
    );

    expect(
      await controller.updateBookingStatus(
        bookingId: 'service-booking-001',
        status: ServiceBookingStatus.inProgress,
      ),
      isFalse,
    );
    expect(controller.errorMessage, contains('Không thể chuyển'));
  });

  test('cư dân có thể yêu cầu xử lý lại dịch vụ', () async {
    await controller.load();
    await controller.assignBooking(
      bookingId: 'service-booking-001',
      assigneeId: 'technician-001',
      assigneeName: 'Lê Hoàng Kỹ Thuật',
    );
    await controller.updateBookingStatus(
      bookingId: 'service-booking-001',
      status: ServiceBookingStatus.inProgress,
    );
    await controller.updateBookingStatus(
      bookingId: 'service-booking-001',
      status: ServiceBookingStatus.waitingResident,
      note: 'Đã hoàn tất vệ sinh và bàn giao căn hộ.',
    );

    expect(
      await controller.respondToResult(
        bookingId: 'service-booking-001',
        confirmed: false,
        note: 'Ban công vẫn chưa được vệ sinh.',
      ),
      isTrue,
    );
    expect(
      controller.bookingById('service-booking-001')?.status,
      ServiceBookingStatus.inProgress,
    );
  });

  test('cư dân chỉ hủy được đơn còn chờ xác nhận', () async {
    await controller.load();

    expect(await controller.cancelBooking('service-booking-001'), isTrue);
    expect(
      controller.bookingById('service-booking-001')?.status,
      ServiceBookingStatus.cancelled,
    );

    expect(await controller.cancelBooking('service-booking-003'), isFalse);
    expect(controller.errorMessage, contains('chưa xác nhận'));
  });

  test('dịch vụ tạm ẩn biến mất khỏi danh mục đang hoạt động', () async {
    await controller.load();

    final success = await controller.toggleServiceActive('service-001');
    expect(success, isTrue, reason: controller.errorMessage);
    expect(controller.serviceById('service-001')?.isActive, isFalse);
    expect(
      controller.activeServices.any((item) => item.id == 'service-001'),
      isFalse,
    );
  });
}
