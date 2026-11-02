import '../models/amenity_booking_model.dart';
import '../models/amenity_model.dart';

abstract interface class AmenityDataSource {
  Future<List<AmenityModel>> getAmenities();
  Future<List<AmenityBookingModel>> getBookings();
  Future<AmenityBookingModel> createBooking({
    required String amenityId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required DateTime startAt,
    required int attendeeCount,
    required String note,
  });
  Future<AmenityBookingModel> cancelBooking(String bookingId);
  Future<AmenityBookingModel> reviewBooking({
    required String bookingId,
    required bool approved,
    required String note,
  });
  Future<AmenityBookingModel> checkInBooking(String bookingId);
  Future<AmenityBookingModel> completeBooking(String bookingId);
  Future<AmenityBookingModel> markNoShow(String bookingId);
  Future<AmenityBookingModel> blockTimeSlot({
    required String amenityId,
    required DateTime startAt,
    required DateTime endAt,
    required String note,
  });
  Future<AmenityModel> toggleAmenityActive(String amenityId);
}
