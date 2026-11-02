import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/maintenance/services/maintenance_mock_data_source.dart';
import 'package:homie/features/maintenance/services/maintenance_repository_impl.dart';
import 'package:homie/features/maintenance/controllers/maintenance_controller.dart';

void main() {
  late MaintenanceController controller;

  setUp(() {
    controller = MaintenanceController(
      repository: MaintenanceRepositoryImpl(
        MaintenanceMockDataSource(referenceTime: DateTime(2026, 10, 16, 10)),
      ),
    );
  });

  tearDown(() => controller.dispose());

  test('tải đúng yêu cầu đang mở của cư dân A-1205', () async {
    await controller.load();

    final requests = controller.requestsForResident('resident-001');

    expect(requests, hasLength(3));
    expect(controller.openCountForResident('resident-001'), 2);
    expect(requests.any((item) => item.code == 'YC-2026-1001'), isTrue);
  });

  test('cư dân tạo yêu cầu hợp lệ và lưu mốc lịch sử đầu tiên', () async {
    await controller.load();

    final success = await controller.createRequest(
      apartmentId: 'apartment-001',
      residentId: 'resident-001',
      residentName: 'Nguyễn Minh Anh',
      title: 'Máy hút mùi không hoạt động',
      description: 'Máy hút mùi trong bếp không khởi động khi bật công tắc.',
      location: 'Bếp căn A-1205',
      category: MaintenanceCategory.electrical,
      priority: MaintenancePriority.normal,
    );

    expect(success, isTrue);
    final created = controller.requests.firstWhere(
      (item) => item.title == 'Máy hút mùi không hoạt động',
    );
    expect(created.status, MaintenanceStatus.submitted);
    expect(created.history, hasLength(1));
    expect(created.history.single.actorName, 'Nguyễn Minh Anh');
  });

  test(
    'tạo thành công vẫn hiển thị yêu cầu khi tải lại danh sách bị lỗi',
    () async {
      final repository = _FailingRefreshRepository(
        MaintenanceMockDataSource(referenceTime: DateTime(2026, 10, 16, 10)),
      );
      controller.dispose();
      controller = MaintenanceController(repository: repository);
      await controller.load();
      repository.failNextGet = true;

      final success = await controller.createRequest(
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        residentName: 'Nguyễn Minh Anh',
        title: 'Máy hút mùi không hoạt động',
        description: 'Máy hút mùi trong bếp không khởi động khi bật công tắc.',
        location: 'Bếp căn A-1205',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.normal,
      );

      expect(success, isTrue);
      expect(controller.errorMessage, isNull);
      expect(
        controller.requests.any(
          (item) => item.title == 'Máy hút mùi không hoạt động',
        ),
        isTrue,
      );
    },
  );

  test('không tạo yêu cầu có mô tả quá ngắn', () async {
    await controller.load();

    final success = await controller.createRequest(
      apartmentId: 'apartment-001',
      residentId: 'resident-001',
      residentName: 'Nguyễn Minh Anh',
      title: 'Sự cố điện',
      description: 'Bị hỏng',
      location: 'Phòng ngủ',
      category: MaintenanceCategory.electrical,
      priority: MaintenancePriority.high,
    );

    expect(success, isFalse);
    expect(controller.errorMessage, contains('ít nhất 15 ký tự'));
  });

  test('kỹ thuật gửi kết quả và cư dân xác nhận hoàn thành', () async {
    await controller.load();

    expect(
      await controller.assignRequest(
        requestId: 'maintenance-005',
        assigneeId: 'technician-001',
        assigneeName: 'Lê Hoàng Kỹ Thuật',
        actorName: 'Trần Hoàng Nam',
      ),
      isTrue,
    );
    expect(
      controller.requestById('maintenance-005')?.status,
      MaintenanceStatus.received,
    );

    expect(
      await controller.updateStatus(
        requestId: 'maintenance-005',
        status: MaintenanceStatus.inProgress,
        note: 'Kỹ thuật viên đang kiểm tra chuông cửa.',
        actorName: 'Trần Hoàng Nam',
      ),
      isTrue,
    );
    expect(
      await controller.updateStatus(
        requestId: 'maintenance-005',
        status: MaintenanceStatus.waitingResident,
        note: 'Đã thay nút nhấn chuông cửa và kiểm tra hoạt động.',
        actorName: 'Lê Hoàng Kỹ Thuật',
      ),
      isTrue,
    );
    expect(
      controller.requestById('maintenance-005')?.status,
      MaintenanceStatus.waitingResident,
    );
    expect(
      await controller.respondToResult(
        requestId: 'maintenance-005',
        confirmed: true,
        note: '',
        actorName: 'Nguyễn Minh Anh',
      ),
      isTrue,
    );
    final completed = controller.requestById('maintenance-005');
    expect(completed?.status, MaintenanceStatus.completed);
    expect(completed?.history, hasLength(5));
    expect(completed?.history.last.actorName, 'Nguyễn Minh Anh');

    expect(
      await controller.updateStatus(
        requestId: 'maintenance-005',
        status: MaintenanceStatus.inProgress,
        note: 'Mở lại yêu cầu.',
        actorName: 'Trần Hoàng Nam',
      ),
      isFalse,
    );
    expect(controller.errorMessage, contains('Không thể chuyển'));
  });

  test('cư dân báo chưa khắc phục để mở lại yêu cầu', () async {
    await controller.load();

    expect(
      await controller.respondToResult(
        requestId: 'maintenance-003',
        confirmed: false,
        note: 'Ổ cắm vẫn mất điện sau vài phút sử dụng.',
        actorName: 'Lê Thu Hà',
      ),
      isTrue,
    );
    final reopened = controller.requestById('maintenance-003');
    expect(reopened?.status, MaintenanceStatus.inProgress);
    expect(reopened?.history.last.actorName, 'Lê Thu Hà');
    expect(reopened?.history.last.note, contains('chưa khắc phục'));
  });
}

class _FailingRefreshRepository extends MaintenanceRepositoryImpl {
  _FailingRefreshRepository(super.dataSource);

  bool failNextGet = false;

  @override
  Future<List<MaintenanceRequest>> getRequests() {
    if (failNextGet) {
      failNextGet = false;
      throw StateError('Internal server error');
    }
    return super.getRequests();
  }
}
