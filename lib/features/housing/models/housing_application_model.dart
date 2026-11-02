import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

class HousingApplicationModel extends HousingApplication {
  const HousingApplicationModel({
    required super.id,
    required super.code,
    required super.listingId,
    required super.apartmentId,
    required super.transactionType,
    required super.applicantId,
    required super.applicantFullName,
    required super.applicantEmail,
    required super.applicantPhone,
    required super.preferredStartDate,
    required super.note,
    required super.status,
    required super.submittedAt,
    super.preferredEndDate,
    super.reviewedAt,
    super.reviewedBy,
    super.reviewNote,
    super.contractNumber,
    super.contractSignedAt,
    super.effectiveDate,
  });

  factory HousingApplicationModel.fromMap(Map<String, Object?> map) {
    return HousingApplicationModel(
      id: map['id']! as String,
      code: map['code']! as String,
      listingId: map['listingId']! as String,
      apartmentId: map['apartmentId']! as String,
      transactionType: HousingTransactionType.values.byName(
        map['transactionType']! as String,
      ),
      applicantId: map['applicantId']! as String,
      applicantFullName: map['applicantFullName']! as String,
      applicantEmail: map['applicantEmail']! as String,
      applicantPhone: map['applicantPhone']! as String,
      preferredStartDate: DateTime.parse(map['preferredStartDate']! as String),
      preferredEndDate: _nullableDate(map['preferredEndDate']),
      note: map['note'] as String? ?? '',
      status: HousingApplicationStatus.values.byName(map['status']! as String),
      submittedAt: DateTime.parse(map['submittedAt']! as String),
      reviewedAt: _nullableDate(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewNote: map['reviewNote'] as String?,
      contractNumber: map['contractNumber'] as String?,
      contractSignedAt: _nullableDate(map['contractSignedAt']),
      effectiveDate: _nullableDate(map['effectiveDate']),
    );
  }

  factory HousingApplicationModel.fromEntity(HousingApplication application) {
    return HousingApplicationModel(
      id: application.id,
      code: application.code,
      listingId: application.listingId,
      apartmentId: application.apartmentId,
      transactionType: application.transactionType,
      applicantId: application.applicantId,
      applicantFullName: application.applicantFullName,
      applicantEmail: application.applicantEmail,
      applicantPhone: application.applicantPhone,
      preferredStartDate: application.preferredStartDate,
      preferredEndDate: application.preferredEndDate,
      note: application.note,
      status: application.status,
      submittedAt: application.submittedAt,
      reviewedAt: application.reviewedAt,
      reviewedBy: application.reviewedBy,
      reviewNote: application.reviewNote,
      contractNumber: application.contractNumber,
      contractSignedAt: application.contractSignedAt,
      effectiveDate: application.effectiveDate,
    );
  }

  static DateTime? _nullableDate(Object? value) {
    return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
  }
}
