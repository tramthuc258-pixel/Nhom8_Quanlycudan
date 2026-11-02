import 'package:homie/features/notifications/models/app_notification.dart';

abstract interface class NotificationDataSource {
  Future<List<AppNotification>> getForUser(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
