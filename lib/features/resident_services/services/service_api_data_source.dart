import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/resident_services/models/resident_service_model.dart';
import 'package:homie/features/resident_services/models/service_booking_model.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/core/models/work_assignee.dart';

import 'service_data_source.dart';

class ServiceApiDataSource implements ServiceDataSource {
  const ServiceApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ResidentServiceModel>> getServices() async {
    try {
      final response = await _apiClient.get('/resident-services/catalog');
      return _readItems(response)
          .map(ResidentServiceModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<ServiceBookingModel>> getBookings() async {
    try {
      final response = await _apiClient.get('/resident-services/requests');
      return _readItems(response)
          .map(ServiceBookingModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<WorkAssignee>> getAssignees(String bookingId) async {
    try {
      final response = await _apiClient.get(
        '/resident-services/requests/$bookingId/assignees',
      );
      return _readItems(response)
          .map(WorkAssignee.fromMap)
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ServiceBookingModel> createBooking({
    required String serviceId,
    required String apartmentId,
    required String residentId,
    required String residentName,
    required int quantity,
    required DateTime scheduledAt,
    required String note,
  }) async {
    try {
      final response = await _apiClient.post(
        '/resident-services/requests',
        body: <String, Object?>{
          'serviceId': serviceId,
          'apartmentId': apartmentId,
          'quantity': quantity,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          'note': note,
        },
      );
      return ServiceBookingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ServiceBookingModel> cancelBooking(String bookingId) async {
    try {
      final response = await _apiClient.patch(
        '/resident-services/requests/$bookingId/cancel',
      );
      return ServiceBookingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ServiceBookingModel> assignBooking({
    required String bookingId,
    required String assigneeId,
    required String assigneeName,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/resident-services/requests/$bookingId/assign',
        body: <String, Object?>{'assigneeId': assigneeId},
      );
      return ServiceBookingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ServiceBookingModel> updateBookingStatus({
    required String bookingId,
    required ServiceBookingStatus status,
    required String note,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/resident-services/requests/$bookingId/status',
        body: <String, Object?>{
          'status': _enumToApi(status.name),
          'note': note,
        },
      );
      return ServiceBookingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ServiceBookingModel> respondToResult({
    required String bookingId,
    required bool confirmed,
    required String note,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/resident-services/requests/$bookingId/resident-response',
        body: <String, Object?>{
          'decision': confirmed ? 'CONFIRM' : 'REOPEN',
          'note': note,
        },
      );
      return ServiceBookingModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ResidentServiceModel> toggleServiceActive(String serviceId) async {
    try {
      final response = await _apiClient.patch(
        '/resident-services/catalog/$serviceId/toggle-active',
      );
      return ResidentServiceModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  Iterable<Map<String, Object?>> _readItems(Map<String, dynamic> response) {
    final items = response['items'];
    if (items is! List) {
      throw StateError('Dữ liệu dịch vụ cư dân không hợp lệ.');
    }
    return items.whereType<Map>().map(Map<String, Object?>.from);
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
