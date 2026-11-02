enum HousingTransactionType { rent, purchase }

extension HousingTransactionTypeLabel on HousingTransactionType {
  String get label => switch (this) {
    HousingTransactionType.rent => 'Thuê căn hộ',
    HousingTransactionType.purchase => 'Mua căn hộ',
  };

  String get shortLabel => switch (this) {
    HousingTransactionType.rent => 'Cho thuê',
    HousingTransactionType.purchase => 'Mở bán',
  };

  String get priceUnit => switch (this) {
    HousingTransactionType.rent => '/ tháng',
    HousingTransactionType.purchase => '',
  };
}
