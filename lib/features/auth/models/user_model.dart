import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/auth/models/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.apartmentCode,
    super.phoneNumber,
    super.dateOfBirth,
    super.contactAddress,
    super.avatarUrl,
    super.mustChangePassword,
  });

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id']! as String,
      fullName: map['fullName']! as String,
      email: map['email']! as String,
      role: UserRole.values.byName(map['role']! as String),
      apartmentCode: map['apartmentCode'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      dateOfBirth: map['dateOfBirth'] == null
          ? null
          : DateTime.tryParse(map['dateOfBirth']! as String),
      contactAddress: map['contactAddress'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
    );
  }

  factory UserModel.fromApiMap(Map<String, dynamic> map) {
    final roles = (map['roles'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toSet();

    return UserModel(
      id: map['id']! as String,
      fullName: map['fullName']! as String,
      email: map['email']! as String,
      role: _roleFromApi(roles),
      apartmentCode: map['apartmentCode'] as String?,
      phoneNumber: map['phone'] as String?,
      dateOfBirth: map['dateOfBirth'] == null
          ? null
          : DateTime.tryParse(map['dateOfBirth']! as String),
      contactAddress: map['contactAddress'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
    );
  }

  static UserRole _roleFromApi(Set<String> roles) {
    const priority = <(String, UserRole)>[
      ('ADMIN', UserRole.admin),
      ('MANAGEMENT', UserRole.manager),
      ('ACCOUNTANT', UserRole.accountant),
      ('RECEPTIONIST', UserRole.receptionist),
      ('SECURITY', UserRole.security),
      ('TECHNICIAN', UserRole.technician),
      ('RESIDENT', UserRole.resident),
    ];
    for (final item in priority) {
      if (roles.contains(item.$1)) return item.$2;
    }
    return UserRole.resident;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'apartmentCode': apartmentCode,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'contactAddress': contactAddress,
      'avatarUrl': avatarUrl,
      'mustChangePassword': mustChangePassword,
    };
  }
}
