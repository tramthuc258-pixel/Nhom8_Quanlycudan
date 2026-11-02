import 'package:homie/features/invoices/models/invoice_status.dart';

import 'invoice_item.dart';

export 'invoice_item.dart';

class Invoice {
  const Invoice({
    required this.id,
    required this.code,
    required this.apartmentId,
    required this.payerResidentId,
    required this.billingMonth,
    required this.issuedAt,
    required this.dueDate,
    required this.status,
    required this.items,
    this.paidAt,
    this.transactionCode,
    this.createdByName,
    this.publishedByName,
    this.publishedAt,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentNote,
    this.paymentProofUrl,
    this.paymentSubmittedAt,
    this.paymentConfirmedByName,
  });

  final String id;
  final String code;
  final String apartmentId;
  final String payerResidentId;
  final DateTime billingMonth;
  final DateTime issuedAt;
  final DateTime dueDate;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final DateTime? paidAt;
  final String? transactionCode;
  final String? createdByName;
  final String? publishedByName;
  final DateTime? publishedAt;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? paymentNote;
  final String? paymentProofUrl;
  final DateTime? paymentSubmittedAt;
  final String? paymentConfirmedByName;

  bool get hasPendingPayment => paymentStatus == 'pending';
  bool get hasPendingBankTransfer =>
      hasPendingPayment &&
      paymentMethod == 'bank_transfer' &&
      paymentProofUrl?.isNotEmpty == true;
  bool get hasPendingVnpayPayment =>
      hasPendingPayment && paymentMethod == 'vnpay';

  double get totalAmount =>
      items.fold<double>(0, (total, item) => total + item.amount);

  /// Trạng thái dùng để hiển thị và kiểm tra nghiệp vụ.
  ///
  /// Hóa đơn chưa thanh toán tự trở thành quá hạn sau hết ngày đến hạn mà
  /// không cần một tác vụ nền cập nhật lại bản ghi chỉ vì thời gian trôi qua.
  InvoiceStatus get effectiveStatus {
    if (status != InvoiceStatus.unpaid) return status;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );
    return normalizedDueDate.isBefore(today)
        ? InvoiceStatus.overdue
        : InvoiceStatus.unpaid;
  }

  bool get isOutstanding => effectiveStatus.isOutstanding;

  Invoice copyWith({
    String? id,
    String? code,
    String? apartmentId,
    String? payerResidentId,
    DateTime? billingMonth,
    DateTime? issuedAt,
    DateTime? dueDate,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? transactionCode,
    bool clearTransactionCode = false,
    String? createdByName,
    String? publishedByName,
    DateTime? publishedAt,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentNote,
    String? paymentProofUrl,
    DateTime? paymentSubmittedAt,
    String? paymentConfirmedByName,
  }) {
    return Invoice(
      id: id ?? this.id,
      code: code ?? this.code,
      apartmentId: apartmentId ?? this.apartmentId,
      payerResidentId: payerResidentId ?? this.payerResidentId,
      billingMonth: billingMonth ?? this.billingMonth,
      issuedAt: issuedAt ?? this.issuedAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      items: List<InvoiceItem>.unmodifiable(items ?? this.items),
      paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
      transactionCode: clearTransactionCode
          ? null
          : transactionCode ?? this.transactionCode,
      createdByName: createdByName ?? this.createdByName,
      publishedByName: publishedByName ?? this.publishedByName,
      publishedAt: publishedAt ?? this.publishedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNote: paymentNote ?? this.paymentNote,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentSubmittedAt: paymentSubmittedAt ?? this.paymentSubmittedAt,
      paymentConfirmedByName:
          paymentConfirmedByName ?? this.paymentConfirmedByName,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Invoice &&
            other.id == id &&
            other.code == code &&
            other.apartmentId == apartmentId &&
            other.payerResidentId == payerResidentId &&
            other.billingMonth == billingMonth &&
            other.issuedAt == issuedAt &&
            other.dueDate == dueDate &&
            other.status == status &&
            _itemsEqual(other.items, items) &&
            other.paidAt == paidAt &&
            other.transactionCode == transactionCode &&
            other.createdByName == createdByName &&
            other.publishedByName == publishedByName &&
            other.publishedAt == publishedAt &&
            other.paymentStatus == paymentStatus &&
            other.paymentMethod == paymentMethod &&
            other.paymentNote == paymentNote &&
            other.paymentProofUrl == paymentProofUrl &&
            other.paymentSubmittedAt == paymentSubmittedAt &&
            other.paymentConfirmedByName == paymentConfirmedByName;
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    apartmentId,
    payerResidentId,
    billingMonth,
    issuedAt,
    dueDate,
    status,
    Object.hashAll(items),
    paidAt,
    transactionCode,
    createdByName,
    publishedByName,
    publishedAt,
    paymentStatus,
    paymentMethod,
    paymentNote,
    paymentProofUrl,
    paymentSubmittedAt,
    paymentConfirmedByName,
  );

  static bool _itemsEqual(List<InvoiceItem> first, List<InvoiceItem> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}
