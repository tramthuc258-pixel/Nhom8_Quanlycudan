enum ApartmentStatus {
  occupied,
  vacant,
  underMaintenance;

  static ApartmentStatus fromValue(Object? value) {
    return switch (value?.toString()) {
      'occupied' || 'OCCUPIED' => occupied,
      'vacant' || 'VACANT' => vacant,
      'underMaintenance' ||
      'under_maintenance' ||
      'UNDER_MAINTENANCE' => underMaintenance,
      final invalid => throw ArgumentError.value(
        invalid,
        'value',
        'Trạng thái căn hộ không hợp lệ',
      ),
    };
  }
}

extension ApartmentStatusLabel on ApartmentStatus {
  String get displayName {
    return switch (this) {
      ApartmentStatus.occupied => 'Đang có người ở',
      ApartmentStatus.vacant => 'Đang trống',
      ApartmentStatus.underMaintenance => 'Đang bảo trì',
    };
  }
}
