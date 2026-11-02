import 'package:homie/features/notifications/models/app_notification.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getForUser(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
