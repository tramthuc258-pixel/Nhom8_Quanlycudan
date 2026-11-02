import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/notifications/controllers/notification_controller.dart';
import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/notifications/services/notification_repository.dart';

void main() {
  test('đánh dấu thông báo push bằng notificationId', () async {
    final repository = _FakeNotificationRepository(_items());
    final controller = NotificationController(repository: repository);

    await controller.markOpenedNotificationAsRead(
      userId: 'resident-1',
      notificationId: 'notification-old',
      referenceType: 'invoice',
      referenceId: 'invoice-1',
    );

    expect(repository.markedIds, ['notification-old']);
    expect(
      controller.notifications
          .singleWhere((item) => item.id == 'notification-old')
          .isRead,
      isTrue,
    );
  });

  test(
    'push cũ không có notificationId dùng bản ghi cùng tham chiếu mới nhất',
    () async {
      final repository = _FakeNotificationRepository(_items());
      final controller = NotificationController(repository: repository);

      await controller.markOpenedNotificationAsRead(
        userId: 'resident-1',
        referenceType: 'invoice',
        referenceId: 'invoice-1',
      );

      expect(repository.markedIds, ['notification-new']);
    },
  );

  test('push thiếu cả id và tham chiếu không đánh dấu nhầm', () async {
    final repository = _FakeNotificationRepository(_items());
    final controller = NotificationController(repository: repository);

    await controller.markOpenedNotificationAsRead(userId: 'resident-1');

    expect(repository.markedIds, isEmpty);
  });
}

List<AppNotification> _items() => <AppNotification>[
  AppNotification(
    id: 'notification-old',
    userId: 'resident-1',
    title: 'Hóa đơn cũ',
    message: 'Cập nhật trước',
    type: AppNotificationType.invoice,
    referenceType: 'invoice',
    referenceId: 'invoice-1',
    createdAt: DateTime(2026, 10, 1),
  ),
  AppNotification(
    id: 'notification-new',
    userId: 'resident-1',
    title: 'Hóa đơn mới',
    message: 'Cập nhật mới nhất',
    type: AppNotificationType.invoice,
    referenceType: 'invoice',
    referenceId: 'invoice-1',
    createdAt: DateTime(2026, 10, 2),
  ),
];

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository(this.items);

  final List<AppNotification> items;
  final List<String> markedIds = <String>[];

  @override
  Future<List<AppNotification>> getForUser(String userId) async =>
      items.where((item) => item.userId == userId).toList(growable: false);

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var index = 0; index < items.length; index++) {
      if (items[index].userId == userId) {
        items[index] = items[index].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    markedIds.add(notificationId);
    final index = items.indexWhere((item) => item.id == notificationId);
    if (index < 0) throw StateError('Không tìm thấy thông báo.');
    items[index] = items[index].copyWith(isRead: true);
  }
}
