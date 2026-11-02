enum HouseholdMemberStatus { active, ended }

class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.apartmentId,
    required this.createdById,
    required this.fullName,
    required this.relationship,
    required this.startDate,
    required this.status,
    this.dateOfBirth,
    this.phone = '',
    this.endDate,
  });

  final String id;
  final String apartmentId;
  final String createdById;
  final String fullName;
  final DateTime? dateOfBirth;
  final String phone;
  final String relationship;
  final DateTime startDate;
  final DateTime? endDate;
  final HouseholdMemberStatus status;

  bool get isActive => status == HouseholdMemberStatus.active;
}
