import 'household_member.dart';

class HouseholdMemberModel extends HouseholdMember {
  const HouseholdMemberModel({
    required super.id,
    required super.apartmentId,
    required super.createdById,
    required super.fullName,
    required super.relationship,
    required super.startDate,
    required super.status,
    super.dateOfBirth,
    super.phone,
    super.endDate,
  });

  factory HouseholdMemberModel.fromMap(Map<String, Object?> map) {
    return HouseholdMemberModel(
      id: map['id']! as String,
      apartmentId: map['apartmentId']! as String,
      createdById: map['createdById']! as String,
      fullName: map['fullName']! as String,
      dateOfBirth: switch (map['dateOfBirth']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      phone: map['phone'] as String? ?? '',
      relationship: map['relationship']! as String,
      startDate: DateTime.parse(map['startDate']! as String),
      endDate: switch (map['endDate']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      status: HouseholdMemberStatus.values.byName(map['status']! as String),
    );
  }
}
