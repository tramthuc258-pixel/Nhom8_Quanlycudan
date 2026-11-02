class RegistrationOtpResult {
  const RegistrationOtpResult({
    required this.message,
    required this.expiresInSeconds,
    this.developmentCode,
  });

  final String message;
  final int expiresInSeconds;
  final String? developmentCode;
}
