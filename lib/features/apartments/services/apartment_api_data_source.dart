import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/models/apartment_model.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';

import 'apartment_data_source.dart';

class ApartmentApiDataSource implements ApartmentDataSource {
  const ApartmentApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ApartmentModel>> getApartments() async {
    try {
      final response = await _apiClient.get('/apartments');
      final items = response['items'];
      if (items is! List) throw StateError('Dữ liệu căn hộ không hợp lệ.');
      return items
          .whereType<Map>()
          .map(
            (item) => ApartmentModel.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ApartmentModel> createApartment({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  }) async {
    try {
      final response = await _apiClient.post(
        '/apartments',
        body: _body(
          code: code,
          buildingName: buildingName,
          floor: floor,
          area: area,
          bedrooms: bedrooms,
          status: status,
        ),
      );
      return ApartmentModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ApartmentModel> updateApartment(Apartment apartment) async {
    try {
      final response = await _apiClient.patch(
        '/apartments/${apartment.id}',
        body: _body(
          code: apartment.code,
          buildingName: apartment.buildingName,
          floor: apartment.floor,
          area: apartment.area,
          bedrooms: apartment.bedrooms,
          status: apartment.status,
        ),
      );
      return ApartmentModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<void> deleteApartment(String apartmentId) async {
    try {
      await _apiClient.delete('/apartments/$apartmentId');
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<ApartmentModel> updateStatus(
    String apartmentId,
    ApartmentStatus status,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/apartments/$apartmentId/status',
        body: <String, Object?>{'status': _statusToApi(status)},
      );
      return ApartmentModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  Map<String, Object?> _body({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  }) {
    return <String, Object?>{
      'code': code,
      'buildingName': buildingName,
      'floor': floor,
      'area': area,
      'bedrooms': bedrooms,
      'status': _statusToApi(status),
    };
  }

  String _statusToApi(ApartmentStatus status) {
    return switch (status) {
      ApartmentStatus.occupied => 'OCCUPIED',
      ApartmentStatus.vacant => 'VACANT',
      ApartmentStatus.underMaintenance => 'UNDER_MAINTENANCE',
    };
  }
}
