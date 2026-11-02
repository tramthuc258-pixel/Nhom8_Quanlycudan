import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';

import '../models/announcement_model.dart';
import 'announcement_data_source.dart';

class AnnouncementMockDataSource implements AnnouncementDataSource {
  AnnouncementMockDataSource({DateTime? referenceTime})
    : _announcements = _seed(referenceTime ?? DateTime.now());

  final List<AnnouncementModel> _announcements;
  final Map<String, Set<String>> _readIdsByUser = <String, Set<String>>{};

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<AnnouncementModel>.unmodifiable(_announcements);
  }

  @override
  Future<AnnouncementModel> createAnnouncement(
    AnnouncementModel announcement,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (_announcements.any((item) => item.id == announcement.id)) {
      throw StateError('Mã thông báo đã tồn tại.');
    }
    _announcements.add(announcement);
    return announcement;
  }

  @override
  Future<AnnouncementModel> togglePublished(String announcementId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _indexOf(announcementId);
    final current = _announcements[index];
    final updated = AnnouncementModel.fromEntity(
      current.copyWith(isPublished: !current.isPublished),
    );
    _announcements[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _indexOf(announcementId);
    _announcements.removeAt(index);
    for (final readIds in _readIdsByUser.values) {
      readIds.remove(announcementId);
    }
  }

  @override
  bool isRead(String announcementId, String userId) {
    return _readIdsByUser[userId]?.contains(announcementId) ?? false;
  }

  @override
  Future<void> markAsRead(String announcementId, String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    _indexOf(announcementId);
    _readIdsByUser.putIfAbsent(userId, () => <String>{}).add(announcementId);
  }

  @override
  Future<void> markAllAsRead(
    String userId,
    Iterable<String> announcementIds,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final knownIds = _announcements.map((item) => item.id).toSet();
    final ids = announcementIds.where(knownIds.contains);
    _readIdsByUser.putIfAbsent(userId, () => <String>{}).addAll(ids);
  }

  int _indexOf(String announcementId) {
    final index = _announcements.indexWhere(
      (item) => item.id == announcementId,
    );
    if (index == -1) {
      throw StateError('Không tìm thấy thông báo.');
    }
    return index;
  }

  static List<AnnouncementModel> _seed(DateTime now) {
    DateTime ago({int days = 0, int hours = 0}) {
      return now.subtract(Duration(days: days, hours: hours));
    }

    return <AnnouncementModel>[
      AnnouncementModel(
        id: 'announcement-001',
        title: 'Tạm ngưng cấp nước khẩn cấp tại tòa A',
        content: 'Ban quản lý tạm ngưng cấp nước từ 13:30 đến 16:30 hôm nay để xử lý sự cố đường ống chính. Mong cư dân chủ động dự trữ nước.',
        category: AnnouncementCategory.emergency,
        priority: AnnouncementPriority.urgent,
        audience: AnnouncementAudience.residents,
        publishedAt: ago(hours: 2),
        expiresAt: now.add(const Duration(days: 1)),
        isPinned: true,
        isPublished: true,
        authorName: 'Ban quản lý Homie',
      ),
      AnnouncementModel(
        id: 'announcement-002',
        title: 'Lịch bảo trì thang máy tòa B',
        content: 'Thang máy số 2 tại tòa B sẽ được bảo trì định kỳ từ 08:00 đến 11:30 thứ Bảy. Cư dân vui lòng sử dụng thang máy số 1.',
        category: AnnouncementCategory.maintenance,
        priority: AnnouncementPriority.important,
        audience: AnnouncementAudience.all,
        publishedAt: ago(days: 1),
        expiresAt: now.add(const Duration(days: 5)),
        isPinned: true,
        isPublished: true,
        authorName: 'Bộ phận kỹ thuật',
      ),
      AnnouncementModel(
        id: 'announcement-003',
        title: 'Thông báo thu phí dịch vụ tháng 10',
        content: 'Hóa đơn phí quản lý, gửi xe và dịch vụ tháng 10 đã được phát hành. Hạn thanh toán là ngày 25/10/2026.',
        category: AnnouncementCategory.billing,
        priority: AnnouncementPriority.important,
        audience: AnnouncementAudience.residents,
        publishedAt: ago(days: 2),
        expiresAt: now.add(const Duration(days: 10)),
        isPinned: false,
        isPublished: true,
        authorName: 'Bộ phận kế toán',
      ),
      AnnouncementModel(
        id: 'announcement-004',
        title: 'Ngày hội gia đình Homie 2026',
        content: 'Mời cư dân tham gia ngày hội gia đình tại sân trung tâm vào cuối tuần với các hoạt động cho trẻ em và gian hàng cộng đồng.',
        category: AnnouncementCategory.event,
        priority: AnnouncementPriority.normal,
        audience: AnnouncementAudience.all,
        publishedAt: ago(days: 3),
        expiresAt: now.add(const Duration(days: 14)),
        isPinned: false,
        isPublished: true,
        authorName: 'Ban quản lý Homie',
      ),
      AnnouncementModel(
        id: 'announcement-005',
        title: 'Cập nhật quy trình tiếp nhận phản ánh',
        content: 'Từ tháng này, mọi phản ánh của cư dân sẽ được cấp mã theo dõi và cập nhật tiến độ trực tiếp trên ứng dụng Homie.',
        category: AnnouncementCategory.general,
        priority: AnnouncementPriority.normal,
        audience: AnnouncementAudience.residents,
        publishedAt: ago(days: 7),
        isPinned: false,
        isPublished: true,
        authorName: 'Ban quản lý Homie',
      ),
      AnnouncementModel(
        id: 'announcement-006',
        title: 'Họp điều phối công việc tuần',
        content: 'Các bộ phận quản lý tập trung tại phòng họp tầng 2 lúc 09:00 thứ Hai để rà soát công nợ và yêu cầu đang xử lý.',
        category: AnnouncementCategory.general,
        priority: AnnouncementPriority.normal,
        audience: AnnouncementAudience.managers,
        publishedAt: ago(days: 1, hours: 3),
        isPinned: false,
        isPublished: true,
        authorName: 'Trưởng ban quản lý',
      ),
      AnnouncementModel(
        id: 'announcement-007',
        title: 'Bản nháp hướng dẫn đăng ký dịch vụ',
        content: 'Nội dung hướng dẫn đăng ký dịch vụ đang được hoàn thiện và sẽ phát hành tới cư dân sau khi được phê duyệt.',
        category: AnnouncementCategory.general,
        priority: AnnouncementPriority.normal,
        audience: AnnouncementAudience.residents,
        publishedAt: now.add(const Duration(days: 2)),
        isPinned: false,
        isPublished: false,
        authorName: 'Ban quản lý Homie',
      ),
    ];
  }
}
