import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/invoices/models/invoice.dart';

import 'invoice_item_model.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.code,
    required super.apartmentId,
    required super.payerResidentId,
    required super.billingMonth,
    required super.issuedAt,
    required super.dueDate,
    required super.status,
    required super.items,
    super.paidAt,
    super.transactionCode,
    super.createdByName,
    super.publishedByName,
    super.publishedAt,
    super.paymentStatus,
    super.paymentMethod,
    super.paymentNote,
    super.paymentProofUrl,
    super.paymentSubmittedAt,
    super.paymentConfirmedByName,
  });

  factory InvoiceModel.fromEntity(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      code: invoice.code,
      apartmentId: invoice.apartmentId,
      payerResidentId: invoice.payerResidentId,
      billingMonth: invoice.billingMonth,
      issuedAt: invoice.issuedAt,
      dueDate: invoice.dueDate,
      status: invoice.status,
      items: List<InvoiceItemModel>.unmodifiable(
        invoice.items.map(InvoiceItemModel.fromEntity),
      ),
      paidAt: invoice.paidAt,
      transactionCode: invoice.transactionCode,
      createdByName: invoice.createdByName,
      publishedByName: invoice.publishedByName,
      publishedAt: invoice.publishedAt,
      paymentStatus: invoice.paymentStatus,
      paymentMethod: invoice.paymentMethod,
      paymentNote: invoice.paymentNote,
      paymentProofUrl: invoice.paymentProofUrl,
      paymentSubmittedAt: invoice.paymentSubmittedAt,
      paymentConfirmedByName: invoice.paymentConfirmedByName,
    );
  }

  factory InvoiceModel.fromMap(Map<String, Object?> map) {
    final paidAtValue = map['paidAt'] as String?;
    final paymentSubmittedAtValue = map['paymentSubmittedAt'] as String?;
    final publishedAtValue = map['publishedAt'] as String?;
    final rawItems = map['items']! as List<Object?>;
    return InvoiceModel(
      id: map['id']! as String,
      code: map['code']! as String,
      apartmentId: map['apartmentId']! as String,
      payerResidentId: map['payerResidentId']! as String,
      billingMonth: DateTime.parse(map['billingMonth']! as String),
      issuedAt: DateTime.parse(map['issuedAt']! as String).toLocal(),
      dueDate: DateTime.parse(map['dueDate']! as String),
      status: InvoiceStatus.values.byName(map['status']! as String),
      items: List<InvoiceItemModel>.unmodifiable(
        rawItems.map(
          (item) =>
              InvoiceItemModel.fromMap(Map<String, Object?>.from(item! as Map)),
        ),
      ),
      paidAt: paidAtValue == null
          ? null
          : DateTime.parse(paidAtValue).toLocal(),
      transactionCode: map['transactionCode'] as String?,
      createdByName: map['createdByName'] as String?,
      publishedByName: map['publishedByName'] as String?,
      publishedAt: publishedAtValue == null
          ? null
          : DateTime.parse(publishedAtValue).toLocal(),
      paymentStatus: map['paymentStatus'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      paymentNote: map['paymentNote'] as String?,
      paymentProofUrl: map['paymentProofUrl'] as String?,
      paymentSubmittedAt: paymentSubmittedAtValue == null
          ? null
          : DateTime.parse(paymentSubmittedAtValue).toLocal(),
      paymentConfirmedByName: map['paymentConfirmedByName'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'code': code,
      'apartmentId': apartmentId,
      'payerResidentId': payerResidentId,
      'billingMonth': billingMonth.toIso8601String(),
      'issuedAt': issuedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'items': items
          .map((item) => InvoiceItemModel.fromEntity(item).toMap())
          .toList(growable: false),
      'paidAt': paidAt?.toIso8601String(),
      'transactionCode': transactionCode,
      'createdByName': createdByName,
      'publishedByName': publishedByName,
      'publishedAt': publishedAt?.toIso8601String(),
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentNote': paymentNote,
      'paymentProofUrl': paymentProofUrl,
      'paymentSubmittedAt': paymentSubmittedAt?.toIso8601String(),
      'paymentConfirmedByName': paymentConfirmedByName,
    };
  }
}
