class AuditActor {
  const AuditActor({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory AuditActor.fromMap(Map<String, dynamic> map) => AuditActor(
    id: map['id'] as String? ?? '',
    fullName: map['fullName'] as String? ?? 'Không rõ',
    email: map['email'] as String? ?? '',
  );
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.resource,
    required this.path,
    required this.statusCode,
    required this.createdAt,
    required this.actor,
    this.targetId,
    this.metadata = const {},
  });

  final String id;
  final String action;
  final String resource;
  final String path;
  final int statusCode;
  final DateTime createdAt;
  final AuditActor actor;
  final String? targetId;
  final Map<String, dynamic> metadata;

  bool get succeeded => statusCode >= 200 && statusCode < 400;

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) => AuditLogEntry(
    id: map['id'] as String? ?? '',
    action: map['action'] as String? ?? '',
    resource: map['resource'] as String? ?? '',
    path: map['path'] as String? ?? '',
    statusCode: map['statusCode'] as int? ?? 0,
    targetId: map['targetId'] as String?,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    actor: AuditActor.fromMap(
      map['actor'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    ),
    metadata: map['metadata'] as Map<String, dynamic>? ?? const {},
  );
}
