enum SecurityIncidentStatus {
  reported,
  reviewing,
  resolved,
  cancelled;

  String get label => switch (this) {
    reported => 'Đã ghi nhận',
    reviewing => 'Đang xử lý',
    resolved => 'Đã giải quyết',
    cancelled => 'Đã hủy',
  };
}
