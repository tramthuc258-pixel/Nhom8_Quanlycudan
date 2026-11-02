class BankTransferConfiguration {
  const BankTransferConfiguration({
    required this.enabled,
    required this.bankName,
    required this.bankId,
    required this.accountNumber,
    required this.accountName,
    required this.transferContentPrefix,
    this.branch,
    this.qrImageUrl,
  });

  final bool enabled;
  final String bankName;
  final String bankId;
  final String accountNumber;
  final String accountName;
  final String transferContentPrefix;
  final String? branch;
  final String? qrImageUrl;

  factory BankTransferConfiguration.fromMap(Map<String, Object?> map) =>
      BankTransferConfiguration(
        enabled: map['enabled'] == true,
        bankName: map['bankName'] as String? ?? '',
        bankId: map['bankId'] as String? ?? '',
        accountNumber: map['accountNumber'] as String? ?? '',
        accountName: map['accountName'] as String? ?? '',
        transferContentPrefix:
            map['transferContentPrefix'] as String? ?? 'HOMIE',
        branch: _optionalText(map['branch']),
        qrImageUrl: _optionalText(map['qrImageUrl']),
      );

  String contentFor({
    required String invoiceCode,
    required String apartmentCode,
  }) {
    final normalizedApartment = apartmentCode.replaceAll(
      RegExp(r'[^A-Za-z0-9]'),
      '',
    );
    return '$transferContentPrefix $invoiceCode $normalizedApartment'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? qrImageUrlFor({required double amount, required String content}) {
    if (bankId.isNotEmpty && accountNumber.isNotEmpty) {
      final bank = Uri.encodeComponent(bankId);
      final account = Uri.encodeComponent(accountNumber);
      return Uri.https(
        'img.vietqr.io',
        '/image/$bank-$account-compact2.png',
        <String, String>{
          'amount': amount.round().toString(),
          'addInfo': content,
          'accountName': accountName,
        },
      ).toString();
    }
    return qrImageUrl;
  }
}

class PaymentConfiguration {
  const PaymentConfiguration({
    required this.bankTransfer,
    required this.vnpayEnabled,
  });

  final BankTransferConfiguration bankTransfer;
  final bool vnpayEnabled;

  factory PaymentConfiguration.fromMap(Map<String, Object?> map) {
    final bank = map['bankTransfer'];
    final vnpay = map['vnpay'];
    return PaymentConfiguration(
      bankTransfer: BankTransferConfiguration.fromMap(
        bank is Map ? Map<String, Object?>.from(bank) : const {},
      ),
      vnpayEnabled: vnpay is Map && vnpay['enabled'] == true,
    );
  }
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
