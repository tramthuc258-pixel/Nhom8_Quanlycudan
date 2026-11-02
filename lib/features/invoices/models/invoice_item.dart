class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.feeTypeId,
    this.serviceRequestId,
    this.feeTypeCode,
    this.feeTypeDescription,
    this.source = 'manual',
    this.calculationType = 'manual',
    this.calculationDescription,
  });

  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final String? feeTypeId;
  final String? serviceRequestId;
  final String? feeTypeCode;
  final String? feeTypeDescription;
  final String source;
  final String calculationType;
  final String? calculationDescription;

  double get amount => quantity * unitPrice;

  InvoiceItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
    String? feeTypeId,
    String? serviceRequestId,
    String? feeTypeCode,
    String? feeTypeDescription,
    String? source,
    String? calculationType,
    String? calculationDescription,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      feeTypeId: feeTypeId ?? this.feeTypeId,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      feeTypeCode: feeTypeCode ?? this.feeTypeCode,
      feeTypeDescription: feeTypeDescription ?? this.feeTypeDescription,
      source: source ?? this.source,
      calculationType: calculationType ?? this.calculationType,
      calculationDescription:
          calculationDescription ?? this.calculationDescription,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoiceItem &&
            other.id == id &&
            other.name == name &&
            other.quantity == quantity &&
            other.unitPrice == unitPrice &&
            other.feeTypeId == feeTypeId &&
            other.serviceRequestId == serviceRequestId &&
            other.feeTypeCode == feeTypeCode &&
            other.feeTypeDescription == feeTypeDescription &&
            other.source == source &&
            other.calculationType == calculationType &&
            other.calculationDescription == calculationDescription;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    quantity,
    unitPrice,
    feeTypeId,
    serviceRequestId,
    feeTypeCode,
    feeTypeDescription,
    source,
    calculationType,
    calculationDescription,
  );
}
