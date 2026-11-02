import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/maintenance/services/maintenance_repository.dart';
import 'package:homie/features/maintenance/services/maintenance_data_source.dart';
import 'package:homie/core/models/work_assignee.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  const MaintenanceRepositoryImpl(this._dataSource);

  final MaintenanceDataSource _dataSource;

  @override
  Future<List<MaintenanceRequest>> getRequests() => _dataSource.getRequests();

  @override
  Future<List<WorkAssignee>> getAssignees(String requestId) =>
      _dataSource.getAssignees(requestId);

  @override
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
  }) => _dataSource.createRequest(
    apartmentId: apartmentId,
    residentId: residentId,
    residentName: residentName,
    title: title,
    description: description,
    location: location,
    category: category,
    priority: priority,
    imageUrls: imageUrls,
  );

  @override
  Future<MaintenanceRequest> assignRequest({
    required String requestId,
    required String assigneeId,
    required String assigneeName,
    required String actorName,
  }) => _dataSource.assignRequest(
    requestId: requestId,
    assigneeId: assigneeId,
    assigneeName: assigneeName,
    actorName: actorName,
  );

  @override
  Future<MaintenanceRequest> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
    required String note,
    required String actorName,
  }) => _dataSource.updateStatus(
    requestId: requestId,
    status: status,
    note: note,
    actorName: actorName,
  );

  @override
  Future<MaintenanceRequest> respondToResult({
    required String requestId,
    required bool confirmed,
    required String note,
    required String actorName,
  }) => _dataSource.respondToResult(
    requestId: requestId,
    confirmed: confirmed,
    note: note,
    actorName: actorName,
  );
}
