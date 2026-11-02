import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';

import '../models/amenity_booking_model.dart';
import '../models/amenity_model.dart';
import 'amenity_data_source.dart';

class AmenityApiDataSource implements AmenityDataSource {
  const AmenityApiDataSource(this._client);
  final ApiClient _client;

  @override
  Future<List<AmenityModel>> getAmenities() =>
      _list('/amenities', AmenityModel.fromMap);
  @override
  Future<List<AmenityBookingModel>> getBookings() =>
      _list('/amenities/bookings', AmenityBookingModel.fromMap);
  @override
  Future<AmenityBookingModel> createBooking({
    required String amenityId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required DateTime startAt,
    required int attendeeCount,
    required String note,
  }) => _post('/amenities/bookings', {
    'amenityId': amenityId,
    'apartmentId': apartmentId,
    'startAt': startAt.toUtc().toIso8601String(),
    'attendeeCount': attendeeCount,
    'note': note,
  });
  @override
  Future<AmenityBookingModel> cancelBooking(String bookingId) =>
      _patchBooking('/amenities/bookings/$bookingId/cancel');
  @override
  Future<AmenityBookingModel> reviewBooking({
    required String bookingId,
    required bool approved,
    required String note,
  }) => _patchBooking('/amenities/bookings/$bookingId/review', {
    'approved': approved,
    'note': note,
  });
  @override
  Future<AmenityBookingModel> checkInBooking(String bookingId) =>
      _patchBooking('/amenities/bookings/$bookingId/check-in');
  @override
  Future<AmenityBookingModel> completeBooking(String bookingId) =>
      _patchBooking('/amenities/bookings/$bookingId/complete');
  @override
  Future<AmenityBookingModel> markNoShow(String bookingId) =>
      _patchBooking('/amenities/bookings/$bookingId/no-show');
  @override
  Future<AmenityBookingModel> blockTimeSlot({
    required String amenityId,
    required DateTime startAt,
    required DateTime endAt,
    required String note,
  }) => _post('/amenities/blocked-slots', {
    'amenityId': amenityId,
    'startAt': startAt.toUtc().toIso8601String(),
    'endAt': endAt.toUtc().toIso8601String(),
    'note': note,
  });
  @override
  Future<AmenityModel> toggleAmenityActive(String amenityId) async {
    try {
      return AmenityModel.fromMap(
        await _client.patch('/amenities/$amenityId/toggle-active'),
      );
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, Object?>) parse,
  ) async {
    try {
      final response = await _client.get(path);
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu tiện ích không hợp lệ.');
      return items
          .whereType<Map>()
          .map((e) => parse(Map<String, Object?>.from(e)))
          .toList(growable: false);
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  Future<AmenityBookingModel> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      return AmenityBookingModel.fromMap(await _client.post(path, body: body));
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  Future<AmenityBookingModel> _patchBooking(
    String path, [
    Map<String, Object?>? body,
  ]) async {
    try {
      return AmenityBookingModel.fromMap(await _client.patch(path, body: body));
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }
}
