import 'package:flutter/foundation.dart';

import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/services/announcement_repository.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController({required this.repository});

  final AnnouncementRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Announcement> _announcements = const <Announcement>[];

  bool get isLoading => _isLoading;
  bool get loading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;
  List<Announcement> get announcements => _announcements;

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _refreshAnnouncements();
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Announcement> publishedForUser(User user) {
    final result = _announcements.where((announcement) {
      return announcement.isActive && announcement.isVisibleTo(user.role);
    }).toList()..sort(_compareAnnouncements);

    return List<Announcement>.unmodifiable(result);
  }

  int unreadCountForUser(User user) {
    return publishedForUser(user)
        .where((announcement) => !isRead(announcement.id, user.id))
        .length;
  }

  bool isRead(String announcementId, String userId) {
    return repository.isRead(announcementId, userId);
  }

  Future<bool> markAsRead(String announcementId, String userId) async {
    if (repository.isRead(announcementId, userId)) return true;

    try {
      await repository.markAsRead(announcementId, userId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      final visibleIds = _announcements
          .where((announcement) => announcement.isActive)
          .map((announcement) => announcement.id);
      await repository.markAllAsRead(userId, visibleIds);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementCategory category,
    required AnnouncementPriority priority,
    required AnnouncementAudience audience,
    String? buildingId,
    DateTime? publishedAt,
    DateTime? publishAt,
    DateTime? expiresAt,
    bool isPinned = false,
    bool isPublished = true,
    String authorName = 'Ban quản lý Homie',
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectivePublishedAt = publishedAt ?? publishAt ?? DateTime.now();
      _validateAnnouncement(
        title: title,
        content: content,
        publishedAt: effectivePublishedAt,
        expiresAt: expiresAt,
        authorName: authorName,
      );

      final id = 'announcement-${DateTime.now().microsecondsSinceEpoch}';
      await repository.createAnnouncement(
        Announcement(
          id: id,
          title: title.trim(),
          content: content.trim(),
          category: category,
          priority: priority,
          audience: audience,
          publishedAt: effectivePublishedAt,
          expiresAt: expiresAt,
          isPinned: isPinned,
          isPublished: isPublished,
          authorName: authorName.trim(),
          buildingId: buildingId,
        ),
      );
      await _refreshAnnouncements();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> togglePublished(String id) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.togglePublished(id);
      await _refreshAnnouncements();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.deleteAnnouncement(id);
      await _refreshAnnouncements();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshAnnouncements() async {
    final items = List<Announcement>.from(await repository.getAnnouncements())
      ..sort(_compareAnnouncements);
    _announcements = List<Announcement>.unmodifiable(items);
  }

  int _compareAnnouncements(Announcement first, Announcement second) {
    if (first.isPinned != second.isPinned) {
      return first.isPinned ? -1 : 1;
    }
    final priorityComparison = first.priority.sortOrder.compareTo(
      second.priority.sortOrder,
    );
    if (priorityComparison != 0) return priorityComparison;
    return second.publishedAt.compareTo(first.publishedAt);
  }

  void _validateAnnouncement({
    required String title,
    required String content,
    required DateTime publishedAt,
    required DateTime? expiresAt,
    required String authorName,
  }) {
    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();
    if (normalizedTitle.length < 5) {
      throw ArgumentError('Tiêu đề phải có ít nhất 5 ký tự.');
    }
    if (normalizedTitle.length > 120) {
      throw ArgumentError('Tiêu đề không được vượt quá 120 ký tự.');
    }
    if (normalizedContent.length < 10) {
      throw ArgumentError('Nội dung phải có ít nhất 10 ký tự.');
    }
    if (normalizedContent.length > 2000) {
      throw ArgumentError('Nội dung không được vượt quá 2000 ký tự.');
    }
    if (authorName.trim().isEmpty) {
      throw ArgumentError('Tên người đăng không được để trống.');
    }
    if (expiresAt != null && !expiresAt.isAfter(publishedAt)) {
      throw ArgumentError('Ngày hết hạn phải sau ngày phát hành.');
    }
  }

  String _messageFor(Object error) {
    return switch (error) {
      StateError(message: final message) => message,
      ArgumentError(message: final Object? message) =>
        message?.toString() ?? 'Dữ liệu thông báo không hợp lệ.',
      _ => 'Không thể cập nhật thông báo. Vui lòng thử lại.',
    };
  }
}
