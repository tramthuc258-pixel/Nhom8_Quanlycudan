import 'package:homie/core/enums/user_role.dart';

enum AnnouncementAudience {
  all,
  residents,
  managers;

  String get label => switch (this) {
    AnnouncementAudience.all => 'Tất cả',
    AnnouncementAudience.residents => 'Cư dân',
    AnnouncementAudience.managers => 'Ban quản lý',
  };

  String get displayName => label;

  bool includes(UserRole role) {
    return switch (this) {
      AnnouncementAudience.all => true,
      AnnouncementAudience.residents => role.isResident,
      AnnouncementAudience.managers => role.isManager,
    };
  }
}
