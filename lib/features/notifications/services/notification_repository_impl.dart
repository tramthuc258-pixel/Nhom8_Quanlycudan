import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/notifications/services/notification_repository.dart';
import 'package:homie/features/notifications/services/notification_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._dataSource);
  final NotificationDataSource _dataSource;

  @override
  Future<List<AppNotification>> getForUser(String userId) =>
      _dataSource.getForUser(userId);
  @override
  Future<void> markAsRead(String notificationId) =>
      _dataSource.markAsRead(notificationId);
  @override
  Future<void> markAllAsRead(String userId) =>
      _dataSource.markAllAsRead(userId);
}
