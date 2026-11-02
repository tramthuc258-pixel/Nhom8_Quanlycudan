import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/invoices/models/payment_configuration.dart';

void main() {
  test('đọc cấu hình thanh toán và tạo đúng nội dung chuyển khoản', () {
    final configuration = PaymentConfiguration.fromMap(<String, Object?>{
      'bankTransfer': <String, Object?>{
        'enabled': true,
        'bankName': 'Ngân hàng Homie',
        'bankId': 'VCB',
        'accountNumber': '0123456789',
        'accountName': 'BAN QUAN LY HOMIE',
        'transferContentPrefix': 'HOMIE',
      },
      'vnpay': <String, Object?>{'enabled': false},
    });

    expect(configuration.bankTransfer.enabled, isTrue);
    expect(configuration.vnpayEnabled, isFalse);
    expect(
      configuration.bankTransfer.contentFor(
        invoiceCode: 'HD-202610-001',
        apartmentCode: 'A-1205',
      ),
      'HOMIE HD-202610-001 A1205',
    );
    final qrUrl = configuration.bankTransfer.qrImageUrlFor(
      amount: 1550000,
      content: 'HOMIE HD-202610-001 A1205',
    );
    expect(qrUrl, contains('/image/VCB-0123456789-compact2.png'));
    expect(qrUrl, contains('amount=1550000'));
  });
}
