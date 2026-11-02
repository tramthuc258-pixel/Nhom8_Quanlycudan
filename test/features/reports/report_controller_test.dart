import 'package:flutter_test/flutter_test.dart';
import 'package:homie/dependencies.dart';
import 'package:homie/features/reports/models/management_report.dart';

void main() {
  test('tổng hợp báo cáo quản lý từ các module hiện có', () async {
    final dependencies = AppDependencies.create(useMockData: true);
    addTearDown(dependencies.dispose);

    await dependencies.reportController.load();

    final report = dependencies.reportController.report;
    expect(dependencies.reportController.errorMessage, isNull);
    expect(report, isNotNull);
    expect(report!.totalApartments, greaterThan(0));
    expect(report.activeResidents, greaterThan(0));
    expect(report.totalInvoiceValue, greaterThan(0));
    expect(report.monthlyRevenue, hasLength(6));
  });

  test('đổi kỳ báo cáo tính lại số liệu nhưng giữ số căn hộ', () async {
    final dependencies = AppDependencies.create(useMockData: true);
    addTearDown(dependencies.dispose);
    final controller = dependencies.reportController;
    await controller.load();
    final apartmentCount = controller.report!.totalApartments;

    controller.setPeriod(ReportPeriod.last30Days);

    expect(controller.period, ReportPeriod.last30Days);
    expect(controller.report!.totalApartments, apartmentCount);
  });
}
