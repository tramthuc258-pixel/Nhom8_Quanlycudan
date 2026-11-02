import 'package:homie/features/resident_services/models/service_booking_status.dart';

class ServiceBookingUpdate {
  const ServiceBookingUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.actorName,
    required this.createdAt,
  });

  final String id;
  final ServiceBookingStatus status;
  final String note;
  final String actorName;
  final DateTime createdAt;

  factory ServiceBookingUpdate.fromMap(Map<String, Object?> map) {
    return ServiceBookingUpdate(
      id: map['id']! as String,
      status: ServiceBookingStatus.values.byName(map['status']! as String),
      note: map['note'] as String? ?? '',
      actorName: map['actorName'] as String? ?? 'Hệ thống',
      createdAt: DateTime.parse(map['createdAt']! as String).toLocal(),
    );
  }
}
