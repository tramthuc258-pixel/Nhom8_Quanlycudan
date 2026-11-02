import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_booking_update.dart';

class ServiceBookingModel extends ServiceBooking {
  const ServiceBookingModel({
    required super.id,
    required super.code,
    required super.serviceId,
    required super.serviceName,
    required super.unitPrice,
    required super.apartmentId,
    required super.residentId,
    required super.residentName,
    required super.quantity,
    required super.scheduledAt,
    required super.note,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.assignedTo,
    super.assignedToId,
    super.managementNote,
    super.invoiceId,
    super.invoiceCode,
    super.history,
  });

  factory ServiceBookingModel.fromMap(Map<String, Object?> map) {
    return ServiceBookingModel(
      id: map['id']! as String,
      code: map['code']! as String,
      serviceId: map['serviceId']! as String,
      serviceName: map['serviceName']! as String,
      unitPrice: (map['unitPrice']! as num).toDouble(),
      apartmentId: map['apartmentId']! as String,
      residentId: map['residentId']! as String,
      residentName: map['residentName']! as String,
      quantity: (map['quantity']! as num).toInt(),
      scheduledAt: DateTime.parse(map['scheduledAt']! as String).toLocal(),
      note: map['note'] as String? ?? '',
      status: ServiceBookingStatus.values.byName(map['status']! as String),
      createdAt: DateTime.parse(map['createdAt']! as String).toLocal(),
      updatedAt: DateTime.parse(map['updatedAt']! as String).toLocal(),
      assignedTo: map['assignedTo'] as String?,
      assignedToId: map['assignedToId'] as String?,
      managementNote: map['managementNote'] as String?,
      invoiceId: map['invoiceId'] as String?,
      invoiceCode: map['invoiceCode'] as String?,
      history: (map['history'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map(
            (item) =>
                ServiceBookingUpdate.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false),
    );
  }

  factory ServiceBookingModel.fromEntity(ServiceBooking booking) {
    return ServiceBookingModel(
      id: booking.id,
      code: booking.code,
      serviceId: booking.serviceId,
      serviceName: booking.serviceName,
      unitPrice: booking.unitPrice,
      apartmentId: booking.apartmentId,
      residentId: booking.residentId,
      residentName: booking.residentName,
      quantity: booking.quantity,
      scheduledAt: booking.scheduledAt,
      note: booking.note,
      status: booking.status,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
      assignedTo: booking.assignedTo,
      assignedToId: booking.assignedToId,
      managementNote: booking.managementNote,
      invoiceId: booking.invoiceId,
      invoiceCode: booking.invoiceCode,
      history: booking.history,
    );
  }
}
