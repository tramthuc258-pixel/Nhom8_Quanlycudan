enum AnnouncementCategory {
  general,
  maintenance,
  billing,
  event,
  emergency;

  String get label => switch (this) {
    AnnouncementCategory.general => 'Chung',
    AnnouncementCategory.maintenance => 'Bảo trì',
    AnnouncementCategory.billing => 'Thu phí',
    AnnouncementCategory.event => 'Sự kiện',
    AnnouncementCategory.emergency => 'Khẩn cấp',
  };

  String get displayName => label;
}
