import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';

class ApartmentModel extends Apartment {
  const ApartmentModel({
    required super.id,
    required super.code,
    required super.buildingName,
    required super.floor,
    required super.area,
    required super.bedrooms,
    required super.status,
  });

  factory ApartmentModel.fromMap(Map<String, Object?> map) {
    return ApartmentModel(
      id: map['id']! as String,
      code: map['code']! as String,
      buildingName: map['buildingName']! as String,
      floor: map['floor']! as int,
      area: (map['area']! as num).toDouble(),
      bedrooms: map['bedrooms']! as int,
      status: ApartmentStatus.fromValue(map['status']),
    );
  }

  factory ApartmentModel.fromEntity(Apartment apartment) {
    return ApartmentModel(
      id: apartment.id,
      code: apartment.code,
      buildingName: apartment.buildingName,
      floor: apartment.floor,
      area: apartment.area,
      bedrooms: apartment.bedrooms,
      status: apartment.status,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'code': code,
      'buildingName': buildingName,
      'floor': floor,
      'area': area,
      'bedrooms': bedrooms,
      'status': status.name,
    };
  }
}
