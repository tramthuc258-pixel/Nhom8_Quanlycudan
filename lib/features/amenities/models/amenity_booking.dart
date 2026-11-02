import 'package:homie/features/amenities/models/amenity_booking_status.dart';

class AmenityBooking {
  const AmenityBooking({
    required this.id,
    required this.code,
    required this.amenityId,
    required this.amenityName,
    required this.apartmentId,
    required this.residentId,
    required this.residentName,
    required this.startAt,
    required this.endAt,
    required this.attendeeCount,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.managementNote,
    this.processedByName,
    this.checkedInAt,
    this.completedAt,
  });

  final String id;
  final String code;
  final String amenityId;
  final String amenityName;
  final String apartmentId;
  final String residentId;
  final String residentName;
  final DateTime startAt;
  final DateTime endAt;
  final int attendeeCount;
  final String note;
  final AmenityBookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? managementNote;
  final String? processedByName;
  final DateTime? checkedInAt;
  final DateTime? completedAt;

  bool get isBlocked => status == AmenityBookingStatus.blocked;

  AmenityBooking copyWith({
    AmenityBookingStatus? status,
    DateTime? updatedAt,
    String? managementNote,
    String? processedByName,
    DateTime? checkedInAt,
    DateTime? completedAt,
  }) => AmenityBooking(
    id: id,
    code: code,
    amenityId: amenityId,
    amenityName: amenityName,
    apartmentId: apartmentId,
    residentId: residentId,
    residentName: residentName,
    startAt: startAt,
    endAt: endAt,
    attendeeCount: attendeeCount,
    note: note,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    managementNote: managementNote ?? this.managementNote,
    processedByName: processedByName ?? this.processedByName,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    completedAt: completedAt ?? this.completedAt,
  );
}
