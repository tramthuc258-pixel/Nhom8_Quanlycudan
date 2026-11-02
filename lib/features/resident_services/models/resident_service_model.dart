import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_category.dart';

class ResidentServiceModel extends ResidentService {
  const ResidentServiceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.unitLabel,
    required super.unitPrice,
    required super.estimatedDurationMinutes,
    required super.providerName,
    required super.contactPhone,
    required super.isActive,
  });

  factory ResidentServiceModel.fromMap(Map<String, Object?> map) {
    return ResidentServiceModel(
      id: map['id']! as String,
      name: map['name']! as String,
      description: map['description'] as String? ?? '',
      category: ServiceCategory.values.byName(map['category']! as String),
      unitLabel: map['unitLabel']! as String,
      unitPrice: (map['unitPrice']! as num).toDouble(),
      estimatedDurationMinutes:
          (map['estimatedDurationMinutes'] as num?)?.toInt() ?? 0,
      providerName: map['providerName'] as String? ?? '',
      contactPhone: map['contactPhone'] as String? ?? '',
      isActive: map['isActive']! as bool,
    );
  }

  factory ResidentServiceModel.fromEntity(ResidentService service) {
    return ResidentServiceModel(
      id: service.id,
      name: service.name,
      description: service.description,
      category: service.category,
      unitLabel: service.unitLabel,
      unitPrice: service.unitPrice,
      estimatedDurationMinutes: service.estimatedDurationMinutes,
      providerName: service.providerName,
      contactPhone: service.contactPhone,
      isActive: service.isActive,
    );
  }
}
