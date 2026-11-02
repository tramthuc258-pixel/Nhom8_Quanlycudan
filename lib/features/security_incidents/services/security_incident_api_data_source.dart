import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';

import '../models/security_incident.dart';
import '../models/security_incident_status.dart';
import '../models/security_incident_type.dart';
import 'security_incident_repository.dart';

import 'package:homie/core/models/work_assignee.dart';

class SecurityIncidentApiDataSource implements SecurityIncidentRepository {
  const SecurityIncidentApiDataSource(this._client);
  final ApiClient _client;
  @override
  Future<List<SecurityIncident>> getIncidents() async {
    try {
      final response = await _client.get('/security-incidents');
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu sự cố không hợp lệ.');
      return items
          .whereType<Map>()
          .map((e) => SecurityIncident.fromMap(Map<String, Object?>.from(e)))
          .toList(growable: false);
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  @override
  Future<SecurityIncident> create({
    required String apartmentId,
    required SecurityIncidentType type,
    required String title,
    required String description,
    required String location,
    required DateTime occurredAt,
  }) async {
    try {
      return SecurityIncident.fromMap(
        await _client.post(
          '/security-incidents',
          body: {
            'apartmentId': apartmentId,
            'type': _api(type.name),
            'title': title,
            'description': description,
            'location': location,
            'occurredAt': occurredAt.toUtc().toIso8601String(),
          },
        ),
      );
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  @override
  Future<SecurityIncident> update({
    required String id,
    required SecurityIncidentStatus status,
    required String note,
  }) async {
    try {
      return SecurityIncident.fromMap(
        await _client.patch(
          '/security-incidents/$id/status',
          body: {'status': _api(status.name), 'resolutionNote': note},
        ),
      );
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  @override
  Future<List<WorkAssignee>> getAssignees(String id) async {
    try {
      final response = await _client.get('/security-incidents/$id/assignees');
      final items = response['items'];
      if (items is! List) throw StateError('Danh sách bảo vệ không hợp lệ.');
      return items
          .whereType<Map>()
          .map((item) => WorkAssignee.fromMap(Map<String, Object?>.from(item)))
          .toList(growable: false);
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  @override
  Future<SecurityIncident> assign({
    required String id,
    required String assigneeId,
  }) async {
    try {
      return SecurityIncident.fromMap(
        await _client.patch(
          '/security-incidents/$id/assign',
          body: {'assigneeId': assigneeId},
        ),
      );
    } on ApiException catch (e) {
      throw StateError(e.message);
    }
  }

  String _api(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m.group(1)}_${m.group(2)}',
      )
      .toUpperCase();
}
