import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/residents/models/apartment_membership_model.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/resident_model.dart';
import 'package:homie/features/residents/models/household_member_model.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/models/apartment_model.dart';
import 'package:homie/features/residents/models/residence_verification.dart';

import 'resident_data_source.dart';

class ResidentApiDataSource implements ResidentDataSource {
  const ResidentApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ResidentModel>> getResidents() async {
    try {
      final response = await _apiClient.get('/residents');
      return _readItems(response, ResidentModel.fromMap);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<ApartmentMembershipModel>> getMemberships() async {
    try {
      final response = await _apiClient.get('/apartment-memberships');
      return _readItems(response, ApartmentMembershipModel.fromMap);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<HouseholdMemberModel>> getHouseholdMembers() async {
    try {
      final response = await _apiClient.get('/household-members');
      return _readItems(response, HouseholdMemberModel.fromMap);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ResidenceVerification> getMyResidenceVerification() async {
    try {
      final response = await _apiClient.get('/residence-verification/me');
      return ResidenceVerification.fromMyResponse(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<Apartment>> getResidenceVerificationApartments() async {
    try {
      final response = await _apiClient.get(
        '/residence-verification/apartments',
      );
      return _readItems(response, ApartmentModel.fromMap);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<ResidenceVerification>> getResidenceVerificationRequests() async {
    try {
      final response = await _apiClient.get('/residence-verification/requests');
      return _readItems(response, ResidenceVerification.fromRequest);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ResidenceVerification> createResidenceVerification({
    required String apartmentId,
    required MembershipType type,
    required DateTime startDate,
    required String contactPhone,
    String? note,
  }) async {
    try {
      final response = await _apiClient.post(
        '/residence-verification/requests',
        body: <String, Object?>{
          'apartmentId': apartmentId,
          'type': type.name.toUpperCase(),
          'startDate': _dateOnly(startDate),
          'contactPhone': contactPhone.trim(),
          if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
        },
      );
      return ResidenceVerification.fromRequest(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ResidenceVerification> reviewResidenceVerification({
    required String requestId,
    required bool approve,
    String? verificationBasis,
    String? reviewNote,
  }) async {
    try {
      final action = approve ? 'approve' : 'reject';
      final response = await _apiClient.patch(
        '/residence-verification/requests/$requestId/$action',
        body: <String, Object?>{
          if (verificationBasis?.trim().isNotEmpty ?? false)
            'verificationBasis': verificationBasis!.trim(),
          if (reviewNote?.trim().isNotEmpty ?? false)
            'reviewNote': reviewNote!.trim(),
        },
      );
      return ResidenceVerification.fromRequest(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ApartmentMembershipModel> addMembership({
    String? residentId,
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/apartment-memberships',
        body: <String, Object?>{
          if (residentId != null && residentId.trim().isNotEmpty)
            'residentId': residentId,
          'apartmentId': apartmentId,
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'type': type.name.toUpperCase(),
          'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      return ApartmentMembershipModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ApartmentMembershipModel> endMembership(String membershipId) async {
    try {
      final response = await _apiClient.patch(
        '/apartment-memberships/$membershipId/end',
      );
      return ApartmentMembershipModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HouseholdMemberModel> addHouseholdMember({
    required String apartmentId,
    required String fullName,
    DateTime? dateOfBirth,
    required String phone,
    required String relationship,
    required DateTime startDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/household-members',
        body: <String, Object?>{
          'apartmentId': apartmentId,
          'fullName': fullName,
          if (dateOfBirth != null) 'dateOfBirth': _dateOnly(dateOfBirth),
          if (phone.trim().isNotEmpty) 'phone': phone.trim(),
          'relationship': relationship,
          'startDate': _dateOnly(startDate),
        },
      );
      return HouseholdMemberModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<HouseholdMemberModel> endHouseholdMember(String memberId) async {
    try {
      final response = await _apiClient.patch(
        '/household-members/$memberId/end',
      );
      return HouseholdMemberModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<T> _readItems<T>(
    Map<String, dynamic> response,
    T Function(Map<String, Object?>) fromMap,
  ) {
    final items = response['items'];
    if (items is! List) throw StateError('Dữ liệu từ API không hợp lệ.');
    return items
        .whereType<Map>()
        .map((item) => fromMap(Map<String, Object?>.from(item)))
        .toList(growable: false);
  }
}
