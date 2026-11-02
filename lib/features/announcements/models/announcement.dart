import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/core/enums/user_role.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.audience,
    required this.publishedAt,
    required this.isPinned,
    required this.isPublished,
    required this.authorName,
    this.buildingId,
    this.buildingName,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String content;
  final AnnouncementCategory category;
  final AnnouncementPriority priority;
  final AnnouncementAudience audience;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isPinned;
  final bool isPublished;
  final String authorName;
  final String? buildingId;
  final String? buildingName;

  bool get isGlobal => buildingId == null;

  /// Alias thuận tiện cho các màn hình gọi ngày phát hành là `publishAt`.
  DateTime get publishAt => publishedAt;

  /// Mock hiện chưa quản lý ngày tạo riêng, nên ngày tạo trùng ngày phát hành.
  DateTime get createdAt => publishedAt;

  bool get isExpired {
    final expiration = expiresAt;
    return expiration != null && !expiration.isAfter(DateTime.now());
  }

  bool get isActive {
    final now = DateTime.now();
    return isPublished &&
        !publishedAt.isAfter(now) &&
        (expiresAt == null || expiresAt!.isAfter(now));
  }

  bool isVisibleTo(UserRole role) => audience.includes(role);

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    AnnouncementCategory? category,
    AnnouncementPriority? priority,
    AnnouncementAudience? audience,
    DateTime? publishedAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    bool? isPinned,
    bool? isPublished,
    String? authorName,
    String? buildingId,
    bool clearBuilding = false,
    String? buildingName,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      audience: audience ?? this.audience,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
      isPinned: isPinned ?? this.isPinned,
      isPublished: isPublished ?? this.isPublished,
      authorName: authorName ?? this.authorName,
      buildingId: clearBuilding ? null : buildingId ?? this.buildingId,
      buildingName: clearBuilding ? null : buildingName ?? this.buildingName,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Announcement &&
            other.id == id &&
            other.title == title &&
            other.content == content &&
            other.category == category &&
            other.priority == priority &&
            other.audience == audience &&
            other.publishedAt == publishedAt &&
            other.expiresAt == expiresAt &&
            other.isPinned == isPinned &&
            other.isPublished == isPublished &&
            other.authorName == authorName &&
            other.buildingId == buildingId &&
            other.buildingName == buildingName;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    category,
    priority,
    audience,
    publishedAt,
    expiresAt,
    isPinned,
    isPublished,
    authorName,
    buildingId,
    buildingName,
  );
}
