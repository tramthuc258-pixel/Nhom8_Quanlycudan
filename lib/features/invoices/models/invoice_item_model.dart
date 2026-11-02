import 'package:homie/features/invoices/models/invoice_item.dart';

class InvoiceItemModel extends InvoiceItem {
  const InvoiceItemModel({
    required super.id,
    required super.name,
    required super.quantity,
    required super.unitPrice,
    super.feeTypeId,
    super.serviceRequestId,
    super.feeTypeCode,
    super.feeTypeDescription,
    super.source,
    super.calculationType,
    super.calculationDescription,
  });

  factory InvoiceItemModel.fromEntity(InvoiceItem item) {
    return InvoiceItemModel(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      feeTypeId: item.feeTypeId,
      serviceRequestId: item.serviceRequestId,
      feeTypeCode: item.feeTypeCode,
      feeTypeDescription: item.feeTypeDescription,
      source: item.source,
      calculationType: item.calculationType,
      calculationDescription: item.calculationDescription,
    );
  }

  factory InvoiceItemModel.fromMap(Map<String, Object?> map) {
    return InvoiceItemModel(
      id: map['id']! as String,
      name: map['name']! as String,
      quantity: (map['quantity']! as num).toDouble(),
      unitPrice: (map['unitPrice']! as num).toDouble(),
      feeTypeId: map['feeTypeId'] as String?,
      serviceRequestId: map['serviceRequestId'] as String?,
      feeTypeCode: map['feeTypeCode'] as String?,
      feeTypeDescription: map['feeTypeDescription'] as String?,
      source: map['source'] as String? ?? 'manual',
      calculationType: map['calculationType'] as String? ?? 'manual',
      calculationDescription: map['calculationDescription'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'feeTypeId': feeTypeId,
      'serviceRequestId': serviceRequestId,
      'feeTypeCode': feeTypeCode,
      'feeTypeDescription': feeTypeDescription,
      'source': source,
      'calculationType': calculationType,
      'calculationDescription': calculationDescription,
    };
  }
}
