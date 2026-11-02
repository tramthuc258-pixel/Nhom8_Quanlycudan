import 'package:flutter/material.dart';

import '../../dependencies.dart';

import 'package:homie/features/announcements/screens/management/announcement_management_page.dart';
import 'package:homie/features/announcements/screens/resident/announcement_list_page.dart';
import 'package:homie/features/amenities/screens/management/amenity_management_page.dart';
import 'package:homie/features/amenities/screens/resident/resident_amenities_page.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/screens/login_page.dart';
import 'package:homie/features/apartments/screens/apartment_list_page.dart';
import 'package:homie/features/dashboard/screens/manager_dashboard_page.dart';
import 'package:homie/features/dashboard/screens/resident_home_page.dart';
import 'package:homie/features/invoices/screens/management/invoice_management_page.dart';
import 'package:homie/features/invoices/screens/resident/resident_invoice_list_page.dart';
import 'package:homie/features/invoices/screens/resident/invoice_detail_page.dart';
import 'package:homie/features/housing/screens/management/housing_management_page.dart';
import 'package:homie/features/housing/screens/resident/resident_housing_page.dart';
import 'package:homie/features/maintenance/screens/management/maintenance_management_page.dart';
import 'package:homie/features/maintenance/screens/resident/resident_maintenance_page.dart';
import 'package:homie/features/maintenance/screens/resident/maintenance_detail_page.dart';
import 'package:homie/features/notifications/screens/notification_center_page.dart';
import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/auth/screens/profile_page.dart';
import 'package:homie/features/auth/screens/force_change_password_page.dart';
import 'package:homie/features/reports/screens/management_report_page.dart';
import 'package:homie/features/residents/screens/management/resident_list_page.dart';
import 'package:homie/features/residents/screens/resident/household_page.dart';
import 'package:homie/features/resident_services/screens/management/service_management_page.dart';
import 'package:homie/features/resident_services/screens/resident/resident_services_page.dart';
import 'package:homie/features/temporary_stays/screens/temporary_stay_page.dart';
import 'package:homie/features/security_incidents/screens/security_incident_page.dart';
import 'package:homie/features/staff_assignments/screens/staff_assignment_page.dart';
import 'package:homie/features/audit_logs/screens/audit_log_page.dart';

import 'route_guard.dart';

/// Điều phối màn hình gốc dựa trên phiên đăng nhập và vai trò người dùng.
abstract final class AppRouter {
  static Future<void> openPushReference({
    required BuildContext context,
    required AppDependencies dependencies,
    required User user,
    String? notificationId,
    required String? referenceType,
    required String? referenceId,
    bool fallbackToNotificationCenter = true,
  }) async {
    await dependencies.notificationController.markOpenedNotificationAsRead(
      userId: user.id,
      notificationId: notificationId,
      referenceType: referenceType,
      referenceId: referenceId,
    );
    if (!context.mounted) return;
    final management = RouteGuard.canOpenManagementArea(user);
    if (!management && referenceType == 'invoice' && referenceId != null) {
      await Future.wait<void>([
        dependencies.invoiceController.load(),
        dependencies.apartmentMembershipController.load(),
      ]);
      if (!context.mounted) return;
    }
    if (!management &&
        referenceType == 'maintenance_request' &&
        referenceId != null) {
      await Future.wait<void>([
        dependencies.maintenanceController.load(),
        dependencies.apartmentMembershipController.load(),
      ]);
      if (!context.mounted) return;
    }
    if (!management && referenceId != null) {
      final apartmentId = switch (referenceType) {
        'invoice' =>
          dependencies.invoiceController.invoiceById(referenceId)?.apartmentId,
        'maintenance_request' =>
          dependencies.maintenanceController
              .requestById(referenceId)
              ?.apartmentId,
        _ => null,
      };
      if (apartmentId != null) {
        dependencies.apartmentMembershipController.selectApartmentForResident(
          user.id,
          apartmentId,
        );
      }
    }
    final Widget? page = switch (referenceType) {
      'announcement' =>
        management
            ? AnnouncementManagementPage(
                controller: dependencies.announcementController,
                staffAssignmentController:
                    dependencies.staffAssignmentController,
              )
            : AnnouncementListPage(
                controller: dependencies.announcementController,
                user: user,
              ),
      'invoice' when !management && referenceId != null => InvoiceDetailPage(
        invoiceController: dependencies.invoiceController,
        apartmentMembershipController:
            dependencies.apartmentMembershipController,
        user: user,
        invoiceId: referenceId,
        fileUploadService: dependencies.fileUploadService,
      ),
      'invoice' =>
        management
            ? InvoiceManagementPage(
                invoiceController: dependencies.invoiceController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                canOperate: user.role.canManageInvoices,
              )
            : ResidentInvoiceListPage(
                invoiceController: dependencies.invoiceController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                user: user,
                fileUploadService: dependencies.fileUploadService,
              ),
      'maintenance_request' when !management && referenceId != null =>
        MaintenanceDetailPage(
          controller: dependencies.maintenanceController,
          apartmentMembershipController:
              dependencies.apartmentMembershipController,
          user: user,
          requestId: referenceId,
        ),
      'maintenance_request' =>
        management
            ? MaintenanceManagementPage(
                controller: dependencies.maintenanceController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                manager: user,
              )
            : ResidentMaintenancePage(
                controller: dependencies.maintenanceController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                user: user,
                fileUploadService: dependencies.fileUploadService,
              ),
      'service_request' =>
        management
            ? ServiceManagementPage(
                serviceController: dependencies.serviceController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                operator: user,
                canManageCatalog: user.role.canManageServiceCatalog,
              )
            : ResidentServicesPage(
                controller: dependencies.serviceController,
                invoiceController: dependencies.invoiceController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                user: user,
              ),
      'amenity_booking' =>
        management
            ? AmenityManagementPage(
                controller: dependencies.amenityController,
                operator: user,
                canManageCatalog: user.role.canManageAmenityCatalog,
              )
            : ResidentAmenitiesPage(
                controller: dependencies.amenityController,
                apartmentMembershipController:
                    dependencies.apartmentMembershipController,
                user: user,
              ),
      'temporary_stay' => TemporaryStayPage(
        controller: dependencies.temporaryStayController,
        membershipController: dependencies.apartmentMembershipController,
        user: user,
        managementMode: management,
      ),
      'security_incident' => SecurityIncidentPage(
        controller: dependencies.securityIncidentController,
        membershipController: dependencies.apartmentMembershipController,
        user: user,
        managementMode: management,
      ),
      'housing_listing' || 'housing_application' || 'housing_inquiry' =>
        management
            ? HousingManagementPage(
                controller: dependencies.housingController,
                reviewer: user,
                fileUploadService: dependencies.fileUploadService,
              )
            : ResidentHousingPage(
                controller: dependencies.housingController,
                user: user,
                fileUploadService: dependencies.fileUploadService,
              ),
      'residence_verification' =>
        management
            ? ResidentListPage(
                controller: dependencies.apartmentMembershipController,
              )
            : HouseholdPage(
                controller: dependencies.apartmentMembershipController,
                user: user,
              ),
      _ when fallbackToNotificationCenter => _notificationCenterPage(
        dependencies: dependencies,
        user: user,
      ),
      _ => null,
    };
    if (page == null || !context.mounted) return;
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  static Widget _notificationCenterPage({
    required AppDependencies dependencies,
    required User user,
  }) {
    return NotificationCenterPage(
      controller: dependencies.notificationController,
      user: user,
      onOpenNotification: (context, notification) => _openStoredNotification(
        context: context,
        dependencies: dependencies,
        user: user,
        notification: notification,
      ),
    );
  }

  static Future<void> _openStoredNotification({
    required BuildContext context,
    required AppDependencies dependencies,
    required User user,
    required AppNotification notification,
  }) {
    return openPushReference(
      context: context,
      dependencies: dependencies,
      user: user,
      notificationId: notification.id,
      referenceType: notification.referenceType,
      referenceId: notification.referenceId,
      fallbackToNotificationCenter: false,
    );
  }

  static Widget buildRoot({
    required BuildContext context,
    required AppDependencies dependencies,
    required VoidCallback onLogout,
  }) {
    final authController = dependencies.authController;
    final user = authController.currentUser;

    if (!RouteGuard.isAuthenticated(user)) {
      return LoginPage(
        key: const ValueKey<String>('login-page'),
        controller: authController,
        onLoginSuccess: _onLoginSuccess,
      );
    }

    return buildAuthenticatedHome(
      context: context,
      dependencies: dependencies,
      user: user!,
      onLogout: onLogout,
    );
  }

  static void _onLoginSuccess(User _) {
    // AuthController đã cập nhật phiên và thông báo cho HomieApp.
  }

  static Widget buildAuthenticatedHome({
    required BuildContext context,
    required AppDependencies dependencies,
    required User user,
    required VoidCallback onLogout,
  }) {
    if (user.mustChangePassword) {
      return ForceChangePasswordPage(
        key: const ValueKey<String>('force-change-password'),
        controller: dependencies.authController,
        user: user,
        onLogout: onLogout,
      );
    }
    if (RouteGuard.canOpenManagementArea(user)) {
      return ManagerDashboardPage(
        key: const ValueKey<String>('manager-dashboard'),
        user: user,
        reportController: dependencies.reportController,
        notificationController: dependencies.notificationController,
        onLogout: onLogout,
        onOpenApartments: () => _push(
          context,
          ApartmentListPage(
            controller: dependencies.apartmentMembershipController,
          ),
        ),
        onOpenResidents: () => _push(
          context,
          ResidentListPage(
            controller: dependencies.apartmentMembershipController,
          ),
        ),
        onOpenAnnouncements: () => _push(
          context,
          AnnouncementManagementPage(
            controller: dependencies.announcementController,
            staffAssignmentController: dependencies.staffAssignmentController,
          ),
        ),
        onOpenInvoices: () => _push(
          context,
          InvoiceManagementPage(
            invoiceController: dependencies.invoiceController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            canOperate: user.role.canManageInvoices,
          ),
        ),
        onOpenMaintenance: () => _push(
          context,
          MaintenanceManagementPage(
            controller: dependencies.maintenanceController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            manager: user,
          ),
        ),
        onOpenServices: () => _push(
          context,
          ServiceManagementPage(
            serviceController: dependencies.serviceController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            operator: user,
            canManageCatalog: user.role.canManageServiceCatalog,
          ),
        ),
        onOpenHousing: () => _push(
          context,
          HousingManagementPage(
            controller: dependencies.housingController,
            reviewer: user,
            fileUploadService: dependencies.fileUploadService,
          ),
        ),
        onOpenAmenities: () => _push(
          context,
          AmenityManagementPage(
            controller: dependencies.amenityController,
            operator: user,
            canManageCatalog: user.role.canManageAmenityCatalog,
          ),
        ),
        onOpenNotifications: () => _push(
          context,
          _notificationCenterPage(dependencies: dependencies, user: user),
        ),
        onOpenProfile: () => _push(
          context,
          ProfilePage(
            controller: dependencies.authController,
            user: user,
            fileUploadService: dependencies.fileUploadService,
            pushNotificationService: dependencies.pushNotificationService,
            onOpenNotifications: () => _push(
              context,
              _notificationCenterPage(dependencies: dependencies, user: user),
            ),
            onLogout: onLogout,
          ),
        ),
        onOpenReports: () => _push(
          context,
          ManagementReportPage(controller: dependencies.reportController),
        ),
        onOpenTemporaryStays: () => _push(
          context,
          TemporaryStayPage(
            controller: dependencies.temporaryStayController,
            membershipController: dependencies.apartmentMembershipController,
            user: user,
            managementMode: true,
          ),
        ),
        onOpenSecurityIncidents: () => _push(
          context,
          SecurityIncidentPage(
            controller: dependencies.securityIncidentController,
            membershipController: dependencies.apartmentMembershipController,
            user: user,
            managementMode: true,
          ),
        ),
        onOpenStaffAssignments: () => _push(
          context,
          StaffAssignmentPage(
            controller: dependencies.staffAssignmentController,
          ),
        ),
        onOpenAuditLogs: () => _push(
          context,
          AuditLogPage(controller: dependencies.auditLogController),
        ),
      );
    }

    if (RouteGuard.canOpenResidentArea(user)) {
      final activeMembership = dependencies.apartmentMembershipController
          .activeMembershipForResident(user.id);
      final resolvedApartmentCode =
          dependencies.apartmentMembershipController
              .apartmentById(activeMembership?.apartmentId ?? '')
              ?.code ??
          user.apartmentCode;
      return ResidentHomePage(
        key: const ValueKey<String>('resident-dashboard'),
        user: user,
        dashboardController: dependencies.residentDashboardController,
        apartmentCode: resolvedApartmentCode,
        onLogout: onLogout,
        onOpenHousehold: () => _push(
          context,
          HouseholdPage(
            controller: dependencies.apartmentMembershipController,
            user: user,
          ),
        ),
        onOpenAnnouncements: () => _push(
          context,
          AnnouncementListPage(
            controller: dependencies.announcementController,
            user: user,
          ),
        ),
        onOpenInvoices: () => _push(
          context,
          ResidentInvoiceListPage(
            invoiceController: dependencies.invoiceController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            user: user,
            fileUploadService: dependencies.fileUploadService,
          ),
        ),
        onOpenMaintenance: () => _push(
          context,
          ResidentMaintenancePage(
            controller: dependencies.maintenanceController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            user: user,
            fileUploadService: dependencies.fileUploadService,
          ),
        ),
        onOpenServices: () => _push(
          context,
          ResidentServicesPage(
            controller: dependencies.serviceController,
            invoiceController: dependencies.invoiceController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            user: user,
          ),
        ),
        onOpenHousing: () => _push(
          context,
          ResidentHousingPage(
            controller: dependencies.housingController,
            user: user,
            fileUploadService: dependencies.fileUploadService,
          ),
        ),
        onOpenAmenities: () => _push(
          context,
          ResidentAmenitiesPage(
            controller: dependencies.amenityController,
            apartmentMembershipController:
                dependencies.apartmentMembershipController,
            user: user,
          ),
        ),
        onOpenNotifications: () => _push(
          context,
          _notificationCenterPage(dependencies: dependencies, user: user),
        ),
        onOpenProfile: () => _push(
          context,
          ProfilePage(
            controller: dependencies.authController,
            user: user,
            fileUploadService: dependencies.fileUploadService,
            membershipController: dependencies.apartmentMembershipController,
            pushNotificationService: dependencies.pushNotificationService,
            onOpenHousehold: () => _push(
              context,
              HouseholdPage(
                controller: dependencies.apartmentMembershipController,
                user: user,
              ),
            ),
            onOpenNotifications: () => _push(
              context,
              _notificationCenterPage(dependencies: dependencies, user: user),
            ),
            onLogout: onLogout,
            apartmentCode: resolvedApartmentCode,
          ),
        ),
        onOpenTemporaryStays: () => _push(
          context,
          TemporaryStayPage(
            controller: dependencies.temporaryStayController,
            membershipController: dependencies.apartmentMembershipController,
            user: user,
            managementMode: false,
          ),
        ),
        onOpenSecurityIncidents: () => _push(
          context,
          SecurityIncidentPage(
            controller: dependencies.securityIncidentController,
            membershipController: dependencies.apartmentMembershipController,
            user: user,
            managementMode: false,
          ),
        ),
      );
    }

    return const _UnsupportedRolePage();
  }

  static Future<void> _push(BuildContext context, Widget page) {
    return Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _UnsupportedRolePage extends StatelessWidget {
  const _UnsupportedRolePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Vai trò này chưa được hỗ trợ.')),
    );
  }
}
