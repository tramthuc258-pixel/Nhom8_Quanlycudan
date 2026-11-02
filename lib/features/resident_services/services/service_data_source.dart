import 'package:homie/features/resident_services/models/resident_service_model.dart';
import 'package:homie/features/resident_services/models/service_booking_model.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/core/models/work_assignee.dart';

abstract interface class ServiceDataSource {
  Future<List<ResidentServiceModel>> getServices();

  Future<List<ServiceBookingModel>> getBookings();

  Future<List<WorkAssignee>> getAssignees(String bookingId);

  Future<ServiceBookingModel> createBooking({
    required String serviceId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    required String note,
  });

  Future<ServiceBookingModel> cancelBooking(String bookingId);

  Future<ServiceBookingModel> assignBooking({
    required String bookingId,
    required String assigneeId,
    required String assigneeName,
  });

  Future<ServiceBookingModel> updateBookingStatus({
    required String bookingId,
    required ServiceBookingStatus status,
    required String note,
  });

  Future<ServiceBookingModel> respondToResult({
    required String bookingId,
    required bool confirmed,
    required String note,
  });

  Future<ResidentServiceModel> toggleServiceActive(String serviceId);
}
