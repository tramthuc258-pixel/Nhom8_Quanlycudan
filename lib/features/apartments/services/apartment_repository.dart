import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';

abstract interface class ApartmentRepository {
  Future<List<Apartment>> getApartments();

  Future<Apartment> createApartment({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  });

  Future<Apartment> updateApartment(Apartment apartment);

  Future<void> deleteApartment(String apartmentId);

  Future<Apartment> updateStatus(String apartmentId, ApartmentStatus status);
}
