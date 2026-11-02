import 'package:homie/features/announcements/models/announcement_model.dart';

abstract interface class AnnouncementDataSource {
  Future<List<AnnouncementModel>> getAnnouncements();

  Future<AnnouncementModel> createAnnouncement(AnnouncementModel announcement);

  Future<AnnouncementModel> togglePublished(String announcementId);

  Future<void> deleteAnnouncement(String announcementId);

  bool isRead(String announcementId, String userId);

  Future<void> markAsRead(String announcementId, String userId);

  Future<void> markAllAsRead(String userId, Iterable<String> announcementIds);
}
