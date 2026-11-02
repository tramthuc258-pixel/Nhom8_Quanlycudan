import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_category.dart';

class AmenityModel extends Amenity {
  const AmenityModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.capacity,
    required super.slotDurationMinutes,
    required super.openingHour,
    required super.closingHour,
    required super.isActive,
    super.fee,
  });

  factory AmenityModel.fromMap(Map<String, Object?> map) => AmenityModel(
    id: map['id']! as String,
    name: map['name']! as String,
    description: map['description'] as String? ?? '',
    category: AmenityCategory.values.byName(map['category']! as String),
    capacity: (map['capacity']! as num).toInt(),
    slotDurationMinutes: (map['slotDurationMinutes']! as num).toInt(),
    openingHour: (map['openingHour']! as num).toInt(),
    closingHour: (map['closingHour']! as num).toInt(),
    fee: (map['fee']! as num).toDouble(),
    isActive: map['isActive']! as bool,
  );

  factory AmenityModel.fromEntity(Amenity value) => AmenityModel(
    id: value.id,
    name: value.name,
    description: value.description,
    category: value.category,
    capacity: value.capacity,
    slotDurationMinutes: value.slotDurationMinutes,
    openingHour: value.openingHour,
    closingHour: value.closingHour,
    fee: value.fee,
    isActive: value.isActive,
  );
}
