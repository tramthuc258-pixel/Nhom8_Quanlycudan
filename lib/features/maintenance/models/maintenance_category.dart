enum MaintenanceCategory {
  electrical,
  plumbing,
  elevator,
  commonArea,
  security,
  other;

  String get label => switch (this) {
    MaintenanceCategory.electrical => 'Điện',
    MaintenanceCategory.plumbing => 'Nước',
    MaintenanceCategory.elevator => 'Thang máy',
    MaintenanceCategory.commonArea => 'Khu vực chung',
    MaintenanceCategory.security => 'An ninh',
    MaintenanceCategory.other => 'Khác',
  };
}
