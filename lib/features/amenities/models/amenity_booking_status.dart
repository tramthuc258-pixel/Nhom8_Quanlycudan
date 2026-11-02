enum AmenityBookingStatus {
  pending,
  approved,
  checkedIn,
  completed,
  noShow,
  rejected,
  cancelled,
  blocked,
}

extension AmenityBookingStatusLabel on AmenityBookingStatus {
  String get label => switch (this) {
    AmenityBookingStatus.pending => 'Chờ duyệt',
    AmenityBookingStatus.approved => 'Đã duyệt',
    AmenityBookingStatus.checkedIn => 'Đang sử dụng',
    AmenityBookingStatus.completed => 'Hoàn thành',
    AmenityBookingStatus.noShow => 'Không đến',
    AmenityBookingStatus.rejected => 'Từ chối',
    AmenityBookingStatus.cancelled => 'Đã hủy',
    AmenityBookingStatus.blocked => 'Đã khóa',
  };

  bool get blocksTimeSlot => switch (this) {
    AmenityBookingStatus.pending ||
    AmenityBookingStatus.approved ||
    AmenityBookingStatus.checkedIn ||
    AmenityBookingStatus.blocked => true,
    AmenityBookingStatus.completed ||
    AmenityBookingStatus.noShow ||
    AmenityBookingStatus.rejected ||
    AmenityBookingStatus.cancelled => false,
  };

  bool get canCancelByResident => this == AmenityBookingStatus.pending;
}
