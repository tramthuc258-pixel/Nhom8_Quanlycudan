import 'package:homie/features/resident_services/models/service_category.dart';

class ResidentService {
  const ResidentService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.unitLabel,
    required this.unitPrice,
    required this.estimatedDurationMinutes,
    required this.providerName,
    required this.contactPhone,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final ServiceCategory category;
  final String unitLabel;
  final double unitPrice;
  final int estimatedDurationMinutes;
  final String providerName;
  final String contactPhone;
  final bool isActive;

  ResidentService copyWith({bool? isActive}) {
    return ResidentService(
      id: id,
      name: name,
      description: description,
      category: category,
      unitLabel: unitLabel,
      unitPrice: unitPrice,
      estimatedDurationMinutes: estimatedDurationMinutes,
      providerName: providerName,
      contactPhone: contactPhone,
      isActive: isActive ?? this.isActive,
    );
  }
}
