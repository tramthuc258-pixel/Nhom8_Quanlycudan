import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_request_model.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/core/models/work_assignee.dart';

abstract interface class MaintenanceDataSource {
  Future<List<MaintenanceRequestModel>> getRequests();

  Future<List<WorkAssignee>> getAssignees(String requestId);

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
  });

  Future<MaintenanceRequestModel> assignRequest({
    required String requestId,
    required String assigneeId,
    required String assigneeName,
    required String actorName,
  });

  Future<MaintenanceRequestModel> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
    required String note,
    required String actorName,
  });

  Future<MaintenanceRequestModel> respondToResult({
    required String requestId,
    required bool confirmed,
    required String note,
    required String actorName,
  });
}
