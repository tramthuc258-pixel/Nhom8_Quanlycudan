class Resident {
  const Resident({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;

  Resident copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
  }) {
    return Resident(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Resident &&
            other.id == id &&
            other.fullName == fullName &&
            other.phone == phone &&
            other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, fullName, phone, email);
}
