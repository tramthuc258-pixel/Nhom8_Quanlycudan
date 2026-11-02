import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';

class ApartmentMembershipModel extends ApartmentMembership {
  const ApartmentMembershipModel({
    required super.id,
    required super.apartmentId,
    required super.residentId,
    required super.type,
    required super.startDate,
    required super.status,
    super.endDate,
    super.isPrimary,
  });

  factory ApartmentMembershipModel.fromMap(Map<String, Object?> map) {
    return ApartmentMembershipModel(
      id: map['id']! as String,
      apartmentId: map['apartmentId']! as String,
      residentId: map['residentId']! as String,
      type: MembershipType.values.byName(map['type']! as String),
      startDate: DateTime.parse(map['startDate']! as String),
      endDate: switch (map['endDate']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      status: MembershipStatus.values.byName(map['status']! as String),
      isPrimary: map['isPrimary'] as bool? ?? false,
    );
  }

  factory ApartmentMembershipModel.fromEntity(ApartmentMembership membership) {
    return ApartmentMembershipModel(
      id: membership.id,
      apartmentId: membership.apartmentId,
      residentId: membership.residentId,
      type: membership.type,
      startDate: membership.startDate,
      endDate: membership.endDate,
      status: membership.status,
      isPrimary: membership.isPrimary,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'apartmentId': apartmentId,
      'residentId': residentId,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'isPrimary': isPrimary,
    };
  }
}
