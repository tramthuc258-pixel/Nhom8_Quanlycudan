import 'package:homie/features/invoices/models/invoice_model.dart';
import 'package:homie/features/invoices/models/fee_type.dart';
import 'package:homie/features/invoices/models/payment_configuration.dart';
import 'package:homie/features/invoices/models/unbilled_service_charge.dart';

abstract interface class InvoiceDataSource {
  Future<List<InvoiceModel>> getInvoices();

  Future<List<FeeType>> getFeeTypes();
  Future<List<UnbilledServiceCharge>> getUnbilledServices();
  Future<PaymentConfiguration> getPaymentConfiguration();

  Future<InvoiceModel> createInvoice(InvoiceModel invoice);

  Future<InvoiceModel> publishInvoice(String invoiceId);

  Future<InvoiceModel> recordPayment(String invoiceId);

  Future<InvoiceModel> submitPayment(
    String invoiceId, {
    required String proofUrl,
  });

  Future<String> createVnpayPayment(String invoiceId);

  Future<InvoiceModel> rejectPayment(String invoiceId, {required String note});

  Future<InvoiceModel> cancelInvoice(String invoiceId);
}
