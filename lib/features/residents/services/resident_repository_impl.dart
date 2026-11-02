import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/features/residents/models/household_member.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/models/residence_verification.dart';
import 'package:homie/features/residents/services/resident_repository.dart';
import 'package:homie/features/residents/services/resident_data_source.dart';

class ResidentRepositoryImpl implements ResidentRepository {
  const ResidentRepositoryImpl(this._dataSource);

  final ResidentDataSource _dataSource;

  @override
  Future<List<Resident>> getResidents() async {
    final residents = await _dataSource.getResidents();
    return List<Resident>.unmodifiable(residents);
  }

  @override
  Future<List<ApartmentMembership>> getMemberships() async {
    final memberships = await _dataSource.getMemberships();
    return List<ApartmentMembership>.unmodifiable(memberships);
  }

  @override
  Future<List<HouseholdMember>> getHouseholdMembers() async {
    final members = await _dataSource.getHouseholdMembers();
    return List<HouseholdMember>.unmodifiable(members);
  }

  @override
  Future<ResidenceVerification> getMyResidenceVerification() =>
      _dataSource.getMyResidenceVerification();

  @override
  Future<List<Apartment>> getResidenceVerificationApartments() =>
      _dataSource.getResidenceVerificationApartments();

  @override
  Future<List<ResidenceVerification>> getResidenceVerificationRequests() =>
      _dataSource.getResidenceVerificationRequests();

  @override
  Future<ResidenceVerification> createResidenceVerification({
    required String apartmentId,
    required MembershipType type,
    required DateTime startDate,
    required String contactPhone,
    String? note,
  }) => _dataSource.createResidenceVerification(
    apartmentId: apartmentId,
    type: type,
    startDate: startDate,
    contactPhone: contactPhone,
    note: note,
  );

  @override
  Future<ResidenceVerification> reviewResidenceVerification({
    required String requestId,
    required bool approve,
    String? verificationBasis,
    String? reviewNote,
  }) => _dataSource.reviewResidenceVerification(
    requestId: requestId,
    approve: approve,
    verificationBasis: verificationBasis,
    reviewNote: reviewNote,
  );

  @override
  Future<ApartmentMembership> addMembership({
    String? residentId,
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return _dataSource.addMembership(
      residentId: residentId,
      apartmentId: apartmentId,
      fullName: fullName,
      phone: phone,
      email: email,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<ApartmentMembership> endMembership(String membershipId) {
    return _dataSource.endMembership(membershipId);
  }

  @override
  Future<HouseholdMember> addHouseholdMember({
    required String apartmentId,
    required String fullName,
    DateTime? dateOfBirth,
    required String phone,
    required String relationship,
    required DateTime startDate,
  }) {
    return _dataSource.addHouseholdMember(
      apartmentId: apartmentId,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      phone: phone,
      relationship: relationship,
      startDate: startDate,
    );
  }

  @override
  Future<HouseholdMember> endHouseholdMember(String memberId) {
    return _dataSource.endHouseholdMember(memberId);
  }
}
