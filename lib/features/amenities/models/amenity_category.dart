enum AmenityCategory { pool, gym, communityRoom, sport, barbecue }

extension AmenityCategoryLabel on AmenityCategory {
  String get label => switch (this) {
    AmenityCategory.pool => 'Hồ bơi',
    AmenityCategory.gym => 'Phòng gym',
    AmenityCategory.communityRoom => 'Phòng sinh hoạt',
    AmenityCategory.sport => 'Sân thể thao',
    AmenityCategory.barbecue => 'Khu BBQ',
  };
}
