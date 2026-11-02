enum HousingApplicationStatus { pending, completed, rejected, cancelled }

extension HousingApplicationStatusLabel on HousingApplicationStatus {
  String get label => switch (this) {
    HousingApplicationStatus.pending => 'Chờ xét duyệt',
    HousingApplicationStatus.completed => 'Đã hoàn tất',
    HousingApplicationStatus.rejected => 'Từ chối',
    HousingApplicationStatus.cancelled => 'Đã hủy',
  };

  bool get isPending => this == HousingApplicationStatus.pending;

  bool get isFinal => switch (this) {
    HousingApplicationStatus.pending => false,
    HousingApplicationStatus.completed ||
    HousingApplicationStatus.rejected ||
    HousingApplicationStatus.cancelled => true,
  };
}
