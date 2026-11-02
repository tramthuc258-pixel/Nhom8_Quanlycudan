import 'package:homie/features/amenities/models/amenity_category.dart';

class Amenity {
  const Amenity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.capacity,
    required this.slotDurationMinutes,
    required this.openingHour,
    required this.closingHour,
    required this.isActive,
    this.fee = 0,
  });

  final String id;
  final String name;
  final String description;
  final AmenityCategory category;
  final int capacity;
  final int slotDurationMinutes;
  final int openingHour;
  final int closingHour;
  final double fee;
  final bool isActive;

  Amenity copyWith({bool? isActive}) => Amenity(
    id: id,
    name: name,
    description: description,
    category: category,
    capacity: capacity,
    slotDurationMinutes: slotDurationMinutes,
    openingHour: openingHour,
    closingHour: closingHour,
    fee: fee,
    isActive: isActive ?? this.isActive,
  );
}
