enum AnnouncementPriority {
  normal,
  important,
  urgent;

  String get label => switch (this) {
    AnnouncementPriority.normal => 'Thông thường',
    AnnouncementPriority.important => 'Quan trọng',
    AnnouncementPriority.urgent => 'Khẩn cấp',
  };

  String get displayName => label;

  int get sortOrder => switch (this) {
    AnnouncementPriority.urgent => 0,
    AnnouncementPriority.important => 1,
    AnnouncementPriority.normal => 2,
  };
}
