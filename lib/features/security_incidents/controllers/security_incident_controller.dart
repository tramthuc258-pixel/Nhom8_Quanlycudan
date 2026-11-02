import 'package:flutter/foundation.dart';

import '../models/security_incident.dart';
import '../models/security_incident_status.dart';
import '../models/security_incident_type.dart';
import '../services/security_incident_repository.dart';

import 'package:homie/core/models/work_assignee.dart';

class SecurityIncidentController extends ChangeNotifier {
  SecurityIncidentController({required this.repository});
  final SecurityIncidentRepository repository;
  bool isLoading = false;
  String? errorMessage;
  List<SecurityIncident> incidents = const [];
  Future<void> load() => _run(() async {
    incidents = List.unmodifiable(await repository.getIncidents());
  });
  Future<bool> create({
    required String apartmentId,
    required SecurityIncidentType type,
    required String title,
    required String description,
    required String location,
    required DateTime occurredAt,
  }) => _mutate(
    () => repository.create(
      apartmentId: apartmentId,
      type: type,
      title: title,
      description: description,
      location: location,
      occurredAt: occurredAt,
    ),
  );
  Future<bool> update({
    required String id,
    required SecurityIncidentStatus status,
    required String note,
  }) => _mutate(() => repository.update(id: id, status: status, note: note));
  Future<List<WorkAssignee>> getAssignees(String id) =>
      repository.getAssignees(id);
  Future<bool> assign({required String id, required String assigneeId}) =>
      _mutate(() => repository.assign(id: id, assigneeId: assigneeId));
  Future<bool> _mutate(Future<Object> Function() action) async {
    var ok = true;
    await _run(() async {
      await action();
      incidents = List.unmodifiable(await repository.getIncidents());
    }, onError: () => ok = false);
    return ok;
  }

  Future<void> _run(
    Future<void> Function() action, {
    VoidCallback? onError,
  }) async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      errorMessage = e is StateError
          ? e.message
          : 'Không thể cập nhật sự cố an ninh.';
      onError?.call();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
