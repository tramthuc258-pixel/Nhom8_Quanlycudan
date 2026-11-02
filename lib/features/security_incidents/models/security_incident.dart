import 'security_incident_status.dart';
import 'security_incident_type.dart';

class SecurityIncidentUpdate {
  const SecurityIncidentUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.actorName,
    required this.createdAt,
  });
  final String id;
  final SecurityIncidentStatus status;
  final String note;
  final String actorName;
  final DateTime createdAt;
}

class SecurityIncident {
  const SecurityIncident({
    required this.id,
    required this.code,
    required this.buildingName,
    required this.reportedById,
    required this.reportedByName,
    required this.type,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.apartmentId,
    this.apartmentCode,
    this.location,
    this.resolutionNote,
    this.resolvedByName,
    this.assignedToId,
    this.assignedToName,
    this.assignedByName,
    this.assignedAt,
    this.history = const [],
  });
  final String id,
      code,
      buildingName,
      reportedById,
      reportedByName,
      title,
      description;
  final String? apartmentId,
      apartmentCode,
      location,
      resolutionNote,
      resolvedByName;
  final String? assignedToId, assignedToName, assignedByName;
  final DateTime? assignedAt;
  final List<SecurityIncidentUpdate> history;
  final SecurityIncidentType type;
  final SecurityIncidentStatus status;
  final DateTime occurredAt, createdAt, updatedAt;
  factory SecurityIncident.fromMap(Map<String, Object?> map) =>
      SecurityIncident(
        id: map['id']! as String,
        code: map['code']! as String,
        buildingName: map['buildingName']! as String,
        apartmentId: map['apartmentId'] as String?,
        apartmentCode: map['apartmentCode'] as String?,
        reportedById: map['reportedById']! as String,
        reportedByName: map['reportedByName']! as String,
        type: SecurityIncidentType.values.byName(map['type']! as String),
        title: map['title']! as String,
        description: map['description']! as String,
        location: map['location'] as String?,
        occurredAt: DateTime.parse(map['occurredAt']! as String).toLocal(),
        status: SecurityIncidentStatus.values.byName(map['status']! as String),
        resolutionNote: map['resolutionNote'] as String?,
        resolvedByName: map['resolvedByName'] as String?,
        assignedToId: map['assignedToId'] as String?,
        assignedToName: map['assignedToName'] as String?,
        assignedByName: map['assignedByName'] as String?,
        assignedAt: map['assignedAt'] == null
            ? null
            : DateTime.parse(map['assignedAt']! as String).toLocal(),
        history: (map['history'] as List? ?? const [])
            .whereType<Map>()
            .map((item) {
              final value = Map<String, Object?>.from(item);
              return SecurityIncidentUpdate(
                id: value['id']! as String,
                status: SecurityIncidentStatus.values.byName(
                  value['status']! as String,
                ),
                note: value['note'] as String? ?? '',
                actorName: value['actorName'] as String? ?? 'Hệ thống',
                createdAt: DateTime.parse(value['createdAt']! as String)
                    .toLocal(),
              );
            })
            .toList(growable: false),
        createdAt: DateTime.parse(map['createdAt']! as String).toLocal(),
        updatedAt: DateTime.parse(map['updatedAt']! as String).toLocal(),
      );
}
