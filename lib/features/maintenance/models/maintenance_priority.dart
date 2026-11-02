enum MaintenancePriority {
  low,
  normal,
  high,
  urgent;

  String get label => switch (this) {
    MaintenancePriority.low => 'Thấp',
    MaintenancePriority.normal => 'Bình thường',
    MaintenancePriority.high => 'Cao',
    MaintenancePriority.urgent => 'Khẩn cấp',
  };
}
