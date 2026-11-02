import 'package:homie/features/apartments/models/apartment_status.dart';

class Apartment {
  const Apartment({
    required this.id,
    required this.code,
    required this.buildingName,
    required this.floor,
    required this.area,
    required this.bedrooms,
    required this.status,
  });

  final String id;
  final String code;
  final String buildingName;
  final int floor;
  final double area;
  final int bedrooms;
  final ApartmentStatus status;

  Apartment copyWith({
    String? id,
    String? code,
    String? buildingName,
    int? floor,
    double? area,
    int? bedrooms,
    ApartmentStatus? status,
  }) {
    return Apartment(
      id: id ?? this.id,
      code: code ?? this.code,
      buildingName: buildingName ?? this.buildingName,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Apartment &&
            other.id == id &&
            other.code == code &&
            other.buildingName == buildingName &&
            other.floor == floor &&
            other.area == area &&
            other.bedrooms == bedrooms &&
            other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, code, buildingName, floor, area, bedrooms, status);
  }
}
