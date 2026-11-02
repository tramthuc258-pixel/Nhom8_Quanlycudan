import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/core/models/work_assignee.dart';

abstract interface class ServiceRepository {
  Future<List<ResidentService>> getServices();

  Future<List<ServiceBooking>> getBookings();

  Future<List<WorkAssignee>> getAssignees(String bookingId);

  Future<ServiceBooking> createBooking({
    required String serviceId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    required String note,
  });

  Future<ServiceBooking> cancelBooking(String bookingId);

  Future<ServiceBooking> assignBooking({
    required String bookingId,
    required String assigneeId,
    required String assigneeName,
  });

  Future<ServiceBooking> updateBookingStatus({
    required String bookingId,
    required ServiceBookingStatus status,
    required String note,
  });

  Future<ServiceBooking> respondToResult({
    required String bookingId,
    required bool confirmed,
    required String note,
  });

  Future<ResidentService> toggleServiceActive(String serviceId);
}
