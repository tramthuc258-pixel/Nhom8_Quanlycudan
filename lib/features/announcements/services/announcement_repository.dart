import 'package:homie/features/announcements/models/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();

  Future<Announcement> createAnnouncement(Announcement announcement);

  Future<Announcement> togglePublished(String announcementId);

  Future<void> deleteAnnouncement(String announcementId);

  bool isRead(String announcementId, String userId);

  Future<void> markAsRead(String announcementId, String userId);

  Future<void> markAllAsRead(String userId, Iterable<String> announcementIds);
}
