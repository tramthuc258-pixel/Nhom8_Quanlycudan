import 'package:flutter/foundation.dart';

import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/services/amenity_repository.dart';

class AmenityController extends ChangeNotifier {
  AmenityController({required this.repository});

  final AmenityRepository repository;
  bool _isLoading = false;
  String? _errorMessage;
  List<Amenity> _amenities = const <Amenity>[];
  List<AmenityBooking> _bookings = const <AmenityBooking>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Amenity> get amenities => _amenities;
  List<AmenityBooking> get bookings => _bookings;
  List<Amenity> get activeAmenities =>
      List<Amenity>.unmodifiable(_amenities.where((item) => item.isActive));

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

  Amenity? amenityById(String id) {
    for (final amenity in _amenities) {
      if (amenity.id == id) return amenity;
    }
    return null;
  }

  List<AmenityBooking> bookingsForResident(String residentId) =>
      List<AmenityBooking>.unmodifiable(
        _bookings.where((item) => item.residentId == residentId),
      );

  List<AmenityBooking> bookingsForAmenity(String amenityId) =>
      List<AmenityBooking>.unmodifiable(
        _bookings.where((item) => item.amenityId == amenityId),
      );

  Future<bool> createBooking({
    required String amenityId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required DateTime startAt,
    required int attendeeCount,
    String note = '',
  }) => _mutate(
    () => repository.createBooking(
      amenityId: amenityId,
      apartmentId: apartmentId,
      residentId: residentId,
      residentName: residentName,
      startAt: startAt,
      attendeeCount: attendeeCount,
      note: note,
    ),
  );

  Future<bool> cancelBooking(String bookingId) =>
      _mutate(() => repository.cancelBooking(bookingId));

  Future<bool> reviewBooking({
    required String bookingId,
    required bool approved,
    required String note,
  }) => _mutate(
    () => repository.reviewBooking(
      bookingId: bookingId,
      approved: approved,
      note: note,
    ),
  );
  Future<bool> checkInBooking(String bookingId) =>
      _mutate(() => repository.checkInBooking(bookingId));
  Future<bool> completeBooking(String bookingId) =>
      _mutate(() => repository.completeBooking(bookingId));
  Future<bool> markNoShow(String bookingId) =>
      _mutate(() => repository.markNoShow(bookingId));

  Future<bool> blockTimeSlot({
    required String amenityId,
    required DateTime startAt,
    required DateTime endAt,
    String note = '',
  }) => _mutate(
    () => repository.blockTimeSlot(
      amenityId: amenityId,
      startAt: startAt,
      endAt: endAt,
      note: note,
    ),
  );

  Future<bool> toggleAmenityActive(String amenityId) =>
      _mutate(() => repository.toggleAmenityActive(amenityId));

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
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
    final result = await Future.wait<Object>([
      repository.getAmenities(),
      repository.getBookings(),
    ]);
    final amenities = List<Amenity>.from(result[0] as List<Amenity>)
      ..sort((a, b) => a.name.compareTo(b.name));
    final bookings = List<AmenityBooking>.from(
      result[1] as List<AmenityBooking>,
    )..sort((a, b) => a.startAt.compareTo(b.startAt));
    _amenities = List<Amenity>.unmodifiable(amenities);
    _bookings = List<AmenityBooking>.unmodifiable(bookings);
  }

  String _messageFor(Object error) => switch (error) {
    StateError(message: final message) => message,
    ArgumentError(message: final Object? message) =>
      message?.toString() ?? 'Dữ liệu đặt tiện ích không hợp lệ.',
    _ => 'Không thể cập nhật tiện ích. Vui lòng thử lại.',
  };
}
