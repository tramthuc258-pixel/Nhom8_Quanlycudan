import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/notifications/services/notification_data_source.dart';

class NotificationMockDataSource implements NotificationDataSource {
  NotificationMockDataSource() : _items = List<AppNotification>.of(_seedItems);

  final List<AppNotification> _items;

  static final List<AppNotification> _seedItems = <AppNotification>[
    AppNotification(
      id: 'notify-r-1',
      userId: 'resident-001',
      title: 'Hóa đơn tháng 10 đã được phát hành',
      message: 'Hóa đơn căn A-1205 có hạn thanh toán đến 25/10/2026.',
      type: AppNotificationType.invoice,
      createdAt: DateTime(2026, 10, 16, 8, 30),
    ),
    AppNotification(
      id: 'notify-r-2',
      userId: 'resident-001',
      title: 'Yêu cầu bảo trì đang được xử lý',
      message:
          'Ban quản lý đã tiếp nhận yêu cầu kiểm tra đường ống bếp của bạn.',
      type: AppNotificationType.maintenance,
      createdAt: DateTime(2026, 10, 15, 14, 20),
    ),
    AppNotification(
      id: 'notify-r-3',
      userId: 'resident-001',
      title: 'Lịch tiện ích được duyệt',
      message:
          'Lịch sử dụng Phòng sinh hoạt cộng đồng của bạn đã được xác nhận.',
      type: AppNotificationType.amenity,
      createdAt: DateTime(2026, 10, 14, 9),
    ),
    AppNotification(
      id: 'notify-m-1',
      userId: 'manager-001',
      title: 'Có yêu cầu bảo trì mới',
      message: 'Cư dân Nguyễn Minh Anh vừa gửi yêu cầu kiểm tra đường ống tại A-1205.',
      type: AppNotificationType.maintenance,
      createdAt: DateTime(2026, 10, 16, 9, 5),
    ),
    AppNotification(
      id: 'notify-m-2',
      userId: 'manager-001',
      title: 'Có yêu cầu đặt tiện ích mới',
      message:
          'Một cư dân đang chờ duyệt lịch sử dụng Phòng sinh hoạt cộng đồng.',
      type: AppNotificationType.amenity,
      createdAt: DateTime(2026, 10, 15, 16, 10),
    ),
    AppNotification(
      id: 'notify-m-3',
      userId: 'manager-001',
      title: 'Có hồ sơ thuê căn hộ mới',
      message: 'Một yêu cầu thuê căn hộ đang chờ Ban quản lý xem xét.',
      type: AppNotificationType.housing,
      createdAt: DateTime(2026, 10, 14, 10),
      isRead: true,
    ),
  ];

  @override
  Future<List<AppNotification>> getForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _items.where((item) => item.userId == userId).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _items.indexWhere((item) => item.id == notificationId);
    if (index < 0) throw StateError('Không tìm thấy thông báo.');
    _items[index] = _items[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var index = 0; index < _items.length; index++) {
      if (_items[index].userId == userId && !_items[index].isRead) {
        _items[index] = _items[index].copyWith(isRead: true);
      }
    }
  }
}
