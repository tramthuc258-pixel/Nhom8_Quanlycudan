import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';

import '../models/temporary_stay.dart';
import '../models/temporary_stay_model.dart';
import 'temporary_stay_repository.dart';

class TemporaryStayApiDataSource implements TemporaryStayRepository {
  const TemporaryStayApiDataSource(this._client);
  final ApiClient _client;

  @override
  Future<List<TemporaryStay>> getStays() async {
    try {
      final response = await _client.get('/temporary-stays');
      final items = response['items'];
      if (items is! List) {
        throw StateError('Dữ liệu khách lưu trú không hợp lệ.');
      }
      return items
          .whereType<Map>()
          .map(
            (item) =>
                TemporaryStayModel.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<TemporaryStay> create({
    required String apartmentId,
    required String guestFullName,
    DateTime? guestDateOfBirth,
    String? guestPhone,
    String? relationshipToResident,
    required DateTime startDate,
    required DateTime endDate,
    String? purpose,
  }) async {
    try {
      return TemporaryStayModel.fromMap(
        await _client.post(
          '/temporary-stays',
          body: {
            'apartmentId': apartmentId,
            'guestFullName': guestFullName,
            if (guestDateOfBirth != null)
              'guestDateOfBirth': guestDateOfBirth.toUtc().toIso8601String(),
            'guestPhone': guestPhone,
            'relationshipToResident': relationshipToResident,
            'startDate': startDate.toUtc().toIso8601String(),
            'endDate': endDate.toUtc().toIso8601String(),
            'purpose': purpose,
          },
        ),
      );
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<TemporaryStay> cancel(String id) =>
      _patch('/temporary-stays/$id/cancel');
  @override
  Future<TemporaryStay> review({
    required String id,
    required bool approved,
    required String note,
  }) => _patch('/temporary-stays/$id/review', {
    'approved': approved,
    'note': note,
  });
  @override
  Future<TemporaryStay> checkIn(String id) =>
      _patch('/temporary-stays/$id/check-in');
  @override
  Future<TemporaryStay> checkOut(String id) =>
      _patch('/temporary-stays/$id/check-out');

  Future<TemporaryStay> _patch(
    String path, [
    Map<String, Object?>? body,
  ]) async {
    try {
      return TemporaryStayModel.fromMap(await _client.patch(path, body: body));
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }
}
