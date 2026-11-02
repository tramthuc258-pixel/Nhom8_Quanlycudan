import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

class HousingListing {
  const HousingListing({
    required this.id,
    required this.apartmentId,
    required this.apartmentCode,
    required this.buildingName,
    required this.title,
    required this.description,
    required this.transactionType,
    required this.price,
    required this.availableFrom,
    required this.status,
    required this.createdAt,
    this.imageUrls = const <String>[],
    this.deposit = 0,
    this.submittedById,
    this.submittedByName,
    this.ownerSubmitted = false,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  final String id;
  final String apartmentId;
  final String apartmentCode;
  final String buildingName;
  final String title;
  final String description;
  final HousingTransactionType transactionType;
  final double price;
  final double deposit;
  final DateTime availableFrom;
  final HousingListingStatus status;
  final DateTime createdAt;
  final List<String> imageUrls;
  final String? submittedById;
  final String? submittedByName;
  final bool ownerSubmitted;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;

  bool get isAvailable => status.isAvailable;

  HousingListing copyWith({
    String? id,
    String? apartmentId,
    String? apartmentCode,
    String? buildingName,
    String? title,
    String? description,
    HousingTransactionType? transactionType,
    double? price,
    double? deposit,
    DateTime? availableFrom,
    HousingListingStatus? status,
    DateTime? createdAt,
    List<String>? imageUrls,
    String? submittedById,
    String? submittedByName,
    bool? ownerSubmitted,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return HousingListing(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      apartmentCode: apartmentCode ?? this.apartmentCode,
      buildingName: buildingName ?? this.buildingName,
      title: title ?? this.title,
      description: description ?? this.description,
      transactionType: transactionType ?? this.transactionType,
      price: price ?? this.price,
      deposit: deposit ?? this.deposit,
      availableFrom: availableFrom ?? this.availableFrom,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: List<String>.unmodifiable(imageUrls ?? this.imageUrls),
      submittedById: submittedById ?? this.submittedById,
      submittedByName: submittedByName ?? this.submittedByName,
      ownerSubmitted: ownerSubmitted ?? this.ownerSubmitted,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}
