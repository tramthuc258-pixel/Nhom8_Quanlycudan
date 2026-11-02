import 'package:flutter/foundation.dart';

import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/amenities/controllers/amenity_controller.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/maintenance/controllers/maintenance_controller.dart';
import 'package:homie/features/resident_services/controllers/service_controller.dart';
import 'package:homie/features/reports/models/management_report.dart';

class ReportController extends ChangeNotifier {
  ReportController({
    required this.apartmentController,
    required this.invoiceController,
    required this.maintenanceController,
    required this.serviceController,
    required this.amenityController,
    required this.housingController,
    DateTime? now,
  }) : _now = now ?? DateTime.now();

  final ApartmentMembershipController apartmentController;
  final InvoiceController invoiceController;
  final MaintenanceController maintenanceController;
  final ServiceController serviceController;
  final AmenityController amenityController;
  final HousingController housingController;
  final DateTime _now;

  bool _isLoading = false;
  String? _errorMessage;
  ReportPeriod _period = ReportPeriod.last90Days;
  ManagementReport? _report;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReportPeriod get period => _period;
  ManagementReport? get report => _report;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait<void>([
        apartmentController.load(),
        invoiceController.load(),
        maintenanceController.load(),
        serviceController.load(),
        amenityController.load(),
        housingController.load(),
      ]);
      final errors = <String?>[
        apartmentController.errorMessage,
        invoiceController.errorMessage,
        maintenanceController.errorMessage,
        serviceController.errorMessage,
        amenityController.errorMessage,
        housingController.errorMessage,
      ].whereType<String>().toList();
      if (errors.isNotEmpty) throw StateError(errors.first);
      _report = _buildReport();
    } catch (error) {
      _errorMessage = error is StateError
          ? error.message
          : 'Không thể tổng hợp báo cáo lúc này.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPeriod(ReportPeriod value) {
    if (_period == value) return;
    _period = value;
    if (_report != null) _report = _buildReport();
    notifyListeners();
  }

  ManagementReport _buildReport() {
    final start = _startDate;
    bool included(DateTime value) => start == null || !value.isBefore(start);

    final apartments = apartmentController.apartments;
    final activeResidents = apartmentController.memberships
        .where((item) => item.status == MembershipStatus.active)
        .map((item) => item.residentId)
        .toSet()
        .length;

    final invoices = invoiceController.invoices
        .where((item) => included(item.issuedAt))
        .where((item) => item.effectiveStatus != InvoiceStatus.draft)
        .where((item) => item.effectiveStatus != InvoiceStatus.cancelled)
        .toList();
    final totalInvoiceValue = invoices.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final collected = invoices
        .where((item) => item.effectiveStatus == InvoiceStatus.paid)
        .fold<double>(0, (sum, item) => sum + item.totalAmount);
    final outstanding = invoices
        .where((item) => item.isOutstanding)
        .fold<double>(0, (sum, item) => sum + item.totalAmount);

    final maintenance = maintenanceController.requests
        .where((item) => included(item.createdAt))
        .toList();
    final services = serviceController.bookings
        .where((item) => included(item.createdAt))
        .toList();
    final amenities = amenityController.bookings
        .where((item) => included(item.createdAt))
        .where((item) => item.status != AmenityBookingStatus.blocked)
        .toList();
    final housing = housingController.applications
        .where((item) => included(item.submittedAt))
        .toList();
    final completedMaintenance = maintenance
        .where((item) => item.status == MaintenanceStatus.completed)
        .toList();
    final maintenanceResolutionHours = completedMaintenance
        .map((item) {
          final completedAt = item.history
              .where((update) => update.status == MaintenanceStatus.completed)
              .map((update) => update.createdAt)
              .fold<DateTime?>(
                null,
                (latest, value) =>
                    latest == null || value.isAfter(latest) ? value : latest,
              );
          return completedAt == null
              ? 0.0
              : completedAt.difference(item.createdAt).inMinutes / 60;
        })
        .where((hours) => hours >= 0)
        .toList();
    final reopenedMaintenance = maintenance.where((item) {
      for (var index = 1; index < item.history.length; index++) {
        if (item.history[index - 1].status ==
                MaintenanceStatus.waitingResident &&
            item.history[index].status == MaintenanceStatus.inProgress) {
          return true;
        }
      }
      return false;
    }).length;
    final completedServices = services
        .where((item) => item.status == ServiceBookingStatus.completed)
        .toList();

    return ManagementReport(
      totalApartments: apartments.length,
      occupiedApartments: apartments
          .where((item) => item.status == ApartmentStatus.occupied)
          .length,
      vacantApartments: apartments
          .where((item) => item.status == ApartmentStatus.vacant)
          .length,
      maintenanceApartments: apartments
          .where((item) => item.status == ApartmentStatus.underMaintenance)
          .length,
      activeResidents: activeResidents,
      totalInvoiceValue: totalInvoiceValue,
      collectedRevenue: collected,
      outstandingDebt: outstanding,
      invoiceCollectionRate: totalInvoiceValue == 0
          ? 0
          : collected / totalInvoiceValue,
      maintenanceRequests: maintenance.length,
      openMaintenanceRequests: maintenance.where((item) => item.isOpen).length,
      completedMaintenanceRequests: completedMaintenance.length,
      averageMaintenanceHours: maintenanceResolutionHours.isEmpty
          ? 0
          : maintenanceResolutionHours.reduce((a, b) => a + b) /
                maintenanceResolutionHours.length,
      reopenedMaintenanceRequests: reopenedMaintenance,
      serviceBookings: services.length,
      completedServiceBookings: completedServices.length,
      serviceRevenue: services
          .where((item) => item.status == ServiceBookingStatus.completed)
          .fold<double>(0, (sum, item) => sum + item.totalAmount),
      serviceCompletionRate: services.isEmpty
          ? 0
          : completedServices.length / services.length,
      amenityBookings: amenities.length,
      pendingAmenityBookings: amenities
          .where((item) => item.status == AmenityBookingStatus.pending)
          .length,
      approvedAmenityBookings: amenities
          .where((item) => item.status == AmenityBookingStatus.approved)
          .length,
      completedAmenityBookings: amenities
          .where((item) => item.status == AmenityBookingStatus.completed)
          .length,
      noShowAmenityBookings: amenities
          .where((item) => item.status == AmenityBookingStatus.noShow)
          .length,
      pendingHousingApplications: housing
          .where((item) => item.status == HousingApplicationStatus.pending)
          .length,
      approvedHousingApplications: housing
          .where((item) => item.status == HousingApplicationStatus.completed)
          .length,
      monthlyRevenue: _monthlyRevenue(),
    );
  }

  DateTime? get _startDate => switch (_period) {
    ReportPeriod.last30Days => _now.subtract(const Duration(days: 30)),
    ReportPeriod.last90Days => _now.subtract(const Duration(days: 90)),
    ReportPeriod.currentYear => DateTime(_now.year),
    ReportPeriod.allTime => null,
  };

  List<ReportBarDatum> _monthlyRevenue() {
    return List<ReportBarDatum>.generate(6, (index) {
      final offset = 5 - index;
      final month = DateTime(_now.year, _now.month - offset);
      final value = invoiceController.invoices
          .where((item) => item.effectiveStatus == InvoiceStatus.paid)
          .where(
            (item) =>
                item.billingMonth.year == month.year &&
                item.billingMonth.month == month.month,
          )
          .fold<double>(0, (sum, item) => sum + item.totalAmount);
      return ReportBarDatum(label: 'T${month.month}', value: value);
    });
  }
}
