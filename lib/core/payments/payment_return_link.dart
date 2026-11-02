String? invoiceIdFromPaymentReturn(String? link) {
  final uri = Uri.tryParse(link ?? '');
  if (uri == null || uri.scheme != 'homie' || uri.host != 'payment-result') {
    return null;
  }
  final invoiceId = uri.queryParameters['invoiceId'];
  if (invoiceId == null || !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(invoiceId)) {
    return null;
  }
  return invoiceId;
}
