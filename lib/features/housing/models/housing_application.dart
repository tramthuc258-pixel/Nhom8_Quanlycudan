import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

class HousingApplication {
  const HousingApplication({
    required this.id,
    required this.code,
    required this.listingId,
    required this.apartmentId,
    required this.transactionType,
    required this.applicantId,
    required this.applicantFullName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.preferredStartDate,
    required this.note,
    required this.status,
    required this.submittedAt,
    this.preferredEndDate,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
    this.contractNumber,
    this.contractSignedAt,
    this.effectiveDate,
  });

  final String id;
  final String code;
  final String listingId;
  final String apartmentId;
  final HousingTransactionType transactionType;
  final String applicantId;
  final String applicantFullName;
  final String applicantEmail;
  final String applicantPhone;
  final DateTime preferredStartDate;
  final DateTime? preferredEndDate;
  final String note;
  final HousingApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;
  final String? contractNumber;
  final DateTime? contractSignedAt;
  final DateTime? effectiveDate;

  String get applicantName => applicantFullName;
  DateTime get desiredStartDate => preferredStartDate;
  DateTime? get desiredEndDate => preferredEndDate;
  HousingTransactionType get type => transactionType;

  bool get canBeReviewed => status.isPending;

  HousingApplication copyWith({
    HousingApplicationStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
    String? contractNumber,
    DateTime? contractSignedAt,
    DateTime? effectiveDate,
  }) {
    return HousingApplication(
      id: id,
      code: code,
      listingId: listingId,
      apartmentId: apartmentId,
      transactionType: transactionType,
      applicantId: applicantId,
      applicantFullName: applicantFullName,
      applicantEmail: applicantEmail,
      applicantPhone: applicantPhone,
      preferredStartDate: preferredStartDate,
      preferredEndDate: preferredEndDate,
      note: note,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
      contractNumber: contractNumber ?? this.contractNumber,
      contractSignedAt: contractSignedAt ?? this.contractSignedAt,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }
}
