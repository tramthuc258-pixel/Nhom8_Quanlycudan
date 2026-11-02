import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_booking_update.dart';

class ServiceBooking {
  const ServiceBooking({
    required this.id,
    required this.code,
    required this.serviceId,
    required this.serviceName,
    required this.unitPrice,
    required this.apartmentId,
    required this.residentId,
    required this.residentName,
    required this.quantity,
    required this.scheduledAt,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.assignedToId,
    this.managementNote,
    this.invoiceId,
    this.invoiceCode,
    this.history = const <ServiceBookingUpdate>[],
  });

  final String id;
  final String code;
  final String serviceId;
  final String serviceName;
  final double unitPrice;
  final String apartmentId;
  final String residentId;
  final String residentName;
  final int quantity;
  final DateTime scheduledAt;
  final String note;
  final ServiceBookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo;
  final String? assignedToId;
  final String? managementNote;
  final String? invoiceId;
  final String? invoiceCode;
  final List<ServiceBookingUpdate> history;

  double get totalAmount => unitPrice * quantity;

  bool get isActive => status.isActive;

  ServiceBooking copyWith({
    ServiceBookingStatus? status,
    DateTime? updatedAt,
    String? assignedTo,
    bool clearAssignedTo = false,
    String? assignedToId,
    String? managementNote,
    bool clearManagementNote = false,
    List<ServiceBookingUpdate>? history,
  }) {
    return ServiceBooking(
      id: id,
      code: code,
      serviceId: serviceId,
      serviceName: serviceName,
      unitPrice: unitPrice,
      apartmentId: apartmentId,
      residentId: residentId,
      residentName: residentName,
      quantity: quantity,
      scheduledAt: scheduledAt,
      note: note,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: clearAssignedTo ? null : assignedTo ?? this.assignedTo,
      assignedToId: clearAssignedTo ? null : assignedToId ?? this.assignedToId,
      managementNote: clearManagementNote
          ? null
          : managementNote ?? this.managementNote,
      invoiceId: invoiceId,
      invoiceCode: invoiceCode,
      history: history ?? this.history,
    );
  }
}
