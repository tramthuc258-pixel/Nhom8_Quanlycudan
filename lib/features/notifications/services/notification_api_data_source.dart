import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/notifications/services/notification_data_source.dart';

class NotificationApiDataSource implements NotificationDataSource {
  const NotificationApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<AppNotification>> getForUser(String userId) async {
    try {
      final response = await _apiClient.get('/notifications');
      final items = response['items'];
      if (items is! List) {
        throw StateError('Dữ liệu thông báo không hợp lệ.');
      }
      return items
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromMap(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.patch('/notifications/$notificationId/read');
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _apiClient.patch('/notifications/read-all');
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }
}
