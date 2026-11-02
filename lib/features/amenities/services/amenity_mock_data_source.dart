import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/amenities/models/amenity_category.dart';

import '../models/amenity_booking_model.dart';
import '../models/amenity_model.dart';
import 'amenity_data_source.dart';

class AmenityMockDataSource implements AmenityDataSource {
  AmenityMockDataSource({DateTime? now})
    : _now = now ?? DateTime.now(),
      _amenities = _seedAmenities(),
      _bookings = <AmenityBookingModel>[] {
    _bookings.addAll(_seedBookings(_now));
  }

  final DateTime _now;
  final List<AmenityModel> _amenities;
  final List<AmenityBookingModel> _bookings;
  int _nextBookingNumber = 1004;

  @override
  Future<List<AmenityModel>> getAmenities() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<AmenityModel>.unmodifiable(_amenities);
  }

  @override
  Future<List<AmenityBookingModel>> getBookings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List<AmenityBookingModel>.unmodifiable(_bookings);
  }

  @override
  Future<AmenityBookingModel> createBooking({
    required String amenityId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required DateTime startAt,
    required int attendeeCount,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final amenity = _amenityById(amenityId);
    if (!amenity.isActive) {
      throw StateError('Tiện ích này hiện đang tạm ngưng.');
    }
    final endAt = startAt.add(Duration(minutes: amenity.slotDurationMinutes));
    _validateSlot(amenity, startAt, endAt, attendeeCount);
    _ensureNoOverlap(amenityId, startAt, endAt);
    final now = DateTime.now();
    final sequence = _nextBookingNumber++;
    final booking = AmenityBookingModel(
      id: 'amenity-booking-${now.microsecondsSinceEpoch}-$sequence',
      code: 'TI-${now.year}-${sequence.toString().padLeft(4, '0')}',
      amenityId: amenity.id,
      amenityName: amenity.name,
      apartmentId: apartmentId,
      residentId: residentId,
      residentName: residentName.trim(),
      startAt: startAt,
      endAt: endAt,
      attendeeCount: attendeeCount,
      note: note.trim(),
      status: AmenityBookingStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<AmenityBookingModel> cancelBooking(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 110));
    final index = _bookingIndex(bookingId);
    final booking = _bookings[index];
    if (!booking.status.canCancelByResident) {
      throw StateError('Chỉ có thể hủy lượt đặt đang chờ duyệt.');
    }
    return _replaceBooking(
      index,
      booking.copyWith(
        status: AmenityBookingStatus.cancelled,
        updatedAt: DateTime.now(),
        managementNote: 'Cư dân đã hủy lượt đặt.',
      ),
    );
  }

  @override
  Future<AmenityBookingModel> reviewBooking({
    required String bookingId,
    required bool approved,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _bookingIndex(bookingId);
    final booking = _bookings[index];
    if (booking.status != AmenityBookingStatus.pending) {
      throw StateError('Lượt đặt này đã được xử lý.');
    }
    if (!approved && note.trim().length < 5) {
      throw ArgumentError('Vui lòng nhập lý do từ chối ít nhất 5 ký tự.');
    }
    return _replaceBooking(
      index,
      booking.copyWith(
        status: approved
            ? AmenityBookingStatus.approved
            : AmenityBookingStatus.rejected,
        updatedAt: DateTime.now(),
        managementNote: note.trim().isEmpty
            ? 'Ban quản lý đã duyệt lượt đặt.'
            : note.trim(),
      ),
    );
  }

  @override
  Future<AmenityBookingModel> checkInBooking(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _bookingIndex(bookingId);
    final booking = _bookings[index];
    if (booking.status != AmenityBookingStatus.approved) {
      throw StateError('Chỉ có thể check-in lượt đặt đã được duyệt.');
    }
    final now = DateTime.now();
    if (now.isBefore(booking.startAt.subtract(const Duration(minutes: 30))) ||
        now.isAfter(booking.endAt)) {
      throw StateError('Chỉ có thể check-in từ 30 phút trước giờ bắt đầu.');
    }
    return _replaceBooking(
      index,
      booking.copyWith(
        status: AmenityBookingStatus.checkedIn,
        updatedAt: now,
        checkedInAt: now,
        processedByName: 'Lễ tân',
      ),
    );
  }

  @override
  Future<AmenityBookingModel> completeBooking(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _bookingIndex(bookingId);
    final booking = _bookings[index];
    if (booking.status != AmenityBookingStatus.checkedIn) {
      throw StateError('Lượt đặt phải được check-in trước khi hoàn tất.');
    }
    final now = DateTime.now();
    return _replaceBooking(
      index,
      booking.copyWith(
        status: AmenityBookingStatus.completed,
        updatedAt: now,
        completedAt: now,
        processedByName: 'Lễ tân',
      ),
    );
  }

  @override
  Future<AmenityBookingModel> markNoShow(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _bookingIndex(bookingId);
    final booking = _bookings[index];
    if (booking.status != AmenityBookingStatus.approved ||
        !DateTime.now().isAfter(booking.endAt)) {
      throw StateError('Chỉ ghi nhận không đến sau khi khung giờ đã kết thúc.');
    }
    return _replaceBooking(
      index,
      booking.copyWith(
        status: AmenityBookingStatus.noShow,
        updatedAt: DateTime.now(),
        processedByName: 'Lễ tân',
      ),
    );
  }

  @override
  Future<AmenityBookingModel> blockTimeSlot({
    required String amenityId,
    required DateTime startAt,
    required DateTime endAt,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final amenity = _amenityById(amenityId);
    if (!endAt.isAfter(startAt)) {
      throw ArgumentError('Khung giờ khóa không hợp lệ.');
    }
    _validateHours(amenity, startAt, endAt);
    _ensureNoOverlap(amenityId, startAt, endAt);
    final now = DateTime.now();
    final sequence = _nextBookingNumber++;
    final booking = AmenityBookingModel(
      id: 'amenity-block-${now.microsecondsSinceEpoch}-$sequence',
      code: 'KHOA-${now.year}-${sequence.toString().padLeft(4, '0')}',
      amenityId: amenity.id,
      amenityName: amenity.name,
      apartmentId: '',
      residentId: 'management',
      residentName: 'Ban quản lý',
      startAt: startAt,
      endAt: endAt,
      attendeeCount: 0,
      note: note.trim().isEmpty ? 'Khóa để bảo trì.' : note.trim(),
      status: AmenityBookingStatus.blocked,
      createdAt: now,
      updatedAt: now,
      managementNote: 'Khung giờ được ban quản lý khóa.',
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<AmenityModel> toggleAmenityActive(String amenityId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _amenities.indexWhere((item) => item.id == amenityId);
    if (index < 0) throw StateError('Không tìm thấy tiện ích.');
    final updated = AmenityModel.fromEntity(
      _amenities[index].copyWith(isActive: !_amenities[index].isActive),
    );
    _amenities[index] = updated;
    return updated;
  }

  AmenityModel _amenityById(String id) {
    final match = _amenities.where((item) => item.id == id).toList();
    if (match.isEmpty) throw StateError('Không tìm thấy tiện ích.');
    return match.first;
  }

  int _bookingIndex(String id) {
    final index = _bookings.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Không tìm thấy lượt đặt tiện ích.');
    return index;
  }

  AmenityBookingModel _replaceBooking(int index, AmenityBooking value) {
    final updated = AmenityBookingModel.fromEntity(value);
    _bookings[index] = updated;
    return updated;
  }

  void _validateSlot(
    AmenityModel amenity,
    DateTime start,
    DateTime end,
    int attendees,
  ) {
    if (attendees < 1 || attendees > amenity.capacity) {
      throw ArgumentError(
        'Số người tham gia phải từ 1 đến ${amenity.capacity}.',
      );
    }
    if (start.isBefore(DateTime.now())) {
      throw ArgumentError('Chỉ có thể đặt khung giờ trong tương lai.');
    }
    _validateHours(amenity, start, end);
  }

  void _validateHours(AmenityModel amenity, DateTime start, DateTime end) {
    if (start.year != end.year ||
        start.month != end.month ||
        start.day != end.day ||
        start.hour < amenity.openingHour ||
        end.hour > amenity.closingHour ||
        (end.hour == amenity.closingHour && end.minute > 0)) {
      throw ArgumentError(
        'Khung giờ phải nằm trong ${amenity.openingHour}:00–${amenity.closingHour}:00.',
      );
    }
  }

  void _ensureNoOverlap(String amenityId, DateTime start, DateTime end) {
    final overlaps = _bookings.any(
      (booking) =>
          booking.amenityId == amenityId &&
          booking.status.blocksTimeSlot &&
          start.isBefore(booking.endAt) &&
          end.isAfter(booking.startAt),
    );
    if (overlaps) {
      throw StateError('Khung giờ này đã có lượt đặt hoặc đang bị khóa.');
    }
  }

  static List<AmenityModel> _seedAmenities() => const <AmenityModel>[
    AmenityModel(
      id: 'amenity-pool',
      name: 'Hồ bơi tầng 1',
      description: 'Hồ bơi ngoài trời dành cho cư dân.',
      category: AmenityCategory.pool,
      capacity: 12,
      slotDurationMinutes: 60,
      openingHour: 6,
      closingHour: 21,
      isActive: true,
      fee: 30000,
    ),
    AmenityModel(
      id: 'amenity-community',
      name: 'Phòng sinh hoạt cộng đồng',
      description: 'Không gian tổ chức họp mặt và hoạt động nội bộ.',
      category: AmenityCategory.communityRoom,
      capacity: 40,
      slotDurationMinutes: 120,
      openingHour: 8,
      closingHour: 22,
      isActive: true,
      fee: 150000,
    ),
    AmenityModel(
      id: 'amenity-badminton',
      name: 'Sân cầu lông',
      description: 'Sân trong nhà, phù hợp tối đa bốn người chơi.',
      category: AmenityCategory.sport,
      capacity: 4,
      slotDurationMinutes: 60,
      openingHour: 6,
      closingHour: 22,
      isActive: true,
      fee: 50000,
    ),
    AmenityModel(
      id: 'amenity-bbq',
      name: 'Khu BBQ sân vườn',
      description: 'Khu vực nướng ngoài trời có bàn ghế cơ bản.',
      category: AmenityCategory.barbecue,
      capacity: 16,
      slotDurationMinutes: 180,
      openingHour: 10,
      closingHour: 22,
      isActive: false,
      fee: 200000,
    ),
  ];

  static List<AmenityBookingModel> _seedBookings(DateTime now) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 2));
    return <AmenityBookingModel>[
      AmenityBookingModel(
        id: 'amenity-booking-001',
        code: 'TI-${now.year}-1001',
        amenityId: 'amenity-pool',
        amenityName: 'Hồ bơi tầng 1',
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        startAt: day.add(const Duration(hours: 9)),
        endAt: day.add(const Duration(hours: 10)),
        attendeeCount: 3,
        note: 'Đặt cho gia đình.',
        status: AmenityBookingStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      AmenityBookingModel(
        id: 'amenity-booking-002',
        code: 'TI-${now.year}-1002',
        amenityId: 'amenity-community',
        amenityName: 'Phòng sinh hoạt cộng đồng',
        apartmentId: 'apartment-001',
        residentId: 'resident-owner-001',
        residentName: 'Nguyễn Văn An',
        startAt: day.add(const Duration(hours: 14)),
        endAt: day.add(const Duration(hours: 16)),
        attendeeCount: 20,
        note: 'Sinh hoạt gia đình.',
        status: AmenityBookingStatus.approved,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        managementNote: 'Đã duyệt.',
      ),
      AmenityBookingModel(
        id: 'amenity-block-001',
        code: 'KHOA-${now.year}-1003',
        amenityId: 'amenity-badminton',
        amenityName: 'Sân cầu lông',
        apartmentId: '',
        residentId: 'management',
        residentName: 'Ban quản lý',
        startAt: day.add(const Duration(hours: 17)),
        endAt: day.add(const Duration(hours: 18)),
        attendeeCount: 0,
        note: 'Bảo trì lưới sân.',
        status: AmenityBookingStatus.blocked,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        managementNote: 'Khung giờ được ban quản lý khóa.',
      ),
    ];
  }
}
