import 'temporary_stay.dart';
import 'temporary_stay_status.dart';

class TemporaryStayModel extends TemporaryStay {
  const TemporaryStayModel({
    required super.id,
    required super.apartmentId,
    required super.apartmentCode,
    required super.declaredById,
    required super.declaredByName,
    required super.guestFullName,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.guestDateOfBirth,
    super.guestPhone,
    super.relationshipToResident,
    super.purpose,
    super.reviewNote,
    super.reviewedByName,
    super.checkedInByName,
    super.checkedOutByName,
    super.checkedInAt,
    super.checkedOutAt,
  });

  factory TemporaryStayModel.fromMap(Map<String, Object?> map) =>
      TemporaryStayModel(
        id: map['id']! as String,
        apartmentId: map['apartmentId']! as String,
        apartmentCode: map['apartmentCode']! as String,
        declaredById: map['declaredById']! as String,
        declaredByName: map['declaredByName']! as String,
        guestFullName: map['guestFullName']! as String,
        guestDateOfBirth: _date(map['guestDateOfBirth']),
        guestPhone: map['guestPhone'] as String?,
        relationshipToResident: map['relationshipToResident'] as String?,
        startDate: DateTime.parse(map['startDate']! as String).toLocal(),
        endDate: DateTime.parse(map['endDate']! as String).toLocal(),
        purpose: map['purpose'] as String?,
        status: TemporaryStayStatus.values.byName(map['status']! as String),
        reviewNote: map['reviewNote'] as String?,
        reviewedByName: map['reviewedByName'] as String?,
        checkedInByName: map['checkedInByName'] as String?,
        checkedOutByName: map['checkedOutByName'] as String?,
        checkedInAt: _date(map['checkedInAt']),
        checkedOutAt: _date(map['checkedOutAt']),
        createdAt: DateTime.parse(map['createdAt']! as String).toLocal(),
        updatedAt: DateTime.parse(map['updatedAt']! as String).toLocal(),
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
