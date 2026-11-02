enum ServiceBookingStatus {
  pending,
  confirmed,
  inProgress,
  waitingResident,
  completed,
  cancelled;

  String get label => switch (this) {
    ServiceBookingStatus.pending => 'Chờ xác nhận',
    ServiceBookingStatus.confirmed => 'Đã xác nhận',
    ServiceBookingStatus.inProgress => 'Đang thực hiện',
    ServiceBookingStatus.waitingResident => 'Chờ cư dân xác nhận',
    ServiceBookingStatus.completed => 'Hoàn thành',
    ServiceBookingStatus.cancelled => 'Đã hủy',
  };

  bool get isActive =>
      this != ServiceBookingStatus.completed &&
      this != ServiceBookingStatus.cancelled;

  bool get isTerminal => !isActive;

  bool get canCancelByResident => this == ServiceBookingStatus.pending;
}
