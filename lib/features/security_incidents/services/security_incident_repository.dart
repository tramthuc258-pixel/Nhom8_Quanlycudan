import '../models/security_incident.dart';
import '../models/security_incident_status.dart';
import '../models/security_incident_type.dart';

import 'package:homie/core/models/work_assignee.dart';

abstract interface class SecurityIncidentRepository {
  Future<List<SecurityIncident>> getIncidents();
  Future<SecurityIncident> create({
    required String apartmentId,
    required SecurityIncidentType type,
    required String title,
    required String description,
    required String location,
    required DateTime occurredAt,
  });
  Future<SecurityIncident> update({
    required String id,
    required SecurityIncidentStatus status,
    required String note,
  });
  Future<List<WorkAssignee>> getAssignees(String id);
  Future<SecurityIncident> assign({
    required String id,
    required String assigneeId,
  });
}
