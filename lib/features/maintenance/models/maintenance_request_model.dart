import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';

class MaintenanceRequestModel extends MaintenanceRequest {
  const MaintenanceRequestModel({
    required super.id,
    required super.code,
    required super.apartmentId,
    required super.residentId,
    required super.title,
    required super.description,
    required super.location,
    required super.category,
    required super.priority,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.history,
    super.imageUrls,
    super.assignedTo,
    super.assignedToId,
  });

  factory MaintenanceRequestModel.fromMap(Map<String, Object?> map) {
    final historyValue = map['history'];
    final history = historyValue is List
        ? historyValue
              .whereType<Map>()
              .map((item) {
                final value = Map<String, Object?>.from(item);
                return MaintenanceUpdate(
                  id: value['id']! as String,
                  status: MaintenanceStatus.values.byName(
                    value['status']! as String,
                  ),
                  note: value['note'] as String? ?? '',
                  actorName: value['actorName']! as String,
                  createdAt: DateTime.parse(value['createdAt']! as String),
                );
              })
              .toList(growable: false)
        : const <MaintenanceUpdate>[];
    return MaintenanceRequestModel(
      id: map['id']! as String,
      code: map['code']! as String,
      apartmentId: map['apartmentId']! as String,
      residentId: map['residentId']! as String,
      title: map['title']! as String,
      description: map['description']! as String,
      location: map['location'] as String? ?? '',
      category: MaintenanceCategory.values.byName(map['category']! as String),
      priority: MaintenancePriority.values.byName(map['priority']! as String),
      status: MaintenanceStatus.values.byName(map['status']! as String),
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
      assignedTo: map['assignedTo'] as String?,
      assignedToId: map['assignedToId'] as String?,
      imageUrls:
          (map['imageUrls'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      history: List<MaintenanceUpdate>.unmodifiable(history),
    );
  }

  factory MaintenanceRequestModel.fromEntity(MaintenanceRequest request) {
    return MaintenanceRequestModel(
      id: request.id,
      code: request.code,
      apartmentId: request.apartmentId,
      residentId: request.residentId,
      title: request.title,
      description: request.description,
      location: request.location,
      category: request.category,
      priority: request.priority,
      status: request.status,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      assignedTo: request.assignedTo,
      assignedToId: request.assignedToId,
      imageUrls: List<String>.unmodifiable(request.imageUrls),
      history: List<MaintenanceUpdate>.unmodifiable(request.history),
    );
  }
}
