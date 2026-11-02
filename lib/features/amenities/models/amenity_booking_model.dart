import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';

class AmenityBookingModel extends AmenityBooking {
  const AmenityBookingModel({
    required super.id,
    required super.code,
    required super.amenityId,
    required super.amenityName,
    required super.apartmentId,
    required super.residentId,
    required super.residentName,
    required super.startAt,
    required super.endAt,
    required super.attendeeCount,
    required super.note,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.managementNote,
    super.processedByName,
    super.checkedInAt,
    super.completedAt,
  });

  factory AmenityBookingModel.fromMap(Map<String, Object?> map) =>
      AmenityBookingModel(
        id: map['id']! as String,
        code: map['code']! as String,
        amenityId: map['amenityId']! as String,
        amenityName: map['amenityName']! as String,
        apartmentId: map['apartmentId'] as String? ?? '',
        residentId: map['residentId']! as String,
        residentName: map['residentName']! as String,
        startAt: DateTime.parse(map['startAt']! as String).toLocal(),
        endAt: DateTime.parse(map['endAt']! as String).toLocal(),
        attendeeCount: (map['attendeeCount']! as num).toInt(),
        note: map['note'] as String? ?? '',
        status: AmenityBookingStatus.values.byName(map['status']! as String),
        createdAt: DateTime.parse(map['createdAt']! as String).toLocal(),
        updatedAt: DateTime.parse(map['updatedAt']! as String).toLocal(),
        managementNote: map['managementNote'] as String?,
        processedByName: map['processedByName'] as String?,
        checkedInAt: map['checkedInAt'] == null
            ? null
            : DateTime.parse(map['checkedInAt']! as String).toLocal(),
        completedAt: map['completedAt'] == null
            ? null
            : DateTime.parse(map['completedAt']! as String).toLocal(),
      );

  factory AmenityBookingModel.fromEntity(AmenityBooking value) =>
      AmenityBookingModel(
        id: value.id,
        code: value.code,
        amenityId: value.amenityId,
        amenityName: value.amenityName,
        apartmentId: value.apartmentId,
        residentId: value.residentId,
        residentName: value.residentName,
        startAt: value.startAt,
        endAt: value.endAt,
        attendeeCount: value.attendeeCount,
        note: value.note,
        status: value.status,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        managementNote: value.managementNote,
        processedByName: value.processedByName,
        checkedInAt: value.checkedInAt,
        completedAt: value.completedAt,
      );
}
