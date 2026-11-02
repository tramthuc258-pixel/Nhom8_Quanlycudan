class WorkAssignee {
  const WorkAssignee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roles,
  });

  factory WorkAssignee.fromMap(Map<String, Object?> map) => WorkAssignee(
    id: map['id']! as String,
    fullName: map['fullName']! as String,
    email: map['email']! as String,
    roles: (map['roles'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList(growable: false),
  );

  final String id;
  final String fullName;
  final String email;
  final List<String> roles;

  String get roleLabel {
    if (roles.contains('TECHNICIAN')) return 'Kỹ thuật viên';
    if (roles.contains('RECEPTIONIST')) return 'Lễ tân';
    return 'Nhân viên';
  }
}
