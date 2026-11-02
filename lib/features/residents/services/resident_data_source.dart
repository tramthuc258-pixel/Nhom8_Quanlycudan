import 'package:homie/features/residents/models/apartment_membership_model.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/resident_model.dart';
import 'package:homie/features/residents/models/household_member_model.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/models/residence_verification.dart';

abstract interface class ResidentDataSource {
  Future<List<ResidentModel>> getResidents();

  Future<List<ApartmentMembershipModel>> getMemberships();

  Future<List<HouseholdMemberModel>> getHouseholdMembers();

  Future<ResidenceVerification> getMyResidenceVerification();

  Future<List<Apartment>> getResidenceVerificationApartments();

  Future<List<ResidenceVerification>> getResidenceVerificationRequests();

  Future<ResidenceVerification> createResidenceVerification({
    required String apartmentId,
    required MembershipType type,
    required DateTime startDate,
    required String contactPhone,
    String? note,
  });

  Future<ResidenceVerification> reviewResidenceVerification({
    required String requestId,
    required bool approve,
    String? verificationBasis,
    String? reviewNote,
  });

  Future<ApartmentMembershipModel> addMembership({
    String? residentId,
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    DateTime? endDate,
  });

  Future<ApartmentMembershipModel> endMembership(String membershipId);

  Future<HouseholdMemberModel> addHouseholdMember({
    required String apartmentId,
    required String fullName,
    DateTime? dateOfBirth,
    required String phone,
    required String relationship,
    required DateTime startDate,
  });

  Future<HouseholdMemberModel> endHouseholdMember(String memberId);
}
