enum MaintenanceStatus {
  submitted,
  received,
  inProgress,
  waitingResident,
  completed,
  cancelled;

  String get label => switch (this) {
    MaintenanceStatus.submitted => 'Đã gửi',
    MaintenanceStatus.received => 'Đã tiếp nhận',
    MaintenanceStatus.inProgress => 'Đang xử lý',
    MaintenanceStatus.waitingResident => 'Chờ cư dân xác nhận',
    MaintenanceStatus.completed => 'Hoàn thành',
    MaintenanceStatus.cancelled => 'Đã hủy',
  };

  bool get isOpen =>
      this != MaintenanceStatus.completed &&
      this != MaintenanceStatus.cancelled;

  bool get isTerminal => !isOpen;
}
