import 'package:flutter/foundation.dart';

import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/maintenance/services/maintenance_repository.dart';
import 'package:homie/core/models/work_assignee.dart';

class MaintenanceController extends ChangeNotifier {
  MaintenanceController({required this.repository});

  final MaintenanceRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<MaintenanceRequest> _requests = const <MaintenanceRequest>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MaintenanceRequest> get requests => _requests;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _refresh();
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  MaintenanceRequest? requestById(String id) {
    for (final request in _requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  List<MaintenanceRequest> requestsForResident(String residentId) {
    return List<MaintenanceRequest>.unmodifiable(
      _requests.where((request) => request.residentId == residentId),
    );
  }

  int openCountForResident(String residentId) =>
      requestsForResident(residentId).where((request) => request.isOpen).length;

  Future<List<WorkAssignee>> getAssignees(String requestId) =>
      repository.getAssignees(requestId);

  Future<bool> createRequest({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required String title,
    required String description,
    required String location,
    required MaintenanceCategory category,
    required MaintenancePriority priority,
    List<String> imageUrls = const <String>[],
  }) => _mutate(
    () => repository.createRequest(
      apartmentId: apartmentId,
      residentId: residentId,
      residentName: residentName,
      title: title,
      description: description,
      location: location,
      category: category,
      priority: priority,
      imageUrls: imageUrls,
    ),
  );

  Future<bool> assignRequest({
    required String requestId,
    required String assigneeId,
    required String assigneeName,
    required String actorName,
  }) => _mutate(
    () => repository.assignRequest(
      requestId: requestId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      actorName: actorName,
    ),
  );

  Future<bool> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
    required String note,
    required String actorName,
  }) => _mutate(
    () => repository.updateStatus(
      requestId: requestId,
      status: status,
      note: note,
      actorName: actorName,
    ),
  );

  Future<bool> respondToResult({
    required String requestId,
    required bool confirmed,
    required String note,
    required String actorName,
  }) => _mutate(
    () => repository.respondToResult(
      requestId: requestId,
      confirmed: confirmed,
      note: note,
      actorName: actorName,
    ),
  );

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _mutate(Future<MaintenanceRequest> Function() action) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final changed = await action();
      final items = List<MaintenanceRequest>.from(
        _requests.where((request) => request.id != changed.id),
      )..add(changed);
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _requests = List<MaintenanceRequest>.unmodifiable(items);
      // The mutation already succeeded. A failed follow-up list refresh must
      // not make the resident or manager think the request was rejected.
      try {
        await _refresh();
      } catch (_) {
        // Keep the confirmed server response until the next manual refresh.
      }
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    final items = List<MaintenanceRequest>.from(await repository.getRequests())
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _requests = List<MaintenanceRequest>.unmodifiable(items);
  }

  String _messageFor(Object error) => switch (error) {
    StateError(message: final message) => message,
    ArgumentError(message: final Object? message) =>
      message?.toString() ?? 'Dữ liệu yêu cầu không hợp lệ.',
    _ => 'Không thể cập nhật yêu cầu. Vui lòng thử lại.',
  };
}
