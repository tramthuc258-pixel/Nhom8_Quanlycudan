import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';

import '../models/maintenance_request_model.dart';
import 'maintenance_data_source.dart';

import 'package:homie/core/models/work_assignee.dart';

class MaintenanceMockDataSource implements MaintenanceDataSource {
  MaintenanceMockDataSource({this.referenceTime}) : _requests = _seed();

  final DateTime? referenceTime;
  final List<MaintenanceRequestModel> _requests;
  int _sequence = 1006;

  DateTime get _now => referenceTime ?? DateTime.now();

  @override
  Future<List<MaintenanceRequestModel>> getRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List<MaintenanceRequestModel>.unmodifiable(_requests);
  }

  @override
  Future<List<WorkAssignee>> getAssignees(String requestId) async => const [
    WorkAssignee(
      id: 'technician-001',
      fullName: 'Lê Hoàng Kỹ Thuật',
      email: 'kythuat.le@homie.com',
      roles: ['TECHNICIAN'],
    ),
  ];

  @override
  Future<MaintenanceRequestModel> createRequest({
    required String apartmentId,
    required String residentId,
    required String residentName,
    required String title,
    required String description,
    required String location,
    required MaintenanceCategory category,
    required MaintenancePriority priority,
    List<String> imageUrls = const <String>[],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _validateText(title: title, description: description, location: location);
    if (apartmentId.trim().isEmpty || residentId.trim().isEmpty) {
      throw ArgumentError('Không xác định được căn hộ hoặc người gửi yêu cầu.');
    }

    final now = _now;
    final sequence = _sequence++;
    final code = 'YC-${now.year}-${sequence.toString().padLeft(4, '0')}';
    final request = MaintenanceRequestModel(
      id: 'maintenance-${now.microsecondsSinceEpoch}-$sequence',
      code: code,
      apartmentId: apartmentId.trim(),
      residentId: residentId.trim(),
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      category: category,
      priority: priority,
      status: MaintenanceStatus.submitted,
      createdAt: now,
      updatedAt: now,
      imageUrls: List<String>.unmodifiable(imageUrls),
      history: <MaintenanceUpdate>[
        MaintenanceUpdate(
          id: 'update-$sequence-1',
          status: MaintenanceStatus.submitted,
          note: 'Yêu cầu đã được gửi đến ban quản lý.',
          actorName: residentName.trim(),
          createdAt: now,
        ),
      ],
    );
    _requests.add(request);
    return request;
  }

  @override
  Future<MaintenanceRequestModel> assignRequest({
    required String requestId,
    required String assigneeId,
    required String assigneeName,
    required String actorName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (assigneeId.isEmpty || assigneeName.trim().length < 3) {
      throw ArgumentError('Vui lòng chọn kỹ thuật viên phụ trách.');
    }
    final index = _indexOf(requestId);
    final current = _requests[index];
    if (!current.status.isOpen) {
      throw StateError('Không thể phân công yêu cầu đã kết thúc.');
    }
    final now = _now;
    final nextStatus = current.status == MaintenanceStatus.submitted
        ? MaintenanceStatus.received
        : current.status;
    final updated = current.copyWith(
      status: nextStatus,
      assignedTo: assigneeName.trim(),
      assignedToId: assigneeId,
      updatedAt: now,
      history: <MaintenanceUpdate>[
        ...current.history,
        MaintenanceUpdate(
          id: 'update-${now.microsecondsSinceEpoch}',
          status: nextStatus,
          note: 'Đã phân công cho ${assigneeName.trim()}.',
          actorName: actorName.trim(),
          createdAt: now,
        ),
      ],
    );
    return _replace(index, updated);
  }

  @override
  Future<MaintenanceRequestModel> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
    required String note,
    required String actorName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final index = _indexOf(requestId);
    final current = _requests[index];
    if (current.status == status) {
      throw StateError('Yêu cầu đang ở trạng thái này.');
    }
    if (!_canTransition(current.status, status)) {
      throw StateError(
        'Không thể chuyển từ “${current.status.label}” sang “${status.label}”.',
      );
    }
    if ((status == MaintenanceStatus.completed ||
            status == MaintenanceStatus.waitingResident) &&
        note.trim().length < 5) {
      throw ArgumentError('Vui lòng nhập ghi chú cập nhật ít nhất 5 ký tự.');
    }
    final now = _now;
    final updated = current.copyWith(
      status: status,
      updatedAt: now,
      history: <MaintenanceUpdate>[
        ...current.history,
        MaintenanceUpdate(
          id: 'update-${now.microsecondsSinceEpoch}',
          status: status,
          note: note.trim().isEmpty
              ? 'Trạng thái được cập nhật thành ${status.label}.'
              : note.trim(),
          actorName: actorName.trim(),
          createdAt: now,
        ),
      ],
    );
    return _replace(index, updated);
  }

  @override
  Future<MaintenanceRequestModel> respondToResult({
    required String requestId,
    required bool confirmed,
    required String note,
    required String actorName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final index = _indexOf(requestId);
    final current = _requests[index];
    if (current.status != MaintenanceStatus.waitingResident) {
      throw StateError('Yêu cầu chưa ở trạng thái chờ cư dân xác nhận.');
    }
    if (!confirmed && note.trim().length < 5) {
      throw ArgumentError(
        'Vui lòng mô tả vấn đề chưa được khắc phục ít nhất 5 ký tự.',
      );
    }
    final now = _now;
    final status = confirmed
        ? MaintenanceStatus.completed
        : MaintenanceStatus.inProgress;
    final effectiveNote = confirmed
        ? note.trim().isEmpty
              ? 'Cư dân xác nhận sự cố đã được khắc phục.'
              : note.trim()
        : 'Cư dân phản hồi chưa khắc phục: ${note.trim()}';
    return _replace(
      index,
      current.copyWith(
        status: status,
        updatedAt: now,
        history: <MaintenanceUpdate>[
          ...current.history,
          MaintenanceUpdate(
            id: 'update-${now.microsecondsSinceEpoch}',
            status: status,
            note: effectiveNote,
            actorName: actorName.trim(),
            createdAt: now,
          ),
        ],
      ),
    );
  }

  MaintenanceRequestModel _replace(int index, MaintenanceRequest request) {
    final model = MaintenanceRequestModel.fromEntity(request);
    _requests[index] = model;
    return model;
  }

  int _indexOf(String requestId) {
    final index = _requests.indexWhere((request) => request.id == requestId);
    if (index < 0) throw StateError('Không tìm thấy yêu cầu cần cập nhật.');
    return index;
  }

  bool _canTransition(MaintenanceStatus from, MaintenanceStatus to) {
    return switch (from) {
      MaintenanceStatus.submitted =>
        to == MaintenanceStatus.received || to == MaintenanceStatus.cancelled,
      MaintenanceStatus.received =>
        to == MaintenanceStatus.inProgress ||
            to == MaintenanceStatus.waitingResident ||
            to == MaintenanceStatus.cancelled,
      MaintenanceStatus.inProgress =>
        to == MaintenanceStatus.waitingResident ||
            to == MaintenanceStatus.cancelled,
      MaintenanceStatus.waitingResident => to == MaintenanceStatus.cancelled,
      MaintenanceStatus.completed || MaintenanceStatus.cancelled => false,
    };
  }

  void _validateText({
    required String title,
    required String description,
    required String location,
  }) {
    if (title.trim().length < 5) {
      throw ArgumentError('Tiêu đề phải có ít nhất 5 ký tự.');
    }
    if (description.trim().length < 15) {
      throw ArgumentError('Mô tả phải có ít nhất 15 ký tự.');
    }
    if (location.trim().length < 3) {
      throw ArgumentError('Vui lòng nhập vị trí xảy ra sự cố.');
    }
  }

  static List<MaintenanceRequestModel> _seed() {
    MaintenanceUpdate update(
      String id,
      MaintenanceStatus status,
      String note,
      String actor,
      DateTime time,
    ) => MaintenanceUpdate(
      id: id,
      status: status,
      note: note,
      actorName: actor,
      createdAt: time,
    );

    return <MaintenanceRequestModel>[
      MaintenanceRequestModel(
        id: 'maintenance-001',
        code: 'YC-2026-1001',
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        title: 'Vòi nước bếp bị rò rỉ',
        description: 'Vòi nước dưới bồn rửa bị rò liên tục và làm ướt tủ bếp.',
        location: 'Bếp căn hộ A-1205',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.inProgress,
        createdAt: DateTime(2026, 10, 14, 8, 25),
        updatedAt: DateTime(2026, 10, 15, 9, 10),
        assignedTo: 'Đội kỹ thuật nước',
        history: <MaintenanceUpdate>[
          update(
            'u-001',
            MaintenanceStatus.submitted,
            'Đã gửi yêu cầu.',
            'Nguyễn Minh Anh',
            DateTime(2026, 10, 14, 8, 25),
          ),
          update(
            'u-002',
            MaintenanceStatus.received,
            'Ban quản lý đã tiếp nhận và kiểm tra thông tin.',
            'Trần Hoàng Nam',
            DateTime(2026, 10, 14, 9, 5),
          ),
          update(
            'u-003',
            MaintenanceStatus.inProgress,
            'Kỹ thuật viên dự kiến đến lúc 14:00.',
            'Đội kỹ thuật nước',
            DateTime(2026, 10, 15, 9, 10),
          ),
        ],
      ),
      MaintenanceRequestModel(
        id: 'maintenance-002',
        code: 'YC-2026-1002',
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        title: 'Đèn hành lang trước căn hộ chập chờn',
        description:
            'Đèn hành lang trước cửa căn A-1205 chập chờn vào buổi tối.',
        location: 'Hành lang tầng 12',
        category: MaintenanceCategory.commonArea,
        priority: MaintenancePriority.normal,
        status: MaintenanceStatus.completed,
        createdAt: DateTime(2026, 10, 5, 19, 30),
        updatedAt: DateTime(2026, 10, 7, 11, 20),
        assignedTo: 'Đội điện tòa A',
        history: <MaintenanceUpdate>[
          update(
            'u-004',
            MaintenanceStatus.submitted,
            'Đã gửi yêu cầu.',
            'Nguyễn Minh Anh',
            DateTime(2026, 10, 5, 19, 30),
          ),
          update(
            'u-005',
            MaintenanceStatus.received,
            'Đã tiếp nhận phản ánh.',
            'Trần Hoàng Nam',
            DateTime(2026, 10, 6, 8, 10),
          ),
          update(
            'u-006',
            MaintenanceStatus.inProgress,
            'Đã phân công đội điện kiểm tra.',
            'Ban kỹ thuật',
            DateTime(2026, 10, 6, 9, 15),
          ),
          update(
            'u-007',
            MaintenanceStatus.completed,
            'Đã thay bóng và kiểm tra đường điện.',
            'Đội điện tòa A',
            DateTime(2026, 10, 7, 11, 20),
          ),
        ],
      ),
      MaintenanceRequestModel(
        id: 'maintenance-003',
        code: 'YC-2026-1003',
        apartmentId: 'apartment-002',
        residentId: 'resident-003',
        title: 'Ổ cắm phòng ngủ không có điện',
        description:
            'Hai ổ cắm cạnh giường không hoạt động dù aptomat vẫn bật.',
        location: 'Phòng ngủ chính căn A-1002',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.high,
        status: MaintenanceStatus.waitingResident,
        createdAt: DateTime(2026, 10, 15, 7, 50),
        updatedAt: DateTime(2026, 10, 15, 14, 30),
        assignedTo: 'Đội điện tòa A',
        history: <MaintenanceUpdate>[
          update(
            'u-008',
            MaintenanceStatus.submitted,
            'Đã gửi yêu cầu.',
            'Lê Thu Hà',
            DateTime(2026, 10, 15, 7, 50),
          ),
          update(
            'u-009',
            MaintenanceStatus.received,
            'Ban quản lý đã tiếp nhận.',
            'Trần Hoàng Nam',
            DateTime(2026, 10, 15, 8, 15),
          ),
          update(
            'u-010',
            MaintenanceStatus.waitingResident,
            'Đã thay ổ cắm và kiểm tra nguồn điện hoạt động ổn định.',
            'Đội điện tòa A',
            DateTime(2026, 10, 15, 14, 30),
          ),
        ],
      ),
      MaintenanceRequestModel(
        id: 'maintenance-004',
        code: 'YC-2026-1004',
        apartmentId: 'apartment-004',
        residentId: 'resident-005',
        title: 'Thang máy tòa B phát tiếng động lạ',
        description:
            'Thang máy số 2 rung và phát tiếng động khi đi qua tầng 10.',
        location: 'Thang máy số 2 tòa B',
        category: MaintenanceCategory.elevator,
        priority: MaintenancePriority.urgent,
        status: MaintenanceStatus.received,
        createdAt: DateTime(2026, 10, 16, 6, 45),
        updatedAt: DateTime(2026, 10, 16, 7, 5),
        assignedTo: 'Đơn vị bảo trì thang máy',
        history: <MaintenanceUpdate>[
          update(
            'u-011',
            MaintenanceStatus.submitted,
            'Đã gửi phản ánh khẩn.',
            'Phạm Gia Huy',
            DateTime(2026, 10, 16, 6, 45),
          ),
          update(
            'u-012',
            MaintenanceStatus.received,
            'Đã khóa thang số 2 và liên hệ đơn vị bảo trì.',
            'Trần Hoàng Nam',
            DateTime(2026, 10, 16, 7, 5),
          ),
        ],
      ),
      MaintenanceRequestModel(
        id: 'maintenance-005',
        code: 'YC-2026-1005',
        apartmentId: 'apartment-001',
        residentId: 'resident-001',
        title: 'Kiểm tra chuông cửa căn hộ',
        description:
            'Chuông cửa đôi lúc không phát âm thanh khi khách nhấn nút.',
        location: 'Cửa chính căn A-1205',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.low,
        status: MaintenanceStatus.submitted,
        createdAt: DateTime(2026, 10, 16, 8, 40),
        updatedAt: DateTime(2026, 10, 16, 8, 40),
        history: <MaintenanceUpdate>[
          update(
            'u-013',
            MaintenanceStatus.submitted,
            'Đã gửi yêu cầu.',
            'Nguyễn Minh Anh',
            DateTime(2026, 10, 16, 8, 40),
          ),
        ],
      ),
    ];
  }
}
