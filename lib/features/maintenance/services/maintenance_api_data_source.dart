import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_request_model.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/core/models/work_assignee.dart';

import 'maintenance_data_source.dart';

class MaintenanceApiDataSource implements MaintenanceDataSource {
  const MaintenanceApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<MaintenanceRequestModel>> getRequests() async {
    try {
      final response = await _apiClient.get('/maintenance-requests');
      final items = response['items'];
      if (items is! List) {
        throw StateError('Dữ liệu yêu cầu sửa chữa không hợp lệ.');
      }
      return items
          .whereType<Map>()
          .map(
            (item) => MaintenanceRequestModel.fromMap(
              Map<String, Object?>.from(item),
            ),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<WorkAssignee>> getAssignees(String requestId) async {
    try {
      final response = await _apiClient.get(
        '/maintenance-requests/$requestId/assignees',
      );
      final items = response['items'];
      if (items is! List) {
        throw StateError('Danh sách kỹ thuật viên không hợp lệ.');
      }
      return items
          .whereType<Map>()
          .map((item) => WorkAssignee.fromMap(Map<String, Object?>.from(item)))
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<MaintenanceRequestModel> createRequest({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required String title,
    required String description,
    required String location,
    required MaintenanceCategory category,
    required MaintenancePriority priority,
    List<String> imageUrls = const <String>[],
  }) async {
    try {
      final response = await _apiClient.post(
        '/maintenance-requests',
        body: <String, Object?>{
          'apartmentId': apartmentId,
          'title': title,
          'description': description,
          'location': location,
          'category': _enumToApi(category.name),
          'priority': _enumToApi(priority.name),
          'imageUrls': imageUrls,
        },
      );
      return MaintenanceRequestModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<MaintenanceRequestModel> assignRequest({
    required String requestId,
    required String assigneeId,
    required String assigneeName,
    required String actorName,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/maintenance-requests/$requestId/assign',
        body: <String, Object?>{'assigneeId': assigneeId},
      );
      return MaintenanceRequestModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<MaintenanceRequestModel> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
    required String note,
    required String actorName,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/maintenance-requests/$requestId/status',
        body: <String, Object?>{
          'status': _enumToApi(status.name),
          'note': note,
        },
      );
      return MaintenanceRequestModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<MaintenanceRequestModel> respondToResult({
    required String requestId,
    required bool confirmed,
    required String note,
    required String actorName,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/maintenance-requests/$requestId/resident-response',
        body: <String, Object?>{
          'decision': confirmed ? 'CONFIRM' : 'REOPEN',
          'note': note,
        },
      );
      return MaintenanceRequestModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  String _enumToApi(String name) {
    return name
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toUpperCase();
  }
}
