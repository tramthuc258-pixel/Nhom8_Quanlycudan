import 'package:flutter/foundation.dart';

import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/features/resident_services/services/service_repository.dart';
import 'package:homie/core/models/work_assignee.dart';

class ServiceController extends ChangeNotifier {
  ServiceController({required this.repository});

  final ServiceRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<ResidentService> _services = const <ResidentService>[];
  List<ServiceBooking> _bookings = const <ServiceBooking>[];

  bool get isLoading => _isLoading;
  bool get loading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;
  List<ResidentService> get services => _services;
  List<ServiceBooking> get bookings => _bookings;

  List<ResidentService> get activeServices =>
      List<ResidentService>.unmodifiable(
        _services.where((service) => service.isActive),
      );

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _refresh();
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ResidentService? serviceById(String serviceId) {
    for (final service in _services) {
      if (service.id == serviceId) return service;
    }
    return null;
  }

  ServiceBooking? bookingById(String bookingId) {
    for (final booking in _bookings) {
      if (booking.id == bookingId) return booking;
    }
    return null;
  }

  List<ResidentService> servicesByCategory(ServiceCategory category) {
    return List<ResidentService>.unmodifiable(
      _services.where((service) => service.category == category),
    );
  }

  List<ServiceBooking> bookingsForResident(String residentId) {
    return List<ServiceBooking>.unmodifiable(
      _bookings.where((booking) => booking.residentId == residentId),
    );
  }

  List<ServiceBooking> bookingsForApartment(String apartmentId) {
    return List<ServiceBooking>.unmodifiable(
      _bookings.where((booking) => booking.apartmentId == apartmentId),
    );
  }

  int activeBookingCountForResident(String residentId) =>
      bookingsForResident(residentId)
          .where((booking) => booking.status.isActive)
          .length;

  Future<List<WorkAssignee>> getAssignees(String bookingId) =>
      repository.getAssignees(bookingId);

  Future<bool> createBooking({
    required String serviceId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    String note = '',
  }) => _mutateBooking(
    () => repository.createBooking(
      serviceId: serviceId,
      apartmentId: apartmentId,
      residentId: residentId,
      residentName: residentName,
      quantity: quantity,
      scheduledAt: scheduledAt,
      note: note,
    ),
  );

  Future<bool> cancelBooking(String bookingId) =>
      _mutateBooking(() => repository.cancelBooking(bookingId));

  Future<bool> assignBooking({
    required String bookingId,
    required String assigneeId,
    required String assigneeName,
  }) => _mutateBooking(
    () => repository.assignBooking(
      bookingId: bookingId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
    ),
  );

  Future<bool> updateBookingStatus({
    required String bookingId,
    required ServiceBookingStatus status,
    String note = '',
  }) => _mutateBooking(
    () => repository.updateBookingStatus(
      bookingId: bookingId,
      status: status,
      note: note,
    ),
  );

  Future<bool> respondToResult({
    required String bookingId,
    required bool confirmed,
    String note = '',
  }) => _mutateBooking(
    () => repository.respondToResult(
      bookingId: bookingId,
      confirmed: confirmed,
      note: note,
    ),
  );

  Future<bool> toggleServiceActive(String serviceId) =>
      _mutateService(() => repository.toggleServiceActive(serviceId));

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _mutateBooking(Future<ServiceBooking> Function() action) async {
    return _mutate(action);
  }

  Future<bool> _mutateService(Future<ResidentService> Function() action) async {
    return _mutate(action);
  }

  Future<bool> _mutate(Future<Object> Function() action) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await _refresh();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    final servicesFuture = repository.getServices();
    final bookingsFuture = repository.getBookings();
    final services = List<ResidentService>.from(await servicesFuture)
      ..sort(_compareServices);
    final bookings = List<ServiceBooking>.from(await bookingsFuture)
      ..sort(_compareBookings);
    _services = List<ResidentService>.unmodifiable(services);
    _bookings = List<ServiceBooking>.unmodifiable(bookings);
  }

  int _compareServices(ResidentService first, ResidentService second) {
    if (first.isActive != second.isActive) return first.isActive ? -1 : 1;
    final categoryComparison = first.category.index.compareTo(
      second.category.index,
    );
    if (categoryComparison != 0) return categoryComparison;
    return first.name.compareTo(second.name);
  }

  int _compareBookings(ServiceBooking first, ServiceBooking second) {
    final updatedComparison = second.updatedAt.compareTo(first.updatedAt);
    if (updatedComparison != 0) return updatedComparison;
    return second.createdAt.compareTo(first.createdAt);
  }

  String _messageFor(Object error) => switch (error) {
    StateError(message: final message) => message,
    ArgumentError(message: final Object? message) =>
      message?.toString() ?? 'Dữ liệu đăng ký dịch vụ không hợp lệ.',
    _ => 'Không thể cập nhật dịch vụ. Vui lòng thử lại.',
  };
}
