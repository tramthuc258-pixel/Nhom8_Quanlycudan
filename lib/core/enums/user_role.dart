enum UserRole {
  resident,
  manager,
  admin,
  accountant,
  receptionist,
  security,
  technician;

  String get label => switch (this) {
    UserRole.resident => 'Cư dân',
    UserRole.manager => 'Ban quản lý',
    UserRole.admin => 'Quản trị viên',
    UserRole.accountant => 'Kế toán',
    UserRole.receptionist => 'Lễ tân',
    UserRole.security => 'Bảo vệ',
    UserRole.technician => 'Kỹ thuật viên',
  };

  bool get isResident => this == UserRole.resident;

  bool get isManager => this == UserRole.manager || this == UserRole.admin;

  bool get isStaff => !isResident;

  bool get canManageApartments => isManager;
  bool get canManageResidents => isManager;
  bool get canManageAnnouncements => isManager;
  bool get canViewInvoices => isManager || this == UserRole.accountant;
  bool get canManageInvoices =>
      this == UserRole.admin || this == UserRole.accountant;
  bool get canManageMaintenance =>
      isManager || this == UserRole.receptionist || this == UserRole.technician;
  bool get canAssignMaintenance => isManager;
  bool get canManageServices =>
      isManager || this == UserRole.receptionist || this == UserRole.technician;
  bool get canManageServiceCatalog => isManager;
  bool get canManageHousing => isManager;
  bool get canManageAmenities => isManager || this == UserRole.receptionist;
  bool get canManageAmenityCatalog => isManager;
  bool get canManageTemporaryStays =>
      isManager || this == UserRole.receptionist || this == UserRole.security;
  bool get canReviewTemporaryStays =>
      isManager || this == UserRole.receptionist;
  bool get canManageSecurityIncidents => isManager || this == UserRole.security;
  bool get canOpenReports => isManager;
  bool get canManageStaffAssignments => this == UserRole.admin;
}
