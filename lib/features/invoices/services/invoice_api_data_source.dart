import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/invoices/models/invoice_model.dart';
import 'package:homie/features/invoices/models/fee_type.dart';
import 'package:homie/features/invoices/models/payment_configuration.dart';
import 'package:homie/features/invoices/models/unbilled_service_charge.dart';

import 'invoice_data_source.dart';

class InvoiceApiDataSource implements InvoiceDataSource {
  const InvoiceApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final response = await _apiClient.get('/invoices');
      final items = response['items'];
      if (items is! List) {
        throw StateError('Dữ liệu hóa đơn không hợp lệ.');
      }
      return items
          .whereType<Map>()
          .map((item) => InvoiceModel.fromMap(Map<String, Object?>.from(item)))
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<FeeType>> getFeeTypes() async {
    try {
      final response = await _apiClient.get('/invoices/fee-types');
      return (response['items'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map((item) => FeeType.fromMap(Map<String, Object?>.from(item)))
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<List<UnbilledServiceCharge>> getUnbilledServices() async {
    try {
      final response = await _apiClient.get('/invoices/unbilled-services');
      return (response['items'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                UnbilledServiceCharge.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<PaymentConfiguration> getPaymentConfiguration() async {
    try {
      return PaymentConfiguration.fromMap(
        await _apiClient.get('/invoices/payment-options'),
      );
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    try {
      final response = await _apiClient.post(
        '/invoices',
        body: <String, Object?>{
          'apartmentId': invoice.apartmentId,
          'payerResidentId': invoice.payerResidentId,
          'billingMonth': invoice.billingMonth.toUtc().toIso8601String(),
          'dueDate': invoice.dueDate.toUtc().toIso8601String(),
          'publish': invoice.status.name == 'unpaid',
          'serviceRequestIds': invoice.items
              .map((item) => item.serviceRequestId)
              .whereType<String>()
              .toList(growable: false),
          'items': invoice.items
              .where((item) => item.serviceRequestId == null)
              .map(
                (item) => <String, Object?>{
                  if (item.feeTypeId != null) 'feeTypeId': item.feeTypeId,
                  'name': item.name,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                },
              )
              .toList(growable: false),
        },
      );
      return InvoiceModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<InvoiceModel> publishInvoice(String invoiceId) =>
      _patch('/invoices/$invoiceId/publish');

  @override
  Future<InvoiceModel> recordPayment(String invoiceId) =>
      _patch('/invoices/$invoiceId/payment-confirm');

  @override
  Future<InvoiceModel> submitPayment(
    String invoiceId, {
    required String proofUrl,
  }) async {
    try {
      return InvoiceModel.fromMap(
        await _apiClient.post(
          '/invoices/$invoiceId/payment-submission',
          body: <String, Object?>{'proofUrl': proofUrl.trim()},
        ),
      );
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<String> createVnpayPayment(String invoiceId) async {
    try {
      final response = await _apiClient.post(
        '/invoices/$invoiceId/vnpay/create',
      );
      final paymentUrl = response['paymentUrl'];
      if (paymentUrl is! String || paymentUrl.isEmpty) {
        throw StateError('API không trả về đường dẫn thanh toán VNPAY.');
      }
      return paymentUrl;
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<InvoiceModel> rejectPayment(
    String invoiceId, {
    required String note,
  }) async {
    try {
      return InvoiceModel.fromMap(
        await _apiClient.patch(
          '/invoices/$invoiceId/payment-reject',
          body: <String, Object?>{'note': note},
        ),
      );
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<InvoiceModel> cancelInvoice(String invoiceId) =>
      _patch('/invoices/$invoiceId/cancel');

  Future<InvoiceModel> _patch(String path) async {
    try {
      return InvoiceModel.fromMap(await _apiClient.patch(path));
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }
}
