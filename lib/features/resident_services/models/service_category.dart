enum ServiceCategory {
  cleaning,
  laundry,
  technical,
  transportation,
  convenience;

  String get label => switch (this) {
    ServiceCategory.cleaning => 'Vệ sinh',
    ServiceCategory.laundry => 'Giặt ủi',
    ServiceCategory.technical => 'Kỹ thuật',
    ServiceCategory.transportation => 'Vận chuyển',
    ServiceCategory.convenience => 'Tiện ích',
  };
}
