enum ReportPeriod {
  last30Days('30 ngày'),
  last90Days('90 ngày'),
  currentYear('Năm nay'),
  allTime('Tất cả');

  const ReportPeriod(this.label);
  final String label;
}

class ReportBarDatum {
  const ReportBarDatum({required this.label, required this.value});
  final String label;
  final double value;
}

class ManagementReport {
  const ManagementReport({
    required this.totalApartments,
    required this.occupiedApartments,
    required this.vacantApartments,
    required this.maintenanceApartments,
    required this.activeResidents,
    required this.totalInvoiceValue,
    required this.collectedRevenue,
    required this.outstandingDebt,
    required this.invoiceCollectionRate,
    required this.maintenanceRequests,
    required this.openMaintenanceRequests,
    required this.completedMaintenanceRequests,
    required this.averageMaintenanceHours,
    required this.reopenedMaintenanceRequests,
    required this.serviceBookings,
    required this.completedServiceBookings,
    required this.serviceRevenue,
    required this.serviceCompletionRate,
    required this.amenityBookings,
    required this.pendingAmenityBookings,
    required this.approvedAmenityBookings,
    required this.completedAmenityBookings,
    required this.noShowAmenityBookings,
    required this.pendingHousingApplications,
    required this.approvedHousingApplications,
    required this.monthlyRevenue,
  });

  final int totalApartments;
  final int occupiedApartments;
  final int vacantApartments;
  final int maintenanceApartments;
  final int activeResidents;
  final double totalInvoiceValue;
  final double collectedRevenue;
  final double outstandingDebt;
  final double invoiceCollectionRate;
  final int maintenanceRequests;
  final int openMaintenanceRequests;
  final int completedMaintenanceRequests;
  final double averageMaintenanceHours;
  final int reopenedMaintenanceRequests;
  final int serviceBookings;
  final int completedServiceBookings;
  final double serviceRevenue;
  final double serviceCompletionRate;
  final int amenityBookings;
  final int pendingAmenityBookings;
  final int approvedAmenityBookings;
  final int completedAmenityBookings;
  final int noShowAmenityBookings;
  final int pendingHousingApplications;
  final int approvedHousingApplications;
  final List<ReportBarDatum> monthlyRevenue;
}
