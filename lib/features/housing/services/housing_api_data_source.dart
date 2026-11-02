import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/housing/models/housing_application_model.dart';
import 'package:homie/features/housing/models/housing_listing_model.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/models/housing_inquiry.dart';

import 'housing_data_source.dart';

class HousingApiDataSource implements HousingDataSource {
  const HousingApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  bool get managesMemberships => true;

  @override
  Future<List<HousingListingModel>> getListings() async {
    try {
      final response = await _apiClient.get('/housing/listings');
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu bài đăng không hợp lệ.');
      return items
          .whereType<Map>()
          .map(
            (item) =>
                HousingListingModel.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<HousingListingModel>> getPublicListings() async {
    try {
      final response = await _apiClient.get('/public/housing/listings');
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu bài đăng không hợp lệ.');
      return items
          .whereType<Map>()
          .map(
            (item) =>
                HousingListingModel.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<HousingInquiry>> getInquiries() async {
    try {
      final response = await _apiClient.get('/housing/inquiries');
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu liên hệ không hợp lệ.');
      return items
          .whereType<Map>()
          .map(
            (item) => HousingInquiry.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingInquiry> submitPublicInquiry({
    required String listingId,
    required String fullName,
    required String phone,
    required String email,
    required String message,
  }) async {
    try {
      final response = await _apiClient.post(
        '/public/housing/inquiries',
        body: <String, Object?>{
          'listingId': listingId,
          'fullName': fullName,
          'phone': phone,
          if (email.trim().isNotEmpty) 'email': email,
          if (message.trim().isNotEmpty) 'message': message,
        },
      );
      return HousingInquiry.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingInquiry> updateInquiry({
    required String inquiryId,
    required HousingInquiryStatus status,
    required String staffNote,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/housing/inquiries/$inquiryId',
        body: <String, Object?>{
          'status': status.apiValue,
          if (staffNote.trim().isNotEmpty) 'staffNote': staffNote,
        },
      );
      return HousingInquiry.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<HousingApplicationModel>> getApplications() async {
    try {
      final response = await _apiClient.get('/housing/applications');
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu hồ sơ không hợp lệ.');
      return items
          .whereType<Map>()
          .map(
            (item) => HousingApplicationModel.fromMap(
              Map<String, Object?>.from(item),
            ),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
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
  }) async {
    try {
      final response = await _apiClient.post(
        '/housing/listings',
        body: <String, Object?>{
          'apartmentId': apartmentId,
          'title': title,
          'description': description,
          'transactionType': _transactionTypeToApi(transactionType),
          'price': price,
          'deposit': deposit,
          'availableFrom': availableFrom.toIso8601String(),
          'imageUrls': imageUrls,
        },
      );
      return HousingListingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingListingModel> approveListing({
    required String listingId,
    required String reviewedBy,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/housing/listings/$listingId/approve',
      );
      return HousingListingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingListingModel> rejectListing({
    required String listingId,
    required String reviewedBy,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/housing/listings/$listingId/reject',
        body: <String, Object?>{'reason': reason},
      );
      return HousingListingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingApplicationModel> submitApplication({
    required String listingId,
    required String applicantId,
    required String applicantFullName,
    required String applicantEmail,
    required String applicantPhone,
    required DateTime preferredStartDate,
    required DateTime? preferredEndDate,
    required String note,
  }) async {
    try {
      final response = await _apiClient.post(
        '/housing/applications',
        body: <String, Object?>{
          'listingId': listingId,
          'phone': applicantPhone,
          'preferredStartDate': preferredStartDate.toIso8601String(),
          if (preferredEndDate != null)
            'preferredEndDate': preferredEndDate.toIso8601String(),
          'note': note,
        },
      );
      return HousingApplicationModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingApplicationModel> rejectApplication({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/housing/applications/$applicationId/reject',
        body: <String, Object?>{'reason': reason},
      );
      return HousingApplicationModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HousingApplicationModel> completeApplication({
    required String applicationId,
    required String completedBy,
    required String contractNumber,
    required DateTime contractSignedAt,
    required DateTime effectiveDate,
    required String note,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/housing/applications/$applicationId/complete',
        body: <String, Object?>{
          'contractNumber': contractNumber,
          'contractSignedAt': contractSignedAt.toIso8601String(),
          'effectiveDate': effectiveDate.toIso8601String(),
          'note': note,
        },
      );
      return HousingApplicationModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  String _transactionTypeToApi(HousingTransactionType type) {
    return switch (type) {
      HousingTransactionType.rent => 'RENT',
      HousingTransactionType.purchase => 'PURCHASE',
    };
  }
}
