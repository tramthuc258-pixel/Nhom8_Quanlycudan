import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/features/resident_services/models/service_booking_update.dart';

import '../models/resident_service_model.dart';
import '../models/service_booking_model.dart';
import 'service_data_source.dart';

import 'package:homie/core/models/work_assignee.dart';

class ServiceMockDataSource implements ServiceDataSource {
  ServiceMockDataSource({this.referenceTime})
    : _services = _seedServices(),
      _bookings = _seedBookings();

  final DateTime? referenceTime;
  final List<ResidentServiceModel> _services;
  final List<ServiceBookingModel> _bookings;
  int _nextBookingNumber = 2007;

  DateTime get _now => referenceTime ?? DateTime.now();

  @override
  Future<List<ResidentServiceModel>> getServices() async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return List<ResidentServiceModel>.unmodifiable(_services);
  }

  @override
  Future<List<ServiceBookingModel>> getBookings() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List<ServiceBookingModel>.unmodifiable(_bookings);
  }

  @override
  Future<List<WorkAssignee>> getAssignees(String bookingId) async => const [
    WorkAssignee(
      id: 'technician-001',
      fullName: 'Lê Hoàng Kỹ Thuật',
      email: 'kythuat.le@homie.com',
      roles: ['TECHNICIAN'],
    ),
    WorkAssignee(
      id: 'receptionist-001',
      fullName: 'Phạm Thu Lễ Tân',
      email: 'letan.pham@homie.com',
      roles: ['RECEPTIONIST'],
    ),
  ];

  @override
  Future<ServiceBookingModel> createBooking({
    required String serviceId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final service = _serviceById(serviceId);
    if (!service.isActive) {
      throw StateError('Dịch vụ này hiện đang tạm ngừng nhận đăng ký.');
    }
    _validateBooking(
      apartmentId: apartmentId,
      residentId: residentId,
      residentName: residentName,
      quantity: quantity,
      scheduledAt: scheduledAt,
      note: note,
    );

    final now = _now;
    final sequence = _nextBookingNumber++;
    final booking = ServiceBookingModel(
      id: 'service-booking-${now.microsecondsSinceEpoch}-$sequence',
      code: 'DV-${now.year}-${sequence.toString().padLeft(4, '0')}',
      serviceId: service.id,
      serviceName: service.name,
      unitPrice: service.unitPrice,
      apartmentId: apartmentId.trim(),
      residentId: residentId.trim(),
      residentName: residentName.trim(),
      quantity: quantity,
      scheduledAt: scheduledAt,
      note: note.trim(),
      status: ServiceBookingStatus.pending,
      createdAt: now,
      updatedAt: now,
      history: [
        ServiceBookingUpdate(
          id: 'service-update-${now.microsecondsSinceEpoch}',
          status: ServiceBookingStatus.pending,
          note: 'Yêu cầu dịch vụ đã được gửi đến ban quản lý.',
          actorName: residentName.trim(),
          createdAt: now,
        ),
      ],
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<ServiceBookingModel> cancelBooking(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _bookingIndex(bookingId);
    final current = _bookings[index];
    if (!current.status.canCancelByResident) {
      throw StateError('Chỉ có thể hủy đăng ký khi ban quản lý chưa xác nhận.');
    }

    return _replaceBooking(
      index,
      current.copyWith(
        status: ServiceBookingStatus.cancelled,
        updatedAt: _now,
        managementNote: 'Cư dân đã hủy đăng ký dịch vụ.',
      ),
    );
  }

  @override
  Future<ServiceBookingModel> assignBooking({
    required String bookingId,
    required String assigneeId,
    required String assigneeName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (assigneeId.isEmpty || assigneeName.trim().length < 3) {
      throw ArgumentError('Vui lòng chọn nhân viên phụ trách.');
    }
    final index = _bookingIndex(bookingId);
    final current = _bookings[index];
    if (current.status.isTerminal) {
      throw StateError('Không thể phân công đăng ký đã kết thúc.');
    }
    final nextStatus = current.status == ServiceBookingStatus.pending
        ? ServiceBookingStatus.confirmed
        : current.status;
    return _replaceBooking(
      index,
      current.copyWith(
        status: nextStatus,
        assignedTo: assigneeName.trim(),
        assignedToId: assigneeId,
        managementNote: 'Đã phân công cho ${assigneeName.trim()}.',
        updatedAt: _now,
      ),
    );
  }

  @override
  Future<ServiceBookingModel> updateBookingStatus({
    required String bookingId,
    required ServiceBookingStatus status,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final index = _bookingIndex(bookingId);
    final current = _bookings[index];
    if (current.status == status) {
      throw StateError('Đăng ký đang ở trạng thái này.');
    }
    if (!_canTransition(current.status, status)) {
      throw StateError(
        'Không thể chuyển từ “${current.status.label}” sang “${status.label}”.',
      );
    }
    if ((status == ServiceBookingStatus.waitingResident ||
            status == ServiceBookingStatus.cancelled) &&
        note.trim().length < 5) {
      throw ArgumentError('Vui lòng nhập ghi chú ít nhất 5 ký tự.');
    }
    return _replaceBooking(
      index,
      current.copyWith(
        status: status,
        managementNote: note.trim().isEmpty
            ? 'Trạng thái được cập nhật thành ${status.label}.'
            : note.trim(),
        updatedAt: _now,
      ),
    );
  }

  @override
  Future<ServiceBookingModel> respondToResult({
    required String bookingId,
    required bool confirmed,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final index = _bookingIndex(bookingId);
    final current = _bookings[index];
    if (current.status != ServiceBookingStatus.waitingResident) {
      throw StateError('Dịch vụ chưa ở trạng thái chờ cư dân xác nhận.');
    }
    if (!confirmed && note.trim().length < 5) {
      throw ArgumentError('Vui lòng mô tả nội dung cần xử lý lại.');
    }
    final now = _now;
    final status = confirmed
        ? ServiceBookingStatus.completed
        : ServiceBookingStatus.inProgress;
    final effectiveNote = confirmed
        ? note.trim().isEmpty
              ? 'Cư dân xác nhận dịch vụ đã hoàn tất.'
              : note.trim()
        : 'Cư dân yêu cầu xử lý lại: ${note.trim()}';
    return _replaceBooking(
      index,
      current.copyWith(
        status: status,
        managementNote: effectiveNote,
        updatedAt: now,
        history: [
          ...current.history,
          ServiceBookingUpdate(
            id: 'service-update-${now.microsecondsSinceEpoch}',
            status: status,
            note: effectiveNote,
            actorName: current.residentName,
            createdAt: now,
          ),
        ],
      ),
    );
  }

  @override
  Future<ResidentServiceModel> toggleServiceActive(String serviceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 110));
    final index = _services.indexWhere((service) => service.id == serviceId);
    if (index < 0) throw StateError('Không tìm thấy dịch vụ cần cập nhật.');
    final updated = ResidentServiceModel.fromEntity(
      _services[index].copyWith(isActive: !_services[index].isActive),
    );
    _services[index] = updated;
    return updated;
  }

  ResidentServiceModel _serviceById(String serviceId) {
    for (final service in _services) {
      if (service.id == serviceId) return service;
    }
    throw StateError('Không tìm thấy dịch vụ đã chọn.');
  }

  int _bookingIndex(String bookingId) {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index < 0) throw StateError('Không tìm thấy đăng ký dịch vụ.');
    return index;
  }

  ServiceBookingModel _replaceBooking(int index, ServiceBooking booking) {
    final model = ServiceBookingModel.fromEntity(booking);
    _bookings[index] = model;
    return model;
  }

  void _validateBooking({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    required String note,
  }) {
    if (apartmentId.trim().isEmpty || residentId.trim().isEmpty) {
      throw ArgumentError('Không xác định được căn hộ hoặc cư dân đăng ký.');
    }
    if (residentName.trim().length < 2) {
      throw ArgumentError('Không xác định được tên cư dân đăng ký.');
    }
    if (quantity < 1 || quantity > 99) {
      throw ArgumentError('Số lượng dịch vụ phải từ 1 đến 99.');
    }
    if (!scheduledAt.isAfter(_now)) {
      throw ArgumentError('Lịch hẹn phải ở trong tương lai.');
    }
    if (scheduledAt.isAfter(_now.add(const Duration(days: 365)))) {
      throw ArgumentError('Chỉ có thể đặt lịch trong vòng 365 ngày.');
    }
    if (note.trim().length > 500) {
      throw ArgumentError('Ghi chú không được vượt quá 500 ký tự.');
    }
  }

  bool _canTransition(ServiceBookingStatus from, ServiceBookingStatus to) {
    return switch (from) {
      ServiceBookingStatus.pending =>
        to == ServiceBookingStatus.confirmed ||
            to == ServiceBookingStatus.cancelled,
      ServiceBookingStatus.confirmed =>
        to == ServiceBookingStatus.inProgress ||
            to == ServiceBookingStatus.cancelled,
      ServiceBookingStatus.inProgress =>
        to == ServiceBookingStatus.waitingResident ||
            to == ServiceBookingStatus.cancelled,
      ServiceBookingStatus.waitingResident =>
        to == ServiceBookingStatus.cancelled,
      ServiceBookingStatus.completed || ServiceBookingStatus.cancelled => false,
    };
  }

  static List<ResidentServiceModel> _seedServices() {
    return <ResidentServiceModel>[
      ResidentServiceModel(
        id: 'service-001',
        name: 'Vệ sinh căn hộ',
        description:
            'Vệ sinh tổng quát phòng khách, phòng ngủ, bếp và nhà vệ sinh.',
        category: ServiceCategory.cleaning,
        unitLabel: 'lần',
        unitPrice: 350000,
        estimatedDurationMinutes: 120,
        providerName: 'Homie Cleaning',
        contactPhone: '02873001205',
        isActive: true,
      ),
      ResidentServiceModel(
        id: 'service-002',
        name: 'Giặt sấy tận nơi',
        description: 'Nhận và giao quần áo tại căn hộ trong vòng 24 giờ.',
        category: ServiceCategory.laundry,
        unitLabel: 'kg',
        unitPrice: 45000,
        estimatedDurationMinutes: 1440,
        providerName: 'Mây Laundry',
        contactPhone: '0908123456',
        isActive: true,
      ),
      ResidentServiceModel(
        id: 'service-003',
        name: 'Vệ sinh máy lạnh',
        description: 'Kiểm tra và vệ sinh dàn lạnh, lưới lọc máy lạnh.',
        category: ServiceCategory.technical,
        unitLabel: 'máy',
        unitPrice: 180000,
        estimatedDurationMinutes: 60,
        providerName: 'Kỹ thuật Homie',
        contactPhone: '02873004567',
        isActive: true,
      ),
      ResidentServiceModel(
        id: 'service-004',
        name: 'Giao nước uống',
        description: 'Nước tinh khiết bình 19 lít, giao tận cửa căn hộ.',
        category: ServiceCategory.convenience,
        unitLabel: 'bình',
        unitPrice: 70000,
        estimatedDurationMinutes: 30,
        providerName: 'Homie Mart',
        contactPhone: '02873007890',
        isActive: true,
      ),
      ResidentServiceModel(
        id: 'service-005',
        name: 'Chuyển đồ nội khu',
        description: 'Hỗ trợ vận chuyển đồ đạc giữa các căn hộ trong khu.',
        category: ServiceCategory.transportation,
        unitLabel: 'chuyến',
        unitPrice: 250000,
        estimatedDurationMinutes: 90,
        providerName: 'Đội vận hành Homie',
        contactPhone: '02873001205',
        isActive: true,
      ),
      ResidentServiceModel(
        id: 'service-006',
        name: 'Diệt côn trùng định kỳ',
        description:
            'Phun xử lý côn trùng bằng dung dịch an toàn cho gia đình.',
        category: ServiceCategory.cleaning,
        unitLabel: 'lần',
        unitPrice: 450000,
        estimatedDurationMinutes: 90,
        providerName: 'Green Pest Control',
        contactPhone: '0911222333',
        isActive: false,
      ),
    ];
  }

  static List<ServiceBookingModel> _seedBookings() {
    return <ServiceBookingModel>[
      ServiceBookingModel(
        id: 'service-booking-001',
        code: 'DV-2026-2001',
        serviceId: 'service-001',
        serviceName: 'Vệ sinh căn hộ',
        unitPrice: 350000,
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        quantity: 1,
        scheduledAt: DateTime(2026, 10, 18, 9),
        note: 'Ưu tiên vệ sinh khu vực bếp và ban công.',
        status: ServiceBookingStatus.pending,
        createdAt: DateTime(2026, 10, 16, 8, 30),
        updatedAt: DateTime(2026, 10, 16, 8, 30),
      ),
      ServiceBookingModel(
        id: 'service-booking-002',
        code: 'DV-2026-2002',
        serviceId: 'service-002',
        serviceName: 'Giặt sấy tận nơi',
        unitPrice: 45000,
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        quantity: 4,
        scheduledAt: DateTime(2026, 10, 9, 18),
        note: 'Có một túi đồ màu trắng cần giặt riêng.',
        status: ServiceBookingStatus.completed,
        createdAt: DateTime(2026, 10, 8, 20),
        updatedAt: DateTime(2026, 10, 10, 17, 30),
        assignedTo: 'Mây Laundry - NV02',
        managementNote: 'Đã giao đủ 4 kg quần áo tại căn hộ.',
      ),
      ServiceBookingModel(
        id: 'service-booking-003',
        code: 'DV-2026-2003',
        serviceId: 'service-004',
        serviceName: 'Giao nước uống',
        unitPrice: 70000,
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        quantity: 2,
        scheduledAt: DateTime(2026, 10, 20, 17, 30),
        note: 'Gọi điện trước khi giao.',
        status: ServiceBookingStatus.confirmed,
        createdAt: DateTime(2026, 10, 15, 19, 10),
        updatedAt: DateTime(2026, 10, 16, 7, 45),
        assignedTo: 'Homie Mart - Ca chiều',
        managementNote: 'Đã xác nhận lịch giao.',
      ),
      ServiceBookingModel(
        id: 'service-booking-004',
        code: 'DV-2026-2004',
        serviceId: 'service-003',
        serviceName: 'Vệ sinh máy lạnh',
        unitPrice: 180000,
        apartmentId: 'apartment-002',
        residentId: 'resident-003',
        residentName: 'Phạm Quốc Bảo',
        quantity: 2,
        scheduledAt: DateTime(2026, 10, 16, 10),
        note: 'Hai máy lạnh trong phòng ngủ.',
        status: ServiceBookingStatus.inProgress,
        createdAt: DateTime(2026, 10, 14, 11, 20),
        updatedAt: DateTime(2026, 10, 16, 10, 5),
        assignedTo: 'Kỹ thuật viên Lê Tuấn',
        managementNote: 'Kỹ thuật viên đã đến căn hộ.',
      ),
      ServiceBookingModel(
        id: 'service-booking-005',
        code: 'DV-2026-2005',
        serviceId: 'service-005',
        serviceName: 'Chuyển đồ nội khu',
        unitPrice: 250000,
        apartmentId: 'apartment-004',
        residentId: 'resident-005',
        residentName: 'Đỗ Hoàng Long',
        quantity: 1,
        scheduledAt: DateTime(2026, 10, 15, 14),
        note: 'Chuyển một bàn làm việc xuống kho.',
        status: ServiceBookingStatus.cancelled,
        createdAt: DateTime(2026, 10, 13, 9),
        updatedAt: DateTime(2026, 10, 14, 8, 10),
        managementNote: 'Cư dân thay đổi kế hoạch.',
      ),
      ServiceBookingModel(
        id: 'service-booking-006',
        code: 'DV-2026-2006',
        serviceId: 'service-001',
        serviceName: 'Vệ sinh căn hộ',
        unitPrice: 350000,
        apartmentId: 'apartment-004',
        residentId: 'resident-005',
        residentName: 'Đỗ Hoàng Long',
        quantity: 1,
        scheduledAt: DateTime(2026, 10, 19, 13, 30),
        note: '',
        status: ServiceBookingStatus.confirmed,
        createdAt: DateTime(2026, 10, 15, 10, 20),
        updatedAt: DateTime(2026, 10, 15, 15, 40),
        assignedTo: 'Homie Cleaning - Đội 1',
        managementNote: 'Đã xác nhận với đơn vị cung cấp.',
      ),
    ];
  }
}
