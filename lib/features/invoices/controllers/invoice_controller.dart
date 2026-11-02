import 'package:flutter/foundation.dart';

import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/models/fee_type.dart';
import 'package:homie/features/invoices/models/payment_configuration.dart';
import 'package:homie/features/invoices/models/unbilled_service_charge.dart';
import 'package:homie/features/invoices/services/invoice_repository.dart';

class InvoiceController extends ChangeNotifier {
  InvoiceController({required this.repository});

  final InvoiceRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Invoice> _invoices = const <Invoice>[];
  List<FeeType> _feeTypes = const <FeeType>[];
  List<UnbilledServiceCharge> _unbilledServices = const [];
  PaymentConfiguration? _paymentConfiguration;

  bool get isLoading => _isLoading;
  bool get loading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;
  List<Invoice> get invoices => _invoices;
  List<FeeType> get feeTypes => _feeTypes;
  List<UnbilledServiceCharge> get unbilledServices => _unbilledServices;
  PaymentConfiguration? get paymentConfiguration => _paymentConfiguration;

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _refreshInvoices();
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeeTypes() async {
    try {
      _feeTypes = List<FeeType>.unmodifiable(await repository.getFeeTypes());
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  Future<bool> loadUnbilledServices() async {
    try {
      _unbilledServices = List.unmodifiable(
        await repository.getUnbilledServices(),
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPaymentConfiguration() async {
    try {
      _paymentConfiguration = await repository.getPaymentConfiguration();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  Invoice? invoiceById(String invoiceId) {
    for (final invoice in _invoices) {
      if (invoice.id == invoiceId) return invoice;
    }
    return null;
  }

  List<Invoice> invoicesForApartment(String apartmentId) {
    final result =
        _invoices
            .where((invoice) => invoice.apartmentId == apartmentId)
            .toList()
          ..sort(_compareInvoices);
    return List<Invoice>.unmodifiable(result);
  }

  double totalDebtForApartment(String apartmentId) {
    return invoicesForApartment(apartmentId)
        .where((invoice) => invoice.isOutstanding)
        .fold<double>(0, (total, invoice) => total + invoice.totalAmount);
  }

  Future<bool> createInvoice({
    required String apartmentId,
    required String payerResidentId,
    required DateTime billingMonth,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    bool publish = false,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _validateInvoiceInput(
        apartmentId: apartmentId,
        payerResidentId: payerResidentId,
        items: items,
      );

      final now = DateTime.now();
      final normalizedMonth = DateTime(billingMonth.year, billingMonth.month);
      final uniquePart = now.microsecondsSinceEpoch;
      final normalizedItems = <InvoiceItem>[
        for (var index = 0; index < items.length; index++)
          items[index].copyWith(
            id: items[index].id.trim().isEmpty
                ? 'invoice-item-$uniquePart-$index'
                : items[index].id.trim(),
            name: items[index].name.trim(),
          ),
      ];

      final invoice = Invoice(
        id: 'invoice-$uniquePart',
        code: _buildInvoiceCode(normalizedMonth, uniquePart),
        apartmentId: apartmentId.trim(),
        payerResidentId: payerResidentId.trim(),
        billingMonth: normalizedMonth,
        issuedAt: now,
        dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
        status: publish ? InvoiceStatus.unpaid : InvoiceStatus.draft,
        items: List<InvoiceItem>.unmodifiable(normalizedItems),
      );
      await repository.createInvoice(invoice);
      await _refreshInvoices();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> publishInvoice(String invoiceId) {
    return _runMutation(() => repository.publishInvoice(invoiceId));
  }

  Future<bool> recordPayment(String invoiceId) {
    return _runMutation(() => repository.recordPayment(invoiceId));
  }

  Future<bool> submitPayment(String invoiceId, {required String proofUrl}) {
    if (proofUrl.trim().isEmpty) {
      _errorMessage = 'Vui lòng tải biên lai chuyển khoản.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return _runMutation(
      () => repository.submitPayment(invoiceId, proofUrl: proofUrl.trim()),
    );
  }

  Future<String?> createVnpayPayment(String invoiceId) async {
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await repository.createVnpayPayment(invoiceId);
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectPayment(String invoiceId, {required String note}) {
    if (note.trim().length < 3) {
      _errorMessage = 'Vui lòng nhập lý do từ chối.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return _runMutation(
      () => repository.rejectPayment(invoiceId, note: note.trim()),
    );
  }

  Future<bool> cancelInvoice(String invoiceId) {
    return _runMutation(() => repository.cancelInvoice(invoiceId));
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runMutation(Future<Invoice> Function() action) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await _refreshInvoices();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshInvoices() async {
    final result = List<Invoice>.from(await repository.getInvoices())
      ..sort(_compareInvoices);
    _invoices = List<Invoice>.unmodifiable(result);
  }

  int _compareInvoices(Invoice first, Invoice second) {
    final monthComparison = second.billingMonth.compareTo(first.billingMonth);
    if (monthComparison != 0) return monthComparison;
    return second.issuedAt.compareTo(first.issuedAt);
  }

  void _validateInvoiceInput({
    required String apartmentId,
    required String payerResidentId,
    required List<InvoiceItem> items,
  }) {
    if (apartmentId.trim().isEmpty) {
      throw ArgumentError('Vui lòng chọn căn hộ.');
    }
    if (payerResidentId.trim().isEmpty) {
      throw ArgumentError('Vui lòng chọn người chịu trách nhiệm thanh toán.');
    }
    if (items.isEmpty) {
      throw ArgumentError('Hóa đơn phải có ít nhất một khoản phí.');
    }
    for (final item in items) {
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

  String _buildInvoiceCode(DateTime billingMonth, int uniquePart) {
    final month = billingMonth.month.toString().padLeft(2, '0');
    final suffix = uniquePart.toString().substring(
      uniquePart.toString().length - 5,
    );
    return 'HD-${billingMonth.year}$month-$suffix';
  }

  String _messageFor(Object error) {
    return switch (error) {
      StateError(message: final message) => message,
      ArgumentError(message: final Object? message) =>
        message?.toString() ?? 'Dữ liệu hóa đơn không hợp lệ.',
      _ => 'Không thể cập nhật hóa đơn. Vui lòng thử lại.',
    };
  }
}
