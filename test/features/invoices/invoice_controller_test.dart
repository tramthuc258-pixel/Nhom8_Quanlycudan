import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/invoices/services/invoice_mock_data_source.dart';
import 'package:homie/features/invoices/services/invoice_repository_impl.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';

void main() {
  late InvoiceController controller;

  setUp(() {
    controller = InvoiceController(
      repository: InvoiceRepositoryImpl(InvoiceMockDataSource()),
    );
  });

  tearDown(() => controller.dispose());

  test('tải đúng lịch sử và tổng công nợ của căn A-1205', () async {
    await controller.load();

    final invoices = controller.invoicesForApartment('apartment-001');

    expect(invoices, hasLength(3));
    expect(invoices.first.code, 'HD-202610-A1205');
    expect(controller.totalDebtForApartment('apartment-001'), 1887000);
    expect(
      invoices.where((invoice) => invoice.status == InvoiceStatus.paid),
      hasLength(2),
    );
  });

  test('hóa đơn chưa thanh toán tự hiển thị quá hạn sau ngày đến hạn', () {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final invoice = Invoice(
      id: 'overdue-test',
      code: 'HD-TEST',
      apartmentId: 'apartment-001',
      payerResidentId: 'resident-001',
      billingMonth: DateTime(yesterday.year, yesterday.month),
      issuedAt: yesterday.subtract(const Duration(days: 10)),
      dueDate: yesterday,
      status: InvoiceStatus.unpaid,
      items: const <InvoiceItem>[
        InvoiceItem(
          id: 'item-test',
          name: 'Phí quản lý',
          quantity: 1,
          unitPrice: 900000,
        ),
      ],
    );

    expect(invoice.effectiveStatus, InvoiceStatus.overdue);
    expect(invoice.isOutstanding, isTrue);
  });

  test('không cho tạo hóa đơn không có khoản phí hoặc trùng kỳ', () async {
    await controller.load();

    final emptyItems = await controller.createInvoice(
      apartmentId: 'apartment-001',
      payerResidentId: 'resident-001',
      billingMonth: DateTime(2040, 1),
      dueDate: DateTime(2040, 1, 25),
      items: const <InvoiceItem>[],
    );

    expect(emptyItems, isFalse);
    expect(controller.errorMessage, contains('ít nhất một khoản phí'));

    final duplicateMonth = await controller.createInvoice(
      apartmentId: 'apartment-001',
      payerResidentId: 'resident-001',
      billingMonth: DateTime(2026, 10),
      dueDate: DateTime(2026, 10, 25),
      items: const <InvoiceItem>[
        InvoiceItem(
          id: '',
          name: 'Phí quản lý',
          quantity: 1,
          unitPrice: 900000,
        ),
      ],
    );

    expect(duplicateMonth, isFalse);
    expect(controller.errorMessage, contains('đã có hóa đơn trong kỳ'));
  });

  test('phát hành và thanh toán hóa đơn tạo biên nhận duy nhất', () async {
    await controller.load();

    expect(await controller.publishInvoice('invoice-005'), isTrue);
    expect(controller.invoiceById('invoice-005')?.status, InvoiceStatus.unpaid);

    expect(await controller.recordPayment('invoice-005'), isTrue);
    final paidInvoice = controller.invoiceById('invoice-005');
    expect(paidInvoice?.status, InvoiceStatus.paid);
    expect(paidInvoice?.paidAt, isNotNull);
    expect(paidInvoice?.transactionCode, startsWith('HOMIE-'));

    expect(await controller.recordPayment('invoice-005'), isFalse);
    expect(controller.errorMessage, contains('đã được thanh toán'));
    expect(await controller.cancelInvoice('invoice-005'), isFalse);
    expect(controller.errorMessage, contains('Không thể hủy'));
  });

  test('chuyển khoản chỉ cần biên lai và tự sinh mã hồ sơ', () async {
    await controller.load();

    expect(
      await controller.submitPayment('invoice-001', proofUrl: '   '),
      isFalse,
    );
    expect(controller.errorMessage, contains('tải biên lai'));

    const proofUrl =
        'https://example.supabase.co/storage/v1/object/sign/homie-files/bill.jpg';
    expect(
      await controller.submitPayment('invoice-001', proofUrl: proofUrl),
      isTrue,
    );

    final submitted = controller.invoiceById('invoice-001');
    expect(submitted?.paymentProofUrl, proofUrl);
    expect(submitted?.transactionCode, startsWith('CK-HD-202610-A1205-'));
    expect(submitted?.hasPendingPayment, isTrue);
  });
}
