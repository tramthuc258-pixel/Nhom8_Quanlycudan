import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/invoices/models/invoice.dart';

import '../models/invoice_model.dart';
import '../models/fee_type.dart';
import '../models/payment_configuration.dart';
import '../models/unbilled_service_charge.dart';
import 'invoice_data_source.dart';

class InvoiceMockDataSource implements InvoiceDataSource {
  InvoiceMockDataSource({this.referenceTime}) : _invoices = _seed();

  final DateTime? referenceTime;
  final List<InvoiceModel> _invoices;
  int _nextTransactionNumber = 1;

  DateTime get _now => referenceTime ?? DateTime.now();

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<InvoiceModel>.unmodifiable(_invoices);
  }

  @override
  Future<List<FeeType>> getFeeTypes() async => const <FeeType>[
    FeeType(
      id: 'fee-management',
      code: 'MANAGEMENT_FEE',
      name: 'Phí quản lý',
      calculationType: FeeCalculationType.byArea,
      defaultUnitPrice: 12000,
    ),
    FeeType(
      id: 'fee-electricity',
      code: 'ELECTRICITY_FEE',
      name: 'Tiền điện',
      calculationType: FeeCalculationType.byQuantity,
      defaultUnitPrice: 3500,
    ),
    FeeType(
      id: 'fee-water',
      code: 'WATER_FEE',
      name: 'Tiền nước',
      calculationType: FeeCalculationType.byQuantity,
      defaultUnitPrice: 18000,
    ),
  ];

  @override
  Future<List<UnbilledServiceCharge>> getUnbilledServices() async => const [];

  @override
  Future<PaymentConfiguration> getPaymentConfiguration() async =>
      const PaymentConfiguration(
        bankTransfer: BankTransferConfiguration(
          enabled: true,
          bankName: 'Ngân hàng Homie',
          bankId: 'VCB',
          accountNumber: '0123456789',
          accountName: 'BAN QUAN LY HOMIE',
          transferContentPrefix: 'HOMIE',
          branch: 'Chi nhánh trung tâm',
        ),
        vnpayEnabled: false,
      );

  @override
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _validateInvoice(invoice);

    if (_invoices.any((item) => item.id == invoice.id)) {
      throw StateError('Mã định danh hóa đơn đã tồn tại.');
    }
    if (_invoices.any((item) => item.code == invoice.code)) {
      throw StateError('Mã hóa đơn đã tồn tại.');
    }
    if (_hasInvoiceInBillingMonth(
      apartmentId: invoice.apartmentId,
      billingMonth: invoice.billingMonth,
    )) {
      throw StateError(
        'Căn hộ đã có hóa đơn trong kỳ này. Hãy hủy hóa đơn cũ trước khi tạo lại.',
      );
    }

    _invoices.add(invoice);
    return invoice;
  }

  @override
  Future<InvoiceModel> publishInvoice(String invoiceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _indexOf(invoiceId);
    final current = _invoices[index];
    if (current.status != InvoiceStatus.draft) {
      throw StateError(
        'Chỉ có thể phát hành hóa đơn đang ở trạng thái bản nháp.',
      );
    }

    final published = InvoiceModel.fromEntity(
      current.copyWith(status: InvoiceStatus.unpaid),
    );
    _invoices[index] = published;
    return published;
  }

  @override
  Future<InvoiceModel> recordPayment(String invoiceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final index = _indexOf(invoiceId);
    final current = _invoices[index];
    final status = current.effectiveStatus;

    if (status == InvoiceStatus.draft) {
      throw StateError('Hóa đơn phải được phát hành trước khi thanh toán.');
    }
    if (status == InvoiceStatus.paid) {
      throw StateError('Hóa đơn đã được thanh toán trước đó.');
    }
    if (status == InvoiceStatus.cancelled) {
      throw StateError('Không thể thanh toán hóa đơn đã hủy.');
    }

    final paidAt = _now;
    final transactionCode = _buildTransactionCode(paidAt);
    final paid = InvoiceModel.fromEntity(
      current.copyWith(
        status: InvoiceStatus.paid,
        paidAt: paidAt,
        transactionCode: transactionCode,
        paymentStatus: 'confirmed',
        paymentConfirmedByName: 'Kế toán Homie',
      ),
    );
    _invoices[index] = paid;
    return paid;
  }

  @override
  Future<InvoiceModel> submitPayment(
    String invoiceId, {
    required String proofUrl,
  }) async {
    final index = _indexOf(invoiceId);
    final current = _invoices[index];
    if (!current.isOutstanding) {
      throw StateError('Hóa đơn không còn ở trạng thái chờ thanh toán.');
    }
    if (current.hasPendingPayment) {
      throw StateError('Giao dịch đang chờ kế toán xác nhận.');
    }
    final updated = InvoiceModel.fromEntity(
      current.copyWith(
        transactionCode:
            'CK-${current.code}-${_now.microsecondsSinceEpoch.toRadixString(36)}'
                .toUpperCase(),
        paymentStatus: 'pending',
        paymentProofUrl: proofUrl,
        paymentSubmittedAt: _now,
      ),
    );
    _invoices[index] = updated;
    return updated;
  }

  @override
  Future<String> createVnpayPayment(String invoiceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _indexOf(invoiceId);
    final current = _invoices[index];
    if (!current.isOutstanding) {
      throw StateError('Hóa đơn không thể thanh toán lúc này.');
    }
    final reference = 'HOMIE-${_now.millisecondsSinceEpoch}';
    _invoices[index] = InvoiceModel.fromEntity(
      current.copyWith(
        transactionCode: reference,
        paymentStatus: 'pending',
        paymentMethod: 'vnpay',
        paymentSubmittedAt: _now,
      ),
    );
    return 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_TxnRef=$reference';
  }

  @override
  Future<InvoiceModel> rejectPayment(
    String invoiceId, {
    required String note,
  }) async {
    final index = _indexOf(invoiceId);
    final current = _invoices[index];
    if (!current.hasPendingPayment) {
      throw StateError('Không có giao dịch nào đang chờ xác nhận.');
    }
    final updated = InvoiceModel.fromEntity(
      current.copyWith(paymentStatus: 'cancelled', paymentNote: note.trim()),
    );
    _invoices[index] = updated;
    return updated;
  }

  @override
  Future<InvoiceModel> cancelInvoice(String invoiceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _indexOf(invoiceId);
    final current = _invoices[index];
    if (current.effectiveStatus == InvoiceStatus.paid) {
      throw StateError('Không thể hủy hóa đơn đã thanh toán.');
    }
    if (current.effectiveStatus == InvoiceStatus.cancelled) {
      throw StateError('Hóa đơn đã được hủy trước đó.');
    }

    final cancelled = InvoiceModel.fromEntity(
      current.copyWith(
        status: InvoiceStatus.cancelled,
        clearPaidAt: true,
        clearTransactionCode: true,
      ),
    );
    _invoices[index] = cancelled;
    return cancelled;
  }

  int _indexOf(String invoiceId) {
    final index = _invoices.indexWhere((invoice) => invoice.id == invoiceId);
    if (index == -1) {
      throw StateError('Không tìm thấy hóa đơn.');
    }
    return index;
  }

  bool _hasInvoiceInBillingMonth({
    required String apartmentId,
    required DateTime billingMonth,
  }) {
    return _invoices.any(
      (invoice) =>
          invoice.apartmentId == apartmentId &&
          invoice.status != InvoiceStatus.cancelled &&
          invoice.billingMonth.year == billingMonth.year &&
          invoice.billingMonth.month == billingMonth.month,
    );
  }

  void _validateInvoice(Invoice invoice) {
    if (invoice.apartmentId.trim().isEmpty) {
      throw ArgumentError('Vui lòng chọn căn hộ.');
    }
    if (invoice.payerResidentId.trim().isEmpty) {
      throw ArgumentError('Vui lòng chọn người chịu trách nhiệm thanh toán.');
    }
    if (invoice.items.isEmpty) {
      throw ArgumentError('Hóa đơn phải có ít nhất một khoản phí.');
    }
    for (final item in invoice.items) {
      if (item.name.trim().isEmpty) {
        throw ArgumentError('Tên khoản phí không được để trống.');
      }
      if (!item.quantity.isFinite || item.quantity <= 0) {
        throw ArgumentError('Số lượng của khoản phí phải lớn hơn 0.');
      }
      if (!item.unitPrice.isFinite || item.unitPrice <= 0) {
        throw ArgumentError('Đơn giá của khoản phí phải lớn hơn 0.');
      }
    }
  }

  String _buildTransactionCode(DateTime paidAt) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final datePart =
        '${paidAt.year}${twoDigits(paidAt.month)}'
        '${twoDigits(paidAt.day)}';
    final sequence = (_nextTransactionNumber++).toString().padLeft(4, '0');
    return 'HOMIE-$datePart-$sequence';
  }

  static List<InvoiceModel> _seed() {
    return <InvoiceModel>[
      InvoiceModel(
        id: 'invoice-001',
        code: 'HD-202610-A1205',
        apartmentId: 'apartment-001',
        payerResidentId: 'resident-001',
        billingMonth: DateTime(2026, 10),
        issuedAt: DateTime(2026, 10, 2, 8, 30),
        dueDate: DateTime(2026, 10, 25),
        status: InvoiceStatus.unpaid,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-001-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 900000,
          ),
          InvoiceItem(
            id: 'item-001-02',
            name: 'Tiền điện',
            quantity: 186,
            unitPrice: 3500,
          ),
          InvoiceItem(
            id: 'item-001-03',
            name: 'Tiền nước',
            quantity: 12,
            unitPrice: 18000,
          ),
          InvoiceItem(
            id: 'item-001-04',
            name: 'Phí gửi xe',
            quantity: 1,
            unitPrice: 120000,
          ),
        ],
      ),
      InvoiceModel(
        id: 'invoice-002',
        code: 'HD-202609-A1205',
        apartmentId: 'apartment-001',
        payerResidentId: 'resident-001',
        billingMonth: DateTime(2026, 9),
        issuedAt: DateTime(2026, 9, 2, 8, 30),
        dueDate: DateTime(2026, 9, 25),
        status: InvoiceStatus.paid,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-002-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 900000,
          ),
          InvoiceItem(
            id: 'item-002-02',
            name: 'Tiền điện',
            quantity: 174,
            unitPrice: 3500,
          ),
          InvoiceItem(
            id: 'item-002-03',
            name: 'Tiền nước',
            quantity: 11,
            unitPrice: 18000,
          ),
        ],
        paidAt: DateTime(2026, 9, 18, 10, 15),
        transactionCode: 'HOMIE-20260918-0001',
      ),
      InvoiceModel(
        id: 'invoice-003',
        code: 'HD-202608-A1205',
        apartmentId: 'apartment-001',
        payerResidentId: 'resident-owner-001',
        billingMonth: DateTime(2026, 8),
        issuedAt: DateTime(2026, 8, 2, 8, 30),
        dueDate: DateTime(2026, 8, 25),
        status: InvoiceStatus.paid,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-003-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 900000,
          ),
          InvoiceItem(
            id: 'item-003-02',
            name: 'Tiền điện',
            quantity: 151,
            unitPrice: 3500,
          ),
          InvoiceItem(
            id: 'item-003-03',
            name: 'Tiền nước',
            quantity: 9,
            unitPrice: 18000,
          ),
        ],
        paidAt: DateTime(2026, 8, 20, 14, 10),
        transactionCode: 'HOMIE-20260820-0001',
      ),
      InvoiceModel(
        id: 'invoice-004',
        code: 'HD-202609-A1002',
        apartmentId: 'apartment-002',
        payerResidentId: 'resident-003',
        billingMonth: DateTime(2026, 9),
        issuedAt: DateTime(2026, 9, 2, 8, 30),
        dueDate: DateTime(2026, 9, 25),
        status: InvoiceStatus.unpaid,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-004-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 820000,
          ),
          InvoiceItem(
            id: 'item-004-02',
            name: 'Phí gửi xe',
            quantity: 2,
            unitPrice: 120000,
          ),
        ],
      ),
      InvoiceModel(
        id: 'invoice-005',
        code: 'HD-202610-B1501',
        apartmentId: 'apartment-004',
        payerResidentId: 'resident-005',
        billingMonth: DateTime(2026, 10),
        issuedAt: DateTime(2026, 10, 5, 9),
        dueDate: DateTime(2026, 10, 28),
        status: InvoiceStatus.draft,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-005-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 1150000,
          ),
          InvoiceItem(
            id: 'item-005-02',
            name: 'Tiền nước',
            quantity: 15,
            unitPrice: 18000,
          ),
        ],
      ),
      InvoiceModel(
        id: 'invoice-006',
        code: 'HD-202608-A1002',
        apartmentId: 'apartment-002',
        payerResidentId: 'resident-003',
        billingMonth: DateTime(2026, 8),
        issuedAt: DateTime(2026, 8, 2, 8, 30),
        dueDate: DateTime(2026, 8, 25),
        status: InvoiceStatus.cancelled,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-006-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 820000,
          ),
        ],
      ),
      InvoiceModel(
        id: 'invoice-007',
        code: 'HD-202609-B1501',
        apartmentId: 'apartment-004',
        payerResidentId: 'resident-005',
        billingMonth: DateTime(2026, 9),
        issuedAt: DateTime(2026, 9, 2, 8, 30),
        dueDate: DateTime(2026, 9, 25),
        status: InvoiceStatus.paid,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item-007-01',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 1150000,
          ),
          InvoiceItem(
            id: 'item-007-02',
            name: 'Phí gửi xe',
            quantity: 1,
            unitPrice: 120000,
          ),
        ],
        paidAt: DateTime(2026, 9, 22, 16, 20),
        transactionCode: 'HOMIE-20260922-0001',
      ),
    ];
  }
}
