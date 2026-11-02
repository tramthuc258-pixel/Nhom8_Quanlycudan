enum MembershipType { owner, tenant }

extension MembershipTypeLabel on MembershipType {
  String get displayName {
    return switch (this) {
      MembershipType.owner => 'Chủ sở hữu',
      MembershipType.tenant => 'Người thuê',
    };
  }
}
