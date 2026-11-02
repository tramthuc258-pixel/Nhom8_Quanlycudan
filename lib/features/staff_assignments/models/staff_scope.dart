class BuildingScope {
  const BuildingScope({
    required this.id,
    required this.code,
    required this.name,
    this.assignmentId,
    this.isActive = true,
  });

  factory BuildingScope.fromMap(Map<String, dynamic> map) => BuildingScope(
    id: map['id']! as String,
    code: map['code']! as String,
    name: map['name']! as String,
    assignmentId: map['assignmentId'] as String?,
    isActive: map['isActive'] as bool? ?? true,
  );

  final String id;
  final String code;
  final String name;
  final String? assignmentId;
  final bool isActive;
}

class StaffScope {
  const StaffScope({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roles,
    required this.buildings,
    required this.status,
    required this.mustChangePassword,
  });

  factory StaffScope.fromMap(Map<String, dynamic> map) => StaffScope(
    id: map['id']! as String,
    fullName: map['fullName']! as String,
    email: map['email']! as String,
    roles: (map['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    buildings: (map['buildings'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BuildingScope.fromMap)
        .toList(growable: false),
    status: map['status'] as String? ?? 'ACTIVE',
    mustChangePassword: map['mustChangePassword'] as bool? ?? false,
  );

  final String id;
  final String fullName;
  final String email;
  final List<String> roles;
  final List<BuildingScope> buildings;
  final String status;
  final bool mustChangePassword;

  bool get isActive => status == 'ACTIVE';
}

class StaffInvitationResult {
  const StaffInvitationResult({
    required this.emailDelivered,
    this.temporaryPassword,
  });

  final bool emailDelivered;
  final String? temporaryPassword;
}
