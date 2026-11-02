import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/features/announcements/models/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.category,
    required super.priority,
    required super.audience,
    required super.publishedAt,
    required super.isPinned,
    required super.isPublished,
    required super.authorName,
    super.buildingId,
    super.buildingName,
    super.expiresAt,
  });

  factory AnnouncementModel.fromEntity(Announcement announcement) {
    return AnnouncementModel(
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      category: announcement.category,
      priority: announcement.priority,
      audience: announcement.audience,
      publishedAt: announcement.publishedAt,
      expiresAt: announcement.expiresAt,
      isPinned: announcement.isPinned,
      isPublished: announcement.isPublished,
      authorName: announcement.authorName,
      buildingId: announcement.buildingId,
      buildingName: announcement.buildingName,
    );
  }

  factory AnnouncementModel.fromMap(Map<String, Object?> map) {
    final expiresAtValue = map['expiresAt'] as String?;
    return AnnouncementModel(
      id: map['id']! as String,
      title: map['title']! as String,
      content: map['content']! as String,
      category: AnnouncementCategory.values.byName(map['category']! as String),
      priority: AnnouncementPriority.values.byName(map['priority']! as String),
      audience: AnnouncementAudience.values.byName(map['audience']! as String),
      publishedAt: DateTime.parse(map['publishedAt']! as String),
      expiresAt: expiresAtValue == null ? null : DateTime.parse(expiresAtValue),
      isPinned: map['isPinned']! as bool,
      isPublished: map['isPublished']! as bool,
      authorName: map['authorName']! as String,
      buildingId: map['buildingId'] as String?,
      buildingName: map['buildingName'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'content': content,
      'category': category.name,
      'priority': priority.name,
      'audience': audience.name,
      'publishedAt': publishedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isPinned': isPinned,
      'isPublished': isPublished,
      'authorName': authorName,
      'buildingId': buildingId,
      'buildingName': buildingName,
    };
  }
}
