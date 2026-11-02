enum MembershipStatus { active, ended }

extension MembershipStatusLabel on MembershipStatus {
  String get displayName {
    return switch (this) {
      MembershipStatus.active => 'Đang hiệu lực',
      MembershipStatus.ended => 'Đã kết thúc',
    };
  }
}
