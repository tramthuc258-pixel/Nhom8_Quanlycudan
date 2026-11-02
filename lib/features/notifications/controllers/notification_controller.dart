import 'package:flutter/foundation.dart';

import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/notifications/services/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({required this.repository});
  final NotificationRepository repository;
  bool _isLoading = false;
  String? _errorMessage;
  List<AppNotification> _notifications = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AppNotification> get notifications => _notifications;
  int unreadCountFor(String userId) => _notifications
      .where((item) => item.userId == userId && !item.isRead)
      .length;

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final items = await repository.getForUser(userId);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications = List.unmodifiable(items);
    } catch (_) {
      _errorMessage = 'Không thể tải thông báo lúc này.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id, String userId) async {
    await repository.markAsRead(id);
    await loadForUser(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    await repository.markAllAsRead(userId);
    await loadForUser(userId);
  }

  /// Đánh dấu đúng thông báo vừa được mở từ push notification.
  ///
  /// Push cũ có thể chưa chứa notificationId, vì vậy dùng referenceType và
  /// referenceId để tìm thông báo chưa đọc gần nhất làm phương án tương thích.
  Future<void> markOpenedNotificationAsRead({
    required String userId,
    String? notificationId,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      var resolvedId = notificationId;
      if (resolvedId == null || resolvedId.isEmpty) {
        if (referenceType == null ||
            referenceType.isEmpty ||
            referenceId == null ||
            referenceId.isEmpty) {
          return;
        }
        await loadForUser(userId);
        for (final item in _notifications) {
          if (!item.isRead &&
              item.referenceType == referenceType &&
              item.referenceId == referenceId) {
            resolvedId = item.id;
            break;
          }
        }
      }
      if (resolvedId == null || resolvedId.isEmpty) return;
      await repository.markAsRead(resolvedId);
      await loadForUser(userId);
    } catch (_) {
      // Việc đánh dấu đã đọc không được cản người dùng mở chức năng đích.
    }
  }
}
