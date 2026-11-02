import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/features/residents/models/household_member.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/models/residence_verification.dart';

abstract interface class ResidentRepository {
  Future<List<Resident>> getResidents();

  Future<List<ApartmentMembership>> getMemberships();

  Future<List<HouseholdMember>> getHouseholdMembers();

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

  Future<ApartmentMembership> addMembership({
    String? residentId,
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    DateTime? endDate,
  });

  Future<ApartmentMembership> endMembership(String membershipId);

  Future<HouseholdMember> addHouseholdMember({
    required String apartmentId,
    required String fullName,
    DateTime? dateOfBirth,
    required String phone,
    required String relationship,
    required DateTime startDate,
  });

  Future<HouseholdMember> endHouseholdMember(String memberId);
}
