import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_config.dart';
import 'package:homie/core/notifications/push_notification_service.dart';
import 'package:homie/core/storage/file_upload_service.dart';
import 'package:homie/features/auth/services/auth_api_data_source.dart';
import 'package:homie/features/auth/services/auth_data_source.dart';
import 'package:homie/features/auth/services/auth_mock_data_source.dart';
import 'package:homie/features/auth/services/auth_repository_impl.dart';
import 'package:homie/features/auth/services/login.dart';
import 'package:homie/features/auth/services/register.dart';
import 'package:homie/features/auth/services/auth_session_store.dart';
import 'package:homie/features/auth/controllers/auth_controller.dart';
import 'package:homie/features/apartments/services/apartment_mock_data_source.dart';
import 'package:homie/features/apartments/services/apartment_api_data_source.dart';
import 'package:homie/features/apartments/services/apartment_data_source.dart';
import 'package:homie/features/apartments/services/apartment_repository_impl.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/announcements/services/announcement_mock_data_source.dart';
import 'package:homie/features/announcements/services/announcement_api_data_source.dart';
import 'package:homie/features/announcements/services/announcement_data_source.dart';
import 'package:homie/features/announcements/services/announcement_repository_impl.dart';
import 'package:homie/features/announcements/controllers/announcement_controller.dart';
import 'package:homie/features/amenities/services/amenity_mock_data_source.dart';
import 'package:homie/features/amenities/services/amenity_api_data_source.dart';
import 'package:homie/features/amenities/services/amenity_data_source.dart';
import 'package:homie/features/amenities/services/amenity_repository_impl.dart';
import 'package:homie/features/amenities/controllers/amenity_controller.dart';
import 'package:homie/features/invoices/services/invoice_mock_data_source.dart';
import 'package:homie/features/invoices/services/invoice_api_data_source.dart';
import 'package:homie/features/invoices/services/invoice_data_source.dart';
import 'package:homie/features/invoices/services/invoice_repository_impl.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/housing/services/housing_mock_data_source.dart';
import 'package:homie/features/housing/services/housing_api_data_source.dart';
import 'package:homie/features/housing/services/housing_data_source.dart';
import 'package:homie/features/housing/services/housing_repository_impl.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/maintenance/services/maintenance_mock_data_source.dart';
import 'package:homie/features/maintenance/services/maintenance_api_data_source.dart';
import 'package:homie/features/maintenance/services/maintenance_data_source.dart';
import 'package:homie/features/maintenance/services/maintenance_repository_impl.dart';
import 'package:homie/features/maintenance/controllers/maintenance_controller.dart';
import 'package:homie/features/notifications/services/notification_mock_data_source.dart';
import 'package:homie/features/notifications/services/notification_api_data_source.dart';
import 'package:homie/features/notifications/services/notification_data_source.dart';
import 'package:homie/features/notifications/services/notification_repository_impl.dart';
import 'package:homie/features/notifications/controllers/notification_controller.dart';
import 'package:homie/features/reports/controllers/report_controller.dart';
import 'package:homie/features/residents/services/resident_mock_data_source.dart';
import 'package:homie/features/residents/services/resident_api_data_source.dart';
import 'package:homie/features/residents/services/resident_data_source.dart';
import 'package:homie/features/residents/services/resident_repository_impl.dart';
import 'package:homie/features/resident_services/services/service_mock_data_source.dart';
import 'package:homie/features/resident_services/services/service_api_data_source.dart';
import 'package:homie/features/resident_services/services/service_data_source.dart';
import 'package:homie/features/resident_services/services/service_repository_impl.dart';
import 'package:homie/features/resident_services/controllers/service_controller.dart';
import 'package:homie/features/temporary_stays/controllers/temporary_stay_controller.dart';
import 'package:homie/features/temporary_stays/services/temporary_stay_api_data_source.dart';
import 'package:homie/features/security_incidents/controllers/security_incident_controller.dart';
import 'package:homie/features/security_incidents/services/security_incident_api_data_source.dart';
import 'package:homie/features/dashboard/controllers/resident_dashboard_controller.dart';
import 'package:homie/features/staff_assignments/controllers/staff_assignment_controller.dart';
import 'package:homie/features/staff_assignments/services/staff_assignment_api_data_source.dart';
import 'package:homie/features/audit_logs/controllers/audit_log_controller.dart';
import 'package:homie/features/audit_logs/services/audit_log_api_data_source.dart';

/// Nơi khởi tạo và quản lý các phụ thuộc dùng trong ứng dụng.
///
/// Mặc định Homie dùng API thật; nguồn dữ liệu giả chỉ được bật trong test.
class AppDependencies {
  AppDependencies._({
    required this.apiClient,
    required this.pushNotificationService,
    required this.authController,
    required this.apartmentMembershipController,
    required this.announcementController,
    required this.amenityController,
    required this.invoiceController,
    required this.housingController,
    required this.maintenanceController,
    required this.notificationController,
    required this.reportController,
    required this.serviceController,
    required this.temporaryStayController,
    required this.securityIncidentController,
    required this.residentDashboardController,
    required this.staffAssignmentController,
    required this.auditLogController,
    required this.fileUploadService,
  });

  factory AppDependencies.create({bool useMockData = false}) {
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
    final pushNotificationService = useMockData
        ? null
        : PushNotificationService(apiClient);
    final AuthDataSource authDataSource = useMockData
        ? AuthMockDataSource(responseDelay: Duration.zero)
        : AuthApiDataSource(apiClient, sessionStore: const AuthSessionStore());
    final authRepository = AuthRepositoryImpl(authDataSource);
    final login = Login(authRepository);
    final register = Register(authRepository);
    final ApartmentDataSource apartmentDataSource = useMockData
        ? ApartmentMockDataSource()
        : ApartmentApiDataSource(apiClient);
    final ResidentDataSource residentDataSource = useMockData
        ? ResidentMockDataSource()
        : ResidentApiDataSource(apiClient);
    final apartmentRepository = ApartmentRepositoryImpl(apartmentDataSource);
    final residentRepository = ResidentRepositoryImpl(residentDataSource);
    final apartmentMembershipController = ApartmentMembershipController(
      apartmentRepository: apartmentRepository,
      residentRepository: residentRepository,
      persistSelection: !useMockData,
    );
    final HousingDataSource housingDataSource = useMockData
        ? HousingMockDataSource()
        : HousingApiDataSource(apiClient);
    final housingRepository = HousingRepositoryImpl(housingDataSource);
    final AmenityDataSource amenityDataSource = useMockData
        ? AmenityMockDataSource()
        : AmenityApiDataSource(apiClient);
    final amenityRepository = AmenityRepositoryImpl(amenityDataSource);
    final AnnouncementDataSource announcementDataSource = useMockData
        ? AnnouncementMockDataSource()
        : AnnouncementApiDataSource(apiClient);
    final announcementRepository = AnnouncementRepositoryImpl(
      announcementDataSource,
    );
    final InvoiceDataSource invoiceDataSource = useMockData
        ? InvoiceMockDataSource()
        : InvoiceApiDataSource(apiClient);
    final invoiceRepository = InvoiceRepositoryImpl(invoiceDataSource);
    final MaintenanceDataSource maintenanceDataSource = useMockData
        ? MaintenanceMockDataSource()
        : MaintenanceApiDataSource(apiClient);
    final maintenanceRepository = MaintenanceRepositoryImpl(
      maintenanceDataSource,
    );
    final NotificationDataSource notificationDataSource = useMockData
        ? NotificationMockDataSource()
        : NotificationApiDataSource(apiClient);
    final notificationRepository = NotificationRepositoryImpl(
      notificationDataSource,
    );
    final ServiceDataSource serviceDataSource = useMockData
        ? ServiceMockDataSource()
        : ServiceApiDataSource(apiClient);
    final serviceRepository = ServiceRepositoryImpl(serviceDataSource);
    final amenityController = AmenityController(repository: amenityRepository);
    final invoiceController = InvoiceController(repository: invoiceRepository);
    final housingController = HousingController(
      repository: housingRepository,
      apartmentMembershipController: apartmentMembershipController,
    );
    final maintenanceController = MaintenanceController(
      repository: maintenanceRepository,
    );
    final serviceController = ServiceController(repository: serviceRepository);
    final temporaryStayController = TemporaryStayController(
      repository: TemporaryStayApiDataSource(apiClient),
    );
    final securityIncidentController = SecurityIncidentController(
      repository: SecurityIncidentApiDataSource(apiClient),
    );
    final notificationController = NotificationController(
      repository: notificationRepository,
    );
    final residentDashboardController = ResidentDashboardController(
      apartmentController: apartmentMembershipController,
      announcementController: AnnouncementController(
        repository: announcementRepository,
      ),
      amenityController: amenityController,
      invoiceController: invoiceController,
      maintenanceController: maintenanceController,
      notificationController: notificationController,
      serviceController: serviceController,
      temporaryStayController: temporaryStayController,
      securityIncidentController: securityIncidentController,
    );

    return AppDependencies._(
      apiClient: apiClient,
      authController: AuthController(
        login,
        register,
        authRepository,
        pushNotificationService,
      ),
      pushNotificationService: pushNotificationService,
      apartmentMembershipController: apartmentMembershipController,
      announcementController:
          residentDashboardController.announcementController,
      amenityController: amenityController,
      invoiceController: invoiceController,
      housingController: housingController,
      maintenanceController: maintenanceController,
      notificationController: notificationController,
      reportController: ReportController(
        apartmentController: apartmentMembershipController,
        invoiceController: invoiceController,
        maintenanceController: maintenanceController,
        serviceController: serviceController,
        amenityController: amenityController,
        housingController: housingController,
      ),
      serviceController: serviceController,
      temporaryStayController: temporaryStayController,
      securityIncidentController: securityIncidentController,
      residentDashboardController: residentDashboardController,
      staffAssignmentController: StaffAssignmentController(
        StaffAssignmentApiDataSource(apiClient),
      ),
      auditLogController: AuditLogController(AuditLogApiDataSource(apiClient)),
      fileUploadService: FileUploadService(apiClient),
    );
  }

  final ApiClient apiClient;
  final PushNotificationService? pushNotificationService;
  final AuthController authController;
  final ApartmentMembershipController apartmentMembershipController;
  final AnnouncementController announcementController;
  final AmenityController amenityController;
  final InvoiceController invoiceController;
  final HousingController housingController;
  final MaintenanceController maintenanceController;
  final NotificationController notificationController;
  final ReportController reportController;
  final ServiceController serviceController;
  final TemporaryStayController temporaryStayController;
  final SecurityIncidentController securityIncidentController;
  final ResidentDashboardController residentDashboardController;
  final StaffAssignmentController staffAssignmentController;
  final AuditLogController auditLogController;
  final FileUploadService fileUploadService;

  Future<void> initialize() async {
    await pushNotificationService?.initialize();
    await authController.restoreSession();
  }

  void dispose() {
    authController.dispose();
    residentDashboardController.dispose();
    apartmentMembershipController.dispose();
    announcementController.dispose();
    amenityController.dispose();
    invoiceController.dispose();
    housingController.dispose();
    maintenanceController.dispose();
    notificationController.dispose();
    reportController.dispose();
    serviceController.dispose();
    temporaryStayController.dispose();
    securityIncidentController.dispose();
    staffAssignmentController.dispose();
    auditLogController.dispose();
    pushNotificationService?.dispose();
    apiClient.close();
  }
}
