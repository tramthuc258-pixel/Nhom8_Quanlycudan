import 'package:homie/features/maintenance/models/maintenance_status.dart';

class MaintenanceUpdate {
  const MaintenanceUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.actorName,
    required this.createdAt,
  });

  final String id;
  final MaintenanceStatus status;
  final String note;
  final String actorName;
  final DateTime createdAt;
}
