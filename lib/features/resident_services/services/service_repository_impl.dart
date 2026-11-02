import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/features/resident_services/services/service_repository.dart';
import 'package:homie/features/resident_services/services/service_data_source.dart';
import 'package:homie/core/models/work_assignee.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  const ServiceRepositoryImpl(this._dataSource);

  final ServiceDataSource _dataSource;

  @override
  Future<List<ResidentService>> getServices() => _dataSource.getServices();

  @override
  Future<List<ServiceBooking>> getBookings() => _dataSource.getBookings();

  @override
  Future<List<WorkAssignee>> getAssignees(String bookingId) =>
      _dataSource.getAssignees(bookingId);

  @override
  Future<ServiceBooking> createBooking({
    required String serviceId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    required String note,
  }) => _dataSource.createBooking(
    serviceId: serviceId,
    apartmentId: apartmentId,
    residentId: residentId,
    residentName: residentName,
    quantity: quantity,
    scheduledAt: scheduledAt,
    note: note,
  );

  @override
  Future<ServiceBooking> cancelBooking(String bookingId) =>
      _dataSource.cancelBooking(bookingId);

  @override
  Future<ServiceBooking> assignBooking({
    required String bookingId,
    required String assigneeId,
    required String assigneeName,
  }) => _dataSource.assignBooking(
    bookingId: bookingId,
    assigneeId: assigneeId,
    assigneeName: assigneeName,
  );

  @override
  Future<ServiceBooking> updateBookingStatus({
    required String bookingId,
    required ServiceBookingStatus status,
    required String note,
  }) => _dataSource.updateBookingStatus(
    bookingId: bookingId,
    status: status,
    note: note,
  );

  @override
  Future<ServiceBooking> respondToResult({
    required String bookingId,
    required bool confirmed,
    required String note,
  }) => _dataSource.respondToResult(
    bookingId: bookingId,
    confirmed: confirmed,
    note: note,
  );

  @override
  Future<ResidentService> toggleServiceActive(String serviceId) =>
      _dataSource.toggleServiceActive(serviceId);
}
