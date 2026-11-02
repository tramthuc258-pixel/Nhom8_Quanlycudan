import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/payments/payment_return_link.dart';

void main() {
  test('nhận đúng mã hóa đơn từ liên kết quay về Homie', () {
    expect(
      invoiceIdFromPaymentReturn(
        'homie://payment-result?invoiceId=72000000-0000-4000-8000-000000000001',
      ),
      '72000000-0000-4000-8000-000000000001',
    );
  });

  test('bỏ qua liên kết khác và mã hóa đơn không hợp lệ', () {
    expect(invoiceIdFromPaymentReturn('https://example.com/'), isNull);
    expect(invoiceIdFromPaymentReturn('homie://payment-result'), isNull);
    expect(
      invoiceIdFromPaymentReturn('homie://payment-result?invoiceId=abc'),
      isNull,
    );
  });
}
