import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/amenities/services/amenity_mock_data_source.dart';
import 'package:homie/features/amenities/services/amenity_repository_impl.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/amenities/controllers/amenity_controller.dart';

void main() {
  late AmenityController controller;
  late DateTime now;

  setUp(() async {
    final today = DateTime.now();
    now = DateTime(today.year, today.month, today.day, 8);
    controller = AmenityController(
      repository: AmenityRepositoryImpl(AmenityMockDataSource(now: now)),
    );
    await controller.load();
  });

  tearDown(() => controller.dispose());

  test('cư dân đặt tiện ích hợp lệ và có thể hủy khi đang chờ duyệt', () async {
    final startAt = now.add(const Duration(days: 5, hours: 2));
    final created = await controller.createBooking(
      amenityId: 'amenity-pool',
      apartmentId: 'apartment-001',
      residentId: 'resident-001',
      residentName: 'Nguyễn Minh Anh',
      startAt: startAt,
      attendeeCount: 2,
      note: 'Đặt cho gia đình.',
    );

    expect(created, isTrue);
    final booking = controller
        .bookingsForResident('resident-001')
        .firstWhere((item) => item.startAt == startAt);
    expect(booking.status, AmenityBookingStatus.pending);

    expect(await controller.cancelBooking(booking.id), isTrue);
    expect(
      controller.bookings.firstWhere((item) => item.id == booking.id).status,
      AmenityBookingStatus.cancelled,
    );
  });

  test('không cho hai lượt đặt chồng thời gian trên cùng tiện ích', () async {
    final startAt = now.add(const Duration(days: 6, hours: 2));
    expect(
      await controller.createBooking(
        amenityId: 'amenity-badminton',
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        startAt: startAt,
        attendeeCount: 2,
      ),
      isTrue,
    );
    expect(
      await controller.createBooking(
        amenityId: 'amenity-badminton',
        apartmentId: 'apartment-002',
        residentId: 'resident-003',
        residentName: 'Phạm Quốc Bảo',
        startAt: startAt,
        attendeeCount: 2,
      ),
      isFalse,
    );
    expect(controller.errorMessage, contains('đã có lượt đặt'));
  });

  test('ban quản lý duyệt lượt đặt và khóa lịch để ngăn đăng ký mới', () async {
    final pending = controller.bookings.firstWhere(
      (item) => item.status == AmenityBookingStatus.pending,
    );
    expect(
      await controller.reviewBooking(
        bookingId: pending.id,
        approved: true,
        note: 'Lịch hợp lệ.',
      ),
      isTrue,
    );
    expect(
      controller.bookings.firstWhere((item) => item.id == pending.id).status,
      AmenityBookingStatus.approved,
    );

    final startAt = now.add(const Duration(days: 7, hours: 3));
    expect(
      await controller.blockTimeSlot(
        amenityId: 'amenity-pool',
        startAt: startAt,
        endAt: startAt.add(const Duration(hours: 1)),
        note: 'Bảo trì định kỳ.',
      ),
      isTrue,
    );
    expect(
      await controller.createBooking(
        amenityId: 'amenity-pool',
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        startAt: startAt,
        attendeeCount: 1,
      ),
      isFalse,
    );
  });
}
