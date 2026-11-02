import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';

abstract interface class AmenityRepository {
  Future<List<Amenity>> getAmenities();
  Future<List<AmenityBooking>> getBookings();
  Future<AmenityBooking> createBooking({
    required String amenityId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required DateTime startAt,
    required int attendeeCount,
    required String note,
  });
  Future<AmenityBooking> cancelBooking(String bookingId);
  Future<AmenityBooking> reviewBooking({
    required String bookingId,
    required bool approved,
    required String note,
  });
  Future<AmenityBooking> checkInBooking(String bookingId);
  Future<AmenityBooking> completeBooking(String bookingId);
  Future<AmenityBooking> markNoShow(String bookingId);
  Future<AmenityBooking> blockTimeSlot({
    required String amenityId,
    required DateTime startAt,
    required DateTime endAt,
    required String note,
  });
  Future<Amenity> toggleAmenityActive(String amenityId);
}
