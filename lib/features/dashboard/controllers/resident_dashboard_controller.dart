import 'package:flutter/foundation.dart';

import 'package:homie/features/amenities/controllers/amenity_controller.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/announcements/controllers/announcement_controller.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/maintenance/controllers/maintenance_controller.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/notifications/controllers/notification_controller.dart';
import 'package:homie/features/resident_services/controllers/service_controller.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/security_incidents/controllers/security_incident_controller.dart';
import 'package:homie/features/security_incidents/models/security_incident.dart';
import 'package:homie/features/security_incidents/models/security_incident_status.dart';
import 'package:homie/features/temporary_stays/controllers/temporary_stay_controller.dart';
import 'package:homie/features/temporary_stays/models/temporary_stay.dart';
import 'package:homie/features/temporary_stays/models/temporary_stay_status.dart';

/// Tổng hợp dữ liệu các phân hệ để trang chủ cư dân chỉ đảm nhiệm hiển thị.
class ResidentDashboardController extends ChangeNotifier {
  ResidentDashboardController({
    required this.apartmentController,
    required this.announcementController,
    required this.amenityController,
    required this.invoiceController,
    required this.maintenanceController,
    required this.notificationController,
    required this.serviceController,
    required this.temporaryStayController,
    required this.securityIncidentController,
  }) {
    for (final controller in _sources) {
      controller.addListener(_forwardChange);
    }
  }

  final ApartmentMembershipController apartmentController;
  final AnnouncementController announcementController;
  final AmenityController amenityController;
  final InvoiceController invoiceController;
  final MaintenanceController maintenanceController;
  final NotificationController notificationController;
  final ServiceController serviceController;
  final TemporaryStayController temporaryStayController;
  final SecurityIncidentController securityIncidentController;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ChangeNotifier> get _sources => [
    apartmentController,
    announcementController,
    amenityController,
    invoiceController,
    maintenanceController,
    notificationController,
    serviceController,
    temporaryStayController,
    securityIncidentController,
  ];

  Future<void> load(User user) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait<void>([
        apartmentController.load(),
        announcementController.load(),
        amenityController.load(),
        invoiceController.load(),
        maintenanceController.load(),
        notificationController.loadForUser(user.id),
        serviceController.load(),
        temporaryStayController.load(),
        securityIncidentController.load(),
      ]);
      _errorMessage = _firstError;
    } catch (_) {
      _errorMessage = 'Không thể tải dữ liệu trang chủ lúc này.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? apartmentIdFor(User user) =>
      apartmentController.activeMembershipForResident(user.id)?.apartmentId;

  String? apartmentCodeFor(User user) {
    final apartmentId = apartmentIdFor(user);
    return apartmentId == null
        ? user.apartmentCode
        : apartmentController.apartmentById(apartmentId)?.code ??
              user.apartmentCode;
  }

  List<Invoice> outstandingInvoicesFor(User user) {
    final apartmentId = apartmentIdFor(user);
    final items =
        invoiceController.invoices
            .where(
              (item) =>
                  item.isOutstanding &&
                  apartmentId != null &&
                  item.apartmentId == apartmentId &&
                  item.payerResidentId == user.id,
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return List.unmodifiable(items);
  }

  double outstandingAmountFor(User user) =>
      outstandingInvoicesFor(user)
          .fold<double>(0, (total, invoice) => total + invoice.totalAmount);

  List<MaintenanceRequest> recentRequestsFor(User user) {
    final apartmentId = apartmentIdFor(user);
    final items =
        maintenanceController
            .requestsForResident(user.id)
            .where((item) => item.apartmentId == apartmentId)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(items.take(2));
  }

  List<Announcement> recentAnnouncementsFor(User user) =>
      List.unmodifiable(announcementController.publishedForUser(user).take(3));

  int unreadCountFor(User user) =>
      notificationController.unreadCountFor(user.id) +
      announcementController.unreadCountForUser(user);

  int activeServiceCountFor(User user) => serviceController
      .bookingsForResident(user.id)
      .where(
        (item) => item.isActive && item.apartmentId == apartmentIdFor(user),
      )
      .length;

  List<AmenityBooking> activeAmenityBookingsFor(User user) {
    final now = DateTime.now();
    return List.unmodifiable(
      amenityController
          .bookingsForResident(user.id)
          .where(
            (item) =>
                item.apartmentId == apartmentIdFor(user) &&
                item.endAt.isAfter(now) &&
                (item.status == AmenityBookingStatus.pending ||
                    item.status == AmenityBookingStatus.approved),
          ),
    );
  }

  List<TemporaryStay> activeTemporaryStaysFor(User user) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.unmodifiable(
      temporaryStayController.stays.where((item) {
        final endDate = DateTime(
          item.endDate.year,
          item.endDate.month,
          item.endDate.day,
        );
        return item.declaredById == user.id &&
            item.apartmentId == apartmentIdFor(user) &&
            !endDate.isBefore(today) &&
            (item.status == TemporaryStayStatus.pending ||
                item.status == TemporaryStayStatus.approved);
      }),
    );
  }

  List<SecurityIncident> activeSecurityIncidentsFor(User user) =>
      List.unmodifiable(
        securityIncidentController.incidents.where(
          (item) =>
              item.reportedById == user.id &&
              item.apartmentId == apartmentIdFor(user) &&
              (item.status == SecurityIncidentStatus.reported ||
                  item.status == SecurityIncidentStatus.reviewing),
        ),
      );

  String? get _firstError => <String?>[
    apartmentController.errorMessage,
    announcementController.errorMessage,
    amenityController.errorMessage,
    invoiceController.errorMessage,
    maintenanceController.errorMessage,
    notificationController.errorMessage,
    serviceController.errorMessage,
    temporaryStayController.errorMessage,
    securityIncidentController.errorMessage,
  ].whereType<String>().firstOrNull;

  void _forwardChange() {
    if (!_isLoading) notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _sources) {
      controller.removeListener(_forwardChange);
    }
    super.dispose();
  }
}
