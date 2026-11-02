import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/models/fee_type.dart';
import 'package:homie/features/invoices/models/payment_configuration.dart';
import 'package:homie/features/invoices/models/unbilled_service_charge.dart';

abstract interface class InvoiceRepository {
  Future<List<Invoice>> getInvoices();

  Future<List<FeeType>> getFeeTypes();
  Future<List<UnbilledServiceCharge>> getUnbilledServices();
  Future<PaymentConfiguration> getPaymentConfiguration();

  Future<Invoice> createInvoice(Invoice invoice);

  Future<Invoice> publishInvoice(String invoiceId);

  Future<Invoice> recordPayment(String invoiceId);

  Future<Invoice> submitPayment(String invoiceId, {required String proofUrl});

  Future<String> createVnpayPayment(String invoiceId);

  Future<Invoice> rejectPayment(String invoiceId, {required String note});

  Future<Invoice> cancelInvoice(String invoiceId);
}
