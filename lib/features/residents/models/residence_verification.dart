import 'package:homie/features/residents/models/membership_type.dart';

enum ResidenceVerificationState {
  notSubmitted,
  pending,
  approved,
  rejected;

  static ResidenceVerificationState fromValue(Object? value) {
    return switch (value?.toString()) {
      'pending' => pending,
      'approved' => approved,
      'rejected' => rejected,
      _ => notSubmitted,
    };
  }
}

class ResidenceVerification {
  const ResidenceVerification({
    required this.state,
    this.id,
    this.userId,
    this.apartmentId,
    this.apartmentCode,
    this.buildingName,
    this.fullName,
    this.email,
    this.phone,
    this.type,
    this.startDate,
    this.verificationBasis,
    this.note,
    this.reviewNote,
    this.createdAt,
    this.hasVerifiedOwner = false,
    this.hasActiveTenant = false,
  });

  final ResidenceVerificationState state;
  final String? id;
  final String? userId;
  final String? apartmentId;
  final String? apartmentCode;
  final String? buildingName;
  final String? fullName;
  final String? email;
  final String? phone;
  final MembershipType? type;
  final DateTime? startDate;
  final String? verificationBasis;
  final String? note;
  final String? reviewNote;
  final DateTime? createdAt;
  final bool hasVerifiedOwner;
  final bool hasActiveTenant;

  bool get canSubmit =>
      state == ResidenceVerificationState.notSubmitted ||
      state == ResidenceVerificationState.rejected;

  factory ResidenceVerification.fromMyResponse(Map<String, Object?> map) {
    final state = ResidenceVerificationState.fromValue(map['state']);
    final nested = state == ResidenceVerificationState.approved
        ? map['membership']
        : map['request'];
    if (nested is! Map) return ResidenceVerification(state: state);
    return ResidenceVerification.fromRequest(
      Map<String, Object?>.from(nested),
      state: state,
    );
  }

  factory ResidenceVerification.fromRequest(
    Map<String, Object?> map, {
    ResidenceVerificationState? state,
  }) {
    final apartment = map['apartment'] is Map
        ? Map<String, Object?>.from(map['apartment']! as Map)
        : const <String, Object?>{};
    final user = map['user'] is Map
        ? Map<String, Object?>.from(map['user']! as Map)
        : const <String, Object?>{};
    final privacy = map['privacy'] is Map
        ? Map<String, Object?>.from(map['privacy']! as Map)
        : const <String, Object?>{};
    return ResidenceVerification(
      state: state ?? ResidenceVerificationState.fromValue(map['status']),
      id: map['id']?.toString(),
      userId: (map['userId'] ?? user['id'])?.toString(),
      apartmentId: (map['apartmentId'] ?? apartment['id'])?.toString(),
      apartmentCode: apartment['code']?.toString(),
      buildingName: apartment['buildingName']?.toString(),
      fullName: user['fullName']?.toString(),
      email: user['email']?.toString(),
      phone: user['phone']?.toString(),
      type: _typeFromValue(map['type']),
      startDate: _dateFromValue(map['startDate']),
      verificationBasis: map['verificationBasis']?.toString(),
      note: map['note']?.toString(),
      reviewNote: map['reviewNote']?.toString(),
      createdAt: _dateFromValue(map['createdAt']),
      hasVerifiedOwner: privacy['hasVerifiedOwner'] == true,
      hasActiveTenant: privacy['hasActiveTenant'] == true,
    );
  }

  static MembershipType? _typeFromValue(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'owner' => MembershipType.owner,
      'tenant' => MembershipType.tenant,
      _ => null,
    };
  }

  static DateTime? _dateFromValue(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
