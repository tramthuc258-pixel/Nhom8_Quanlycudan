enum TemporaryStayStatus {
  pending,
  approved,
  checkedIn,
  checkedOut,
  rejected,
  cancelled,
  expired;

  String get label => switch (this) {
    pending => 'Chờ duyệt',
    approved => 'Đã duyệt',
    checkedIn => 'Đang lưu trú',
    checkedOut => 'Đã rời tòa',
    rejected => 'Từ chối',
    cancelled => 'Đã hủy',
    expired => 'Hết hạn',
  };
}
