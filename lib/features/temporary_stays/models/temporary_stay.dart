import 'temporary_stay_status.dart';

class TemporaryStay {
  const TemporaryStay({
    required this.id,
    required this.apartmentId,
    required this.apartmentCode,
    required this.declaredById,
    required this.declaredByName,
    required this.guestFullName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.guestDateOfBirth,
    this.guestPhone,
    this.relationshipToResident,
    this.purpose,
    this.reviewNote,
    this.reviewedByName,
    this.checkedInByName,
    this.checkedOutByName,
    this.checkedInAt,
    this.checkedOutAt,
  });

  final String id;
  final String apartmentId;
  final String apartmentCode;
  final String declaredById;
  final String declaredByName;
  final String guestFullName;
  final DateTime? guestDateOfBirth;
  final String? guestPhone;
  final String? relationshipToResident;
  final DateTime startDate;
  final DateTime endDate;
  final String? purpose;
  final TemporaryStayStatus status;
  final String? reviewNote;
  final String? reviewedByName;
  final String? checkedInByName;
  final String? checkedOutByName;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
