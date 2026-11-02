import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/core/models/work_assignee.dart';

abstract interface class MaintenanceRepository {
  Future<List<MaintenanceRequest>> getRequests();

  Future<List<WorkAssignee>> getAssignees(String requestId);

  Future<MaintenanceRequest> createRequest({
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

  Future<MaintenanceRequest> assignRequest({
    required String requestId,
    required String assigneeId,
    required String assigneeName,
    required String actorName,
  });

  Future<MaintenanceRequest> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
    required String note,
    required String actorName,
  });

  Future<MaintenanceRequest> respondToResult({
    required String requestId,
    required bool confirmed,
    required String note,
    required String actorName,
  });
}
