import 'package:homie/features/housing/models/housing_application_model.dart';
import 'package:homie/features/housing/models/housing_listing_model.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/models/housing_inquiry.dart';

abstract interface class HousingDataSource {
  bool get managesMemberships;

  Future<List<HousingListingModel>> getListings();

  Future<List<HousingListingModel>> getPublicListings();

  Future<List<HousingInquiry>> getInquiries();

  Future<HousingInquiry> submitPublicInquiry({
    required String listingId,
    required String fullName,
    required String phone,
    required String email,
    required String message,
  });

  Future<HousingInquiry> updateInquiry({
    required String inquiryId,
    required HousingInquiryStatus status,
    required String staffNote,
  });

  Future<List<HousingApplicationModel>> getApplications();

  Future<HousingListingModel> createListing({
    required String apartmentId,
    required String apartmentCode,
    required String buildingName,
    required String title,
    required String description,
    required HousingTransactionType transactionType,
    required double price,
    required double deposit,
    required DateTime availableFrom,
    required HousingListingStatus status,
    required String submittedById,
    required String submittedByName,
    required bool ownerSubmitted,
    List<String> imageUrls = const <String>[],
  });

  Future<HousingListingModel> approveListing({
    required String listingId,
    required String reviewedBy,
  });

  Future<HousingListingModel> rejectListing({
    required String listingId,
    required String reviewedBy,
    required String reason,
  });

  Future<HousingApplicationModel> submitApplication({
    required String listingId,
    required String applicantId,
    required String applicantFullName,
    required String applicantEmail,
    required String applicantPhone,
    required DateTime preferredStartDate,
    required DateTime? preferredEndDate,
    required String note,
  });

  Future<HousingApplicationModel> rejectApplication({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });

  Future<HousingApplicationModel> completeApplication({
    required String applicationId,
    required String completedBy,
    required String contractNumber,
    required DateTime contractSignedAt,
    required DateTime effectiveDate,
    required String note,
  });
}
