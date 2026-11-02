enum FeeCalculationType { fixed, byArea, byQuantity }

class FeeType {
  const FeeType({
    required this.id,
    required this.code,
    required this.name,
    required this.calculationType,
    required this.defaultUnitPrice,
    this.description,
  });

  factory FeeType.fromMap(Map<String, Object?> map) => FeeType(
    id: map['id']! as String,
    code: map['code']! as String,
    name: map['name']! as String,
    description: map['description'] as String?,
    calculationType: _feeCalculationTypeFromApi(map['calculationType']),
    defaultUnitPrice: (map['defaultUnitPrice']! as num).toDouble(),
  );

  final String id;
  final String code;
  final String name;
  final String? description;
  final FeeCalculationType calculationType;
  final double defaultUnitPrice;
}

FeeCalculationType _feeCalculationTypeFromApi(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    'fixed' => FeeCalculationType.fixed,
    'by_area' || 'byarea' => FeeCalculationType.byArea,
    'by_quantity' || 'byquantity' => FeeCalculationType.byQuantity,
    final value => throw FormatException('Kiểu tính phí không hợp lệ: $value'),
  };
}
