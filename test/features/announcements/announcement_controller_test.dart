import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/announcements/services/announcement_mock_data_source.dart';
import 'package:homie/features/announcements/services/announcement_repository_impl.dart';
import 'package:homie/features/announcements/controllers/announcement_controller.dart';
import 'package:homie/features/auth/models/user.dart';

void main() {
  const resident = User(
    id: 'resident-001',
    fullName: 'Nguyễn Minh Anh',
    email: 'anh.resident@homie.com',
    role: UserRole.resident,
    apartmentCode: 'A-1205',
  );
  const manager = User(
    id: 'manager-001',
    fullName: 'Trần Hoàng Nam',
    email: 'nam.management@homie.com',
    role: UserRole.manager,
  );

  late AnnouncementController controller;

  setUp(() {
    controller = AnnouncementController(
      repository: AnnouncementRepositoryImpl(AnnouncementMockDataSource()),
    );
  });

  tearDown(() => controller.dispose());

  test('chỉ trả thông báo đã phát hành đúng nhóm người nhận', () async {
    await controller.load();

    final residentItems = controller.publishedForUser(resident);
    final managerItems = controller.publishedForUser(manager);

    expect(residentItems, isNotEmpty);
    expect(
      residentItems.every((item) => item.isVisibleTo(resident.role)),
      isTrue,
    );
    expect(residentItems.every((item) => item.isActive), isTrue);
    expect(
      managerItems.every((item) => item.isVisibleTo(manager.role)),
      isTrue,
    );
    expect(
      residentItems.any((item) => item.title.contains('Họp điều phối')),
      isFalse,
    );
    expect(
      managerItems.any((item) => item.title.contains('Họp điều phối')),
      isTrue,
    );
  });

  test('đánh dấu đã đọc làm giảm số thông báo chưa đọc', () async {
    await controller.load();
    final first = controller.publishedForUser(resident).first;
    final before = controller.unreadCountForUser(resident);

    final success = await controller.markAsRead(first.id, resident.id);

    expect(success, isTrue);
    expect(controller.isRead(first.id, resident.id), isTrue);
    expect(controller.unreadCountForUser(resident), before - 1);
  });

  test('ban quản lý tạo, ẩn và xóa thông báo', () async {
    await controller.load();

    final created = await controller.createAnnouncement(
      title: 'Thông báo kiểm thử mới',
      content: 'Nội dung thông báo đủ dài để vượt qua bước kiểm tra dữ liệu.',
      category: AnnouncementCategory.general,
      priority: AnnouncementPriority.important,
      audience: AnnouncementAudience.residents,
      publishedAt: DateTime.now(),
      isPinned: true,
      isPublished: true,
      authorName: manager.fullName,
    );
    expect(created, isTrue);

    final announcement = controller.announcements.singleWhere(
      (item) => item.title == 'Thông báo kiểm thử mới',
    );
    expect(controller.publishedForUser(resident), contains(announcement));

    expect(await controller.togglePublished(announcement.id), isTrue);
    expect(
      controller
          .publishedForUser(resident)
          .any((item) => item.id == announcement.id),
      isFalse,
    );

    expect(await controller.deleteAnnouncement(announcement.id), isTrue);
    expect(
      controller.announcements.any((item) => item.id == announcement.id),
      isFalse,
    );
  });

  test('không tạo thông báo có dữ liệu không hợp lệ', () async {
    await controller.load();

    final success = await controller.createAnnouncement(
      title: 'Ngắn',
      content: 'Thiếu',
      category: AnnouncementCategory.general,
      priority: AnnouncementPriority.normal,
      audience: AnnouncementAudience.all,
      authorName: manager.fullName,
    );

    expect(success, isFalse);
    expect(controller.errorMessage, isNotNull);
  });
}
