import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/models/apartment_model.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';

abstract interface class ApartmentDataSource {
  Future<List<ApartmentModel>> getApartments();

  Future<ApartmentModel> createApartment({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  });

  Future<ApartmentModel> updateApartment(Apartment apartment);

  Future<void> deleteApartment(String apartmentId);

  Future<ApartmentModel> updateStatus(
    String apartmentId,
    ApartmentStatus status,
  );
}
