import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/invoices/models/invoice_item.dart';
import 'package:homie/features/invoices/models/invoice_model.dart';
import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/invoices/services/invoice_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('chỉ biên lai chuyển khoản vào hàng chờ kế toán đối soát', () {
    final fields = <String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'code': 'HD-202611-TEST',
      'apartmentId': '22222222-2222-4222-8222-222222222222',
      'payerResidentId': '33333333-3333-4333-8333-333333333333',
      'billingMonth': '2026-11-01T00:00:00.000Z',
      'issuedAt': '2026-11-01T00:00:00.000Z',
      'dueDate': '2026-12-10T00:00:00.000Z',
      'status': 'unpaid',
      'items': <Map<String, Object?>>[],
      'paymentStatus': 'pending',
    };
    final bankTransfer = InvoiceModel.fromMap({
      ...fields,
      'paymentMethod': 'bank_transfer',
      'paymentProofUrl': 'https://example.com/bien-lai.jpg',
    });
    final vnpay = InvoiceModel.fromMap({...fields, 'paymentMethod': 'vnpay'});

    expect(bankTransfer.hasPendingBankTransfer, isTrue);
    expect(vnpay.hasPendingBankTransfer, isFalse);
    expect(vnpay.hasPendingVnpayPayment, isTrue);
  });

  test('mốc thanh toán UTC từ API hiển thị theo giờ thiết bị', () {
    final invoice = InvoiceModel.fromMap(<String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'code': 'HD-202611-TEST',
      'apartmentId': '22222222-2222-4222-8222-222222222222',
      'payerResidentId': '33333333-3333-4333-8333-333333333333',
      'billingMonth': '2026-11-01T00:00:00.000Z',
      'issuedAt': '2026-10-31T19:14:00.000Z',
      'dueDate': '2026-12-10T00:00:00.000Z',
      'status': 'paid',
      'items': <Map<String, Object?>>[],
      'paidAt': '2026-10-31T19:25:00.000Z',
      'paymentSubmittedAt': '2026-10-31T19:21:00.000Z',
    });

    expect(invoice.issuedAt.isUtc, isFalse);
    expect(invoice.paidAt!.isUtc, isFalse);
    expect(invoice.paymentSubmittedAt!.isUtc, isFalse);
    expect(invoice.billingMonth.isUtc, isTrue);
    expect(
      invoice.issuedAt,
      DateTime.parse('2026-10-31T19:14:00.000Z').toLocal(),
    );
  });

  test('đọc danh mục phí với enum dạng snake_case từ API', () async {
    final httpClient = MockClient((request) async {
      expect(request.url.path, endsWith('/invoices/fee-types'));
      return http.Response(
        jsonEncode(<String, Object?>{
          'items': <Map<String, Object?>>[
            <String, Object?>{
              'id': 'fee-area',
              'code': 'MANAGEMENT',
              'name': 'Phí quản lý',
              'calculationType': 'by_area',
              'defaultUnitPrice': 12000,
            },
            <String, Object?>{
              'id': 'fee-quantity',
              'code': 'WATER',
              'name': 'Tiền nước',
              'calculationType': 'by_quantity',
              'defaultUnitPrice': 18000,
            },
          ],
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);

    final feeTypes = await InvoiceApiDataSource(client).getFeeTypes();

    expect(feeTypes[0].calculationType.name, 'byArea');
    expect(feeTypes[1].calculationType.name, 'byQuantity');
  });

  test('đọc và tạo hóa đơn qua API', () async {
    const invoiceId = '11111111-1111-4111-8111-111111111111';
    const apartmentId = '22222222-2222-4222-8222-222222222222';
    const payerId = '33333333-3333-4333-8333-333333333333';
    final responseItem = <String, Object?>{
      'id': invoiceId,
      'code': 'HD-202610-TEST',
      'apartmentId': apartmentId,
      'payerResidentId': payerId,
      'billingMonth': '2026-10-01T00:00:00.000Z',
      'issuedAt': '2026-10-22T00:00:00.000Z',
      'dueDate': '2026-10-30T00:00:00.000Z',
      'status': 'unpaid',
      'items': <Map<String, Object?>>[
        <String, Object?>{
          'id': '44444444-4444-4444-8444-444444444444',
          'name': 'Phí quản lý',
          'feeTypeCode': 'MANAGEMENT_FEE',
          'feeTypeDescription': 'Bao gồm vận hành và vệ sinh khu vực chung.',
          'calculationDescription': 'Theo diện tích: 75 m² × 12.000 đồng/m²',
          'quantity': 1,
          'unitPrice': 900000,
        },
      ],
      'paidAt': null,
      'transactionCode': null,
    };
    final httpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': [responseItem],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['publish'], isTrue);
      expect(body['apartmentId'], apartmentId);
      final items = body['items']! as List<dynamic>;
      expect((items.single as Map<String, dynamic>).containsKey('id'), isFalse);
      return http.Response(
        jsonEncode(responseItem),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final dataSource = InvoiceApiDataSource(client);

    final invoices = await dataSource.getInvoices();
    final created = await dataSource.createInvoice(
      InvoiceModel(
        id: 'local-id',
        code: 'local-code',
        apartmentId: apartmentId,
        payerResidentId: payerId,
        billingMonth: DateTime.utc(2026, 10),
        issuedAt: DateTime.utc(2026, 10, 22),
        dueDate: DateTime.utc(2026, 10, 30),
        status: InvoiceStatus.unpaid,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'local-item',
            name: 'Phí quản lý',
            quantity: 1,
            unitPrice: 900000,
          ),
        ],
      ),
    );

    expect(invoices.single.totalAmount, 900000);
    expect(
      invoices.single.items.single.feeTypeDescription,
      'Bao gồm vận hành và vệ sinh khu vực chung.',
    );
    expect(created.status, InvoiceStatus.unpaid);
  });

  test(
    'gửi mã đơn dịch vụ riêng và không cho kế toán nhập lại đơn giá',
    () async {
      const requestId = '55555555-5555-4555-8555-555555555555';
      final httpClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['serviceRequestIds'], [requestId]);
        final items = body['items'] as List<dynamic>;
        expect(items.length, 1);
        expect((items.single as Map<String, dynamic>)['name'], 'Phí quản lý');
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': '11111111-1111-4111-8111-111111111111',
            'code': 'HD-TEST',
            'apartmentId': '22222222-2222-4222-8222-222222222222',
            'payerResidentId': '33333333-3333-4333-8333-333333333333',
            'billingMonth': '2026-11-01T00:00:00.000Z',
            'issuedAt': '2026-11-01T00:00:00.000Z',
            'dueDate': '2026-12-10T00:00:00.000Z',
            'status': 'unpaid',
            'items': <Map<String, Object?>>[],
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(
        baseUrl: 'http://localhost:3000/api',
        client: httpClient,
      )..accessToken = 'jwt-test';
      addTearDown(client.close);
      await InvoiceApiDataSource(client).createInvoice(
        InvoiceModel(
          id: 'local',
          code: 'local',
          apartmentId: '22222222-2222-4222-8222-222222222222',
          payerResidentId: '33333333-3333-4333-8333-333333333333',
          billingMonth: DateTime(2026, 11),
          issuedAt: DateTime(2026, 11),
          dueDate: DateTime(2026, 12, 10),
          status: InvoiceStatus.unpaid,
          items: const [
            InvoiceItem(
              id: 'manual',
              name: 'Phí quản lý',
              quantity: 1,
              unitPrice: 100000,
            ),
            InvoiceItem(
              id: 'service',
              name: 'Vệ sinh',
              quantity: 2,
              unitPrice: 35000,
              serviceRequestId: requestId,
              source: 'service',
            ),
          ],
        ),
      );
    },
  );

  test('lưu bản nháp chỉ gửi các trường khoản phí API cho phép', () async {
    const apartmentId = '22222222-2222-4222-8222-222222222222';
    const payerId = '33333333-3333-4333-8333-333333333333';
    const feeTypeId = '55555555-5555-4555-8555-555555555555';
    final httpClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/invoices'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['publish'], isFalse);
      final item =
          (body['items'] as List<dynamic>).single as Map<String, dynamic>;
      expect(
        item.keys,
        unorderedEquals(<String>['feeTypeId', 'name', 'quantity', 'unitPrice']),
      );
      expect(item['feeTypeId'], feeTypeId);
      return http.Response(
        jsonEncode(<String, Object?>{
          'id': '11111111-1111-4111-8111-111111111111',
          'code': 'HD-202611-DRAFT',
          'apartmentId': apartmentId,
          'payerResidentId': payerId,
          'billingMonth': '2026-11-01T00:00:00.000Z',
          'issuedAt': '2026-11-02T00:00:00.000Z',
          'dueDate': '2026-11-30T00:00:00.000Z',
          'status': 'draft',
          'items': <Map<String, Object?>>[
            <String, Object?>{
              'id': '44444444-4444-4444-8444-444444444444',
              'feeTypeId': feeTypeId,
              'name': 'Phí quản lý',
              'quantity': 72,
              'unitPrice': 12000,
            },
          ],
        }),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);

    final draft = await InvoiceApiDataSource(client).createInvoice(
      InvoiceModel(
        id: 'local-id',
        code: 'local-code',
        apartmentId: apartmentId,
        payerResidentId: payerId,
        billingMonth: DateTime.utc(2026, 11),
        issuedAt: DateTime.utc(2026, 11, 2),
        dueDate: DateTime.utc(2026, 11, 30),
        status: InvoiceStatus.draft,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'local-item',
            feeTypeId: feeTypeId,
            feeTypeCode: 'MANAGEMENT_FEE',
            source: 'catalog',
            calculationType: 'byArea',
            calculationDescription: 'Theo diện tích',
            name: 'Phí quản lý',
            quantity: 72,
            unitPrice: 12000,
          ),
        ],
      ),
    );

    expect(draft.status, InvoiceStatus.draft);
  });
}
