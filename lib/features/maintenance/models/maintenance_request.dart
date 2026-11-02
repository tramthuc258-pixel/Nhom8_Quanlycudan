import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';

import 'maintenance_update.dart';

export 'maintenance_update.dart';

class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.code,
    required this.apartmentId,
    required this.residentId,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    this.imageUrls = const <String>[],
    this.assignedTo,
    this.assignedToId,
  });

  final String id;
  final String code;
  final String apartmentId;
  final String residentId;
  final String title;
  final String description;
  final String location;
  final MaintenanceCategory category;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo;
  final String? assignedToId;
  final List<String> imageUrls;
  final List<MaintenanceUpdate> history;

  bool get isOpen => status.isOpen;

  MaintenanceRequest copyWith({
    MaintenanceStatus? status,
    DateTime? updatedAt,
    String? assignedTo,
    bool clearAssignedTo = false,
    String? assignedToId,
    List<MaintenanceUpdate>? history,
  }) {
    return MaintenanceRequest(
      id: id,
      code: code,
      apartmentId: apartmentId,
      residentId: residentId,
      title: title,
      description: description,
      location: location,
      category: category,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: clearAssignedTo ? null : assignedTo ?? this.assignedTo,
      assignedToId: clearAssignedTo ? null : assignedToId ?? this.assignedToId,
      imageUrls: imageUrls,
      history: List<MaintenanceUpdate>.unmodifiable(history ?? this.history),
    );
  }
}
