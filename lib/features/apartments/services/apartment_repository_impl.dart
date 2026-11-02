import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/services/apartment_repository.dart';
import 'package:homie/features/apartments/services/apartment_data_source.dart';

class ApartmentRepositoryImpl implements ApartmentRepository {
  const ApartmentRepositoryImpl(this._dataSource);

  final ApartmentDataSource _dataSource;

  @override
  Future<List<Apartment>> getApartments() async {
    final apartments = await _dataSource.getApartments();
    return List<Apartment>.unmodifiable(apartments);
  }

  @override
  Future<Apartment> createApartment({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  }) {
    return _dataSource.createApartment(
      code: code,
      buildingName: buildingName,
      floor: floor,
      area: area,
      bedrooms: bedrooms,
      status: status,
    );
  }

  @override
  Future<Apartment> updateApartment(Apartment apartment) {
    return _dataSource.updateApartment(apartment);
  }

  @override
  Future<void> deleteApartment(String apartmentId) {
    return _dataSource.deleteApartment(apartmentId);
  }

  @override
  Future<Apartment> updateStatus(String apartmentId, ApartmentStatus status) {
    return _dataSource.updateStatus(apartmentId, status);
  }
}
