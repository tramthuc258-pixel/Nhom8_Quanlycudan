import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

class HousingListingModel extends HousingListing {
  const HousingListingModel({
    required super.id,
    required super.apartmentId,
    required super.apartmentCode,
    required super.buildingName,
    required super.title,
    required super.description,
    required super.transactionType,
    required super.price,
    required super.availableFrom,
    required super.status,
    required super.createdAt,
    super.imageUrls,
    super.deposit,
    super.submittedById,
    super.submittedByName,
    super.ownerSubmitted,
    super.reviewedAt,
    super.reviewedBy,
    super.reviewNote,
  });

  factory HousingListingModel.fromMap(Map<String, Object?> map) {
    return HousingListingModel(
      id: map['id']! as String,
      apartmentId: map['apartmentId']! as String,
      apartmentCode: map['apartmentCode']! as String,
      buildingName: map['buildingName']! as String,
      title: map['title']! as String,
      description: map['description']! as String,
      transactionType: HousingTransactionType.values.byName(
        map['transactionType']! as String,
      ),
      price: (map['price']! as num).toDouble(),
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0,
      availableFrom: DateTime.parse(map['availableFrom']! as String),
      status: HousingListingStatus.values.byName(map['status']! as String),
      createdAt: DateTime.parse(map['createdAt']! as String),
      imageUrls:
          (map['imageUrls'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      submittedById: map['submittedById'] as String?,
      submittedByName: map['submittedByName'] as String?,
      ownerSubmitted: map['ownerSubmitted'] as bool? ?? false,
      reviewedAt: _nullableDate(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewNote: map['reviewNote'] as String?,
    );
  }

  factory HousingListingModel.fromEntity(HousingListing listing) {
    return HousingListingModel(
      id: listing.id,
      apartmentId: listing.apartmentId,
      apartmentCode: listing.apartmentCode,
      buildingName: listing.buildingName,
      title: listing.title,
      description: listing.description,
      transactionType: listing.transactionType,
      price: listing.price,
      deposit: listing.deposit,
      availableFrom: listing.availableFrom,
      status: listing.status,
      createdAt: listing.createdAt,
      imageUrls: List<String>.unmodifiable(listing.imageUrls),
      submittedById: listing.submittedById,
      submittedByName: listing.submittedByName,
      ownerSubmitted: listing.ownerSubmitted,
      reviewedAt: listing.reviewedAt,
      reviewedBy: listing.reviewedBy,
      reviewNote: listing.reviewNote,
    );
  }

  static DateTime? _nullableDate(Object? value) {
    return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
  }
}
