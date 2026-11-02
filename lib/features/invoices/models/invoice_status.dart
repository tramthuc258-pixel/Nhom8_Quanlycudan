enum InvoiceStatus {
  draft,
  unpaid,
  paid,
  cancelled,
  overdue;

  String get label => switch (this) {
    InvoiceStatus.draft => 'Bản nháp',
    InvoiceStatus.unpaid => 'Chưa thanh toán',
    InvoiceStatus.paid => 'Đã thanh toán',
    InvoiceStatus.cancelled => 'Đã hủy',
    InvoiceStatus.overdue => 'Quá hạn',
  };

  String get displayName => label;

  bool get isOutstanding =>
      this == InvoiceStatus.unpaid || this == InvoiceStatus.overdue;

  bool get isTerminal =>
      this == InvoiceStatus.paid || this == InvoiceStatus.cancelled;

  bool get canPublish => this == InvoiceStatus.draft;

  bool get canPay => isOutstanding;

  bool get canCancel =>
      this == InvoiceStatus.draft ||
      this == InvoiceStatus.unpaid ||
      this == InvoiceStatus.overdue;
}
