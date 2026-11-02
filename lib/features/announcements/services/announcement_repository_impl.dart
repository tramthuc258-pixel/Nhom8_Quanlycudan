import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/services/announcement_repository.dart';
import 'package:homie/features/announcements/services/announcement_data_source.dart';

import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl(this._dataSource);

  final AnnouncementDataSource _dataSource;

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final announcements = await _dataSource.getAnnouncements();
    return List<Announcement>.unmodifiable(announcements);
  }

  @override
  Future<Announcement> createAnnouncement(Announcement announcement) {
    return _dataSource.createAnnouncement(
      AnnouncementModel.fromEntity(announcement),
    );
  }

  @override
  Future<Announcement> togglePublished(String announcementId) {
    return _dataSource.togglePublished(announcementId);
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) {
    return _dataSource.deleteAnnouncement(announcementId);
  }

  @override
  bool isRead(String announcementId, String userId) {
    return _dataSource.isRead(announcementId, userId);
  }

  @override
  Future<void> markAsRead(String announcementId, String userId) {
    return _dataSource.markAsRead(announcementId, userId);
  }

  @override
  Future<void> markAllAsRead(String userId, Iterable<String> announcementIds) {
    return _dataSource.markAllAsRead(userId, announcementIds);
  }
}
