import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/models/housing_inquiry.dart';
import 'package:homie/features/housing/services/housing_repository.dart';
import 'package:homie/features/housing/services/housing_data_source.dart';

class HousingRepositoryImpl implements HousingRepository {
  const HousingRepositoryImpl(this._dataSource);

  final HousingDataSource _dataSource;

  @override
  bool get managesMemberships => _dataSource.managesMemberships;

  @override
  Future<List<HousingListing>> getListings() => _dataSource.getListings();

  @override
  Future<List<HousingListing>> getPublicListings() =>
      _dataSource.getPublicListings();

  @override
  Future<List<HousingInquiry>> getInquiries() => _dataSource.getInquiries();

  @override
  Future<HousingInquiry> submitPublicInquiry({
    required String listingId,
    required String fullName,
    required String phone,
    required String email,
    required String message,
  }) => _dataSource.submitPublicInquiry(
    listingId: listingId,
    fullName: fullName,
    phone: phone,
    email: email,
    message: message,
  );

  @override
  Future<HousingInquiry> updateInquiry({
    required String inquiryId,
    required HousingInquiryStatus status,
    required String staffNote,
  }) => _dataSource.updateInquiry(
    inquiryId: inquiryId,
    status: status,
    staffNote: staffNote,
  );

  @override
  Future<List<HousingApplication>> getApplications() =>
      _dataSource.getApplications();

  @override
  Future<HousingListing> createListing({
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
  }) => _dataSource.createListing(
    apartmentId: apartmentId,
    apartmentCode: apartmentCode,
    buildingName: buildingName,
    title: title,
    description: description,
    transactionType: transactionType,
    price: price,
    deposit: deposit,
    availableFrom: availableFrom,
    status: status,
    submittedById: submittedById,
    submittedByName: submittedByName,
    ownerSubmitted: ownerSubmitted,
    imageUrls: imageUrls,
  );

  @override
  Future<HousingListing> approveListing({
    required String listingId,
    required String reviewedBy,
  }) =>
      _dataSource.approveListing(listingId: listingId, reviewedBy: reviewedBy);

  @override
  Future<HousingListing> rejectListing({
    required String listingId,
    required String reviewedBy,
    required String reason,
  }) => _dataSource.rejectListing(
    listingId: listingId,
    reviewedBy: reviewedBy,
    reason: reason,
  );

  @override
  Future<HousingApplication> submitApplication({
    required String listingId,
    required String applicantId,
    required String applicantFullName,
    required String applicantEmail,
    required String applicantPhone,
    required DateTime preferredStartDate,
    required DateTime? preferredEndDate,
    required String note,
  }) => _dataSource.submitApplication(
    listingId: listingId,
    applicantId: applicantId,
    applicantFullName: applicantFullName,
    applicantEmail: applicantEmail,
    applicantPhone: applicantPhone,
    preferredStartDate: preferredStartDate,
    preferredEndDate: preferredEndDate,
    note: note,
  );

  @override
  Future<HousingApplication> rejectApplication({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) => _dataSource.rejectApplication(
    applicationId: applicationId,
    reviewedBy: reviewedBy,
    reason: reason,
  );

  @override
  Future<HousingApplication> completeApplication({
    required String applicationId,
    required String completedBy,
    required String contractNumber,
    required DateTime contractSignedAt,
    required DateTime effectiveDate,
    required String note,
  }) => _dataSource.completeApplication(
    applicationId: applicationId,
    completedBy: completedBy,
    contractNumber: contractNumber,
    contractSignedAt: contractSignedAt,
    effectiveDate: effectiveDate,
    note: note,
  );
}
