import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/announcements/models/announcement_model.dart';

import 'announcement_data_source.dart';

class AnnouncementApiDataSource implements AnnouncementDataSource {
  AnnouncementApiDataSource(this._apiClient);

  final ApiClient _apiClient;
  final Map<String, Set<String>> _readIdsByUser = <String, Set<String>>{};

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final response = await _apiClient.get('/announcements');
      final userId = response['userId'];
      final items = response['items'];
      if (userId is! String || items is! List) {
        throw StateError('Dữ liệu thông báo không hợp lệ.');
      }
      final readIds = <String>{};
      final announcements = items
          .whereType<Map>()
          .map((item) {
            final map = Map<String, Object?>.from(item);
            if (map['isRead'] == true && map['id'] is String) {
              readIds.add(map['id']! as String);
            }
            return AnnouncementModel.fromMap(map);
          })
          .toList(growable: false);
      _readIdsByUser[userId] = readIds;
      return announcements;
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<AnnouncementModel> createAnnouncement(
    AnnouncementModel announcement,
  ) async {
    try {
      final response = await _apiClient.post(
        '/announcements',
        body: <String, Object?>{
          'title': announcement.title,
          'content': announcement.content,
          'category': announcement.category.name.toUpperCase(),
          'priority': announcement.priority.name.toUpperCase(),
          'audience': announcement.audience.name.toUpperCase(),
          'publishedAt': announcement.publishedAt.toIso8601String(),
          'expiresAt': announcement.expiresAt?.toIso8601String(),
          'isPinned': announcement.isPinned,
          'isPublished': announcement.isPublished,
          'buildingId': announcement.buildingId,
        },
      );
      return AnnouncementModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<AnnouncementModel> togglePublished(String announcementId) async {
    try {
      final response = await _apiClient.patch(
        '/announcements/$announcementId/toggle-published',
      );
      return AnnouncementModel.fromMap(response);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _apiClient.delete('/announcements/$announcementId');
      for (final readIds in _readIdsByUser.values) {
        readIds.remove(announcementId);
      }
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  bool isRead(String announcementId, String userId) {
    return _readIdsByUser[userId]?.contains(announcementId) ?? false;
  }

  @override
  Future<void> markAsRead(String announcementId, String userId) async {
    try {
      await _apiClient.patch('/announcements/$announcementId/read');
      _readIdsByUser.putIfAbsent(userId, () => <String>{}).add(announcementId);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<void> markAllAsRead(
    String userId,
    Iterable<String> announcementIds,
  ) async {
    final ids = announcementIds.toSet();
    try {
      await _apiClient.patch(
        '/announcements/read-all',
        body: <String, Object?>{'announcementIds': ids.toList()},
      );
      _readIdsByUser.putIfAbsent(userId, () => <String>{}).addAll(ids);
    } on ApiException catch (error) {
      throw StateError(error.message);
    }
  }
}
