import 'package:homie/core/enums/user_role.dart';

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.apartmentCode,
    this.phoneNumber,
    this.dateOfBirth,
    this.contactAddress,
    this.avatarUrl,
    this.mustChangePassword = false,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? apartmentCode;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? contactAddress;
  final String? avatarUrl;
  final bool mustChangePassword;

  User copyWith({
    String? fullName,
    String? email,
    String? apartmentCode,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? contactAddress,
    String? avatarUrl,
    bool? mustChangePassword,
  }) => User(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    role: role,
    apartmentCode: apartmentCode ?? this.apartmentCode,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    contactAddress: contactAddress ?? this.contactAddress,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is User &&
            other.id == id &&
            other.fullName == fullName &&
            other.email == email &&
            other.role == role &&
            other.apartmentCode == apartmentCode &&
            other.phoneNumber == phoneNumber &&
            other.dateOfBirth == dateOfBirth &&
            other.contactAddress == contactAddress &&
            other.avatarUrl == avatarUrl &&
            other.mustChangePassword == mustChangePassword;
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    email,
    role,
    apartmentCode,
    phoneNumber,
    dateOfBirth,
    contactAddress,
    avatarUrl,
    mustChangePassword,
  );
}
