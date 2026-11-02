import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/services/amenity_repository.dart';
import 'package:homie/features/amenities/services/amenity_data_source.dart';

class AmenityRepositoryImpl implements AmenityRepository {
  const AmenityRepositoryImpl(this._source);
  final AmenityDataSource _source;
  @override
  Future<List<Amenity>> getAmenities() => _source.getAmenities();
  @override
  Future<List<AmenityBooking>> getBookings() => _source.getBookings();
  @override
  Future<AmenityBooking> createBooking({
    required String amenityId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required DateTime startAt,
    required int attendeeCount,
    required String note,
  }) => _source.createBooking(
    amenityId: amenityId,
    apartmentId: apartmentId,
    residentId: residentId,
    residentName: residentName,
    startAt: startAt,
    attendeeCount: attendeeCount,
    note: note,
  );
  @override
  Future<AmenityBooking> cancelBooking(String bookingId) =>
      _source.cancelBooking(bookingId);
  @override
  Future<AmenityBooking> reviewBooking({
    required String bookingId,
    required bool approved,
    required String note,
  }) => _source.reviewBooking(
    bookingId: bookingId,
    approved: approved,
    note: note,
  );
  @override
  Future<AmenityBooking> checkInBooking(String bookingId) =>
      _source.checkInBooking(bookingId);
  @override
  Future<AmenityBooking> completeBooking(String bookingId) =>
      _source.completeBooking(bookingId);
  @override
  Future<AmenityBooking> markNoShow(String bookingId) =>
      _source.markNoShow(bookingId);
  @override
  Future<AmenityBooking> blockTimeSlot({
    required String amenityId,
    required DateTime startAt,
    required DateTime endAt,
    required String note,
  }) => _source.blockTimeSlot(
    amenityId: amenityId,
    startAt: startAt,
    endAt: endAt,
    note: note,
  );
  @override
  Future<Amenity> toggleAmenityActive(String amenityId) =>
      _source.toggleAmenityActive(amenityId);
}
