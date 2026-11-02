enum HousingListingStatus { pendingApproval, available, rejected, closed }

extension HousingListingStatusLabel on HousingListingStatus {
  String get label => switch (this) {
    HousingListingStatus.pendingApproval => 'Chờ duyệt',
    HousingListingStatus.available => 'Đang nhận hồ sơ',
    HousingListingStatus.rejected => 'Bị từ chối',
    HousingListingStatus.closed => 'Đã kết thúc',
  };

  bool get isAvailable => this == HousingListingStatus.available;

  bool get isPublic => switch (this) {
    HousingListingStatus.available || HousingListingStatus.closed => true,
    HousingListingStatus.pendingApproval ||
    HousingListingStatus.rejected => false,
  };
}
