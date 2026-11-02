import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/services/invoice_repository.dart';
import 'package:homie/features/invoices/services/invoice_data_source.dart';

import '../models/invoice_model.dart';
import '../models/fee_type.dart';
import '../models/payment_configuration.dart';
import '../models/unbilled_service_charge.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  const InvoiceRepositoryImpl(this._dataSource);

  final InvoiceDataSource _dataSource;

  @override
  Future<List<Invoice>> getInvoices() async {
    final invoices = await _dataSource.getInvoices();
    return List<Invoice>.unmodifiable(invoices);
  }

  @override
  Future<List<FeeType>> getFeeTypes() => _dataSource.getFeeTypes();

  @override
  Future<List<UnbilledServiceCharge>> getUnbilledServices() =>
      _dataSource.getUnbilledServices();

  @override
  Future<PaymentConfiguration> getPaymentConfiguration() =>
      _dataSource.getPaymentConfiguration();

  @override
  Future<Invoice> createInvoice(Invoice invoice) {
    return _dataSource.createInvoice(InvoiceModel.fromEntity(invoice));
  }

  @override
  Future<Invoice> publishInvoice(String invoiceId) {
    return _dataSource.publishInvoice(invoiceId);
  }

  @override
  Future<Invoice> recordPayment(String invoiceId) {
    return _dataSource.recordPayment(invoiceId);
  }

  @override
  Future<Invoice> submitPayment(String invoiceId, {required String proofUrl}) =>
      _dataSource.submitPayment(invoiceId, proofUrl: proofUrl);

  @override
  Future<String> createVnpayPayment(String invoiceId) =>
      _dataSource.createVnpayPayment(invoiceId);

  @override
  Future<Invoice> rejectPayment(String invoiceId, {required String note}) =>
      _dataSource.rejectPayment(invoiceId, note: note);

  @override
  Future<Invoice> cancelInvoice(String invoiceId) {
    return _dataSource.cancelInvoice(invoiceId);
  }
}
