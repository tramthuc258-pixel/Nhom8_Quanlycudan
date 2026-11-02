import 'package:flutter/material.dart';

import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';

/// Nhãn danh mục dùng trong danh sách và trang chi tiết thông báo cư dân.
class AnnouncementCategoryBadge extends StatelessWidget {
  const AnnouncementCategoryBadge({required this.category, super.key});

  final AnnouncementCategory category;

  @override
  Widget build(BuildContext context) {
    final visual = _categoryVisual(category);
    return _AnnouncementBadge(
      icon: visual.icon,
      label: category.displayName,
      foreground: visual.foreground,
      background: visual.background,
    );
  }
}

/// Nhãn mức độ ưu tiên. Mức bình thường vẫn được hiển thị để trạng thái rõ ràng.
class AnnouncementPriorityBadge extends StatelessWidget {
  const AnnouncementPriorityBadge({required this.priority, super.key});

  final AnnouncementPriority priority;

  @override
  Widget build(BuildContext context) {
    final visual = _priorityVisual(priority);
    return _AnnouncementBadge(
      icon: visual.icon,
      label: priority.displayName,
      foreground: visual.foreground,
      background: visual.background,
    );
  }
}

class AnnouncementReadBadge extends StatelessWidget {
  const AnnouncementReadBadge({required this.isRead, super.key});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _AnnouncementBadge(
      icon: isRead ? Icons.drafts_outlined : Icons.mark_email_unread_outlined,
      label: isRead ? 'Đã đọc' : 'Chưa đọc',
      foreground: isRead ? scheme.onSurfaceVariant : scheme.primary,
      background: isRead
          ? scheme.surfaceContainerHighest
          : scheme.primaryContainer,
    );
  }
}

class AnnouncementPinnedBadge extends StatelessWidget {
  const AnnouncementPinnedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return _AnnouncementBadge(
      icon: Icons.push_pin_rounded,
      label: 'Đã ghim',
      foreground: const Color(0xFF9A3412),
      background: const Color(0xFFFFEDD5),
    );
  }
}

class _AnnouncementBadge extends StatelessWidget {
  const _AnnouncementBadge({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

({Color foreground, Color background, IconData icon}) _categoryVisual(
  AnnouncementCategory category,
) {
  return switch (category) {
    AnnouncementCategory.general => (
      foreground: const Color(0xFF1D4ED8),
      background: const Color(0xFFDBEAFE),
      icon: Icons.campaign_outlined,
    ),
    AnnouncementCategory.maintenance => (
      foreground: const Color(0xFF7C3AED),
      background: const Color(0xFFEDE9FE),
      icon: Icons.handyman_outlined,
    ),
    AnnouncementCategory.billing => (
      foreground: const Color(0xFF047857),
      background: const Color(0xFFD1FAE5),
      icon: Icons.receipt_long_outlined,
    ),
    AnnouncementCategory.event => (
      foreground: const Color(0xFFB45309),
      background: const Color(0xFFFEF3C7),
      icon: Icons.event_outlined,
    ),
    AnnouncementCategory.emergency => (
      foreground: const Color(0xFFB91C1C),
      background: const Color(0xFFFEE2E2),
      icon: Icons.warning_amber_rounded,
    ),
  };
}

({Color foreground, Color background, IconData icon}) _priorityVisual(
  AnnouncementPriority priority,
) {
  return switch (priority) {
    AnnouncementPriority.normal => (
      foreground: const Color(0xFF64748B),
      background: const Color(0xFFF1F5F9),
      icon: Icons.low_priority_rounded,
    ),
    AnnouncementPriority.important => (
      foreground: const Color(0xFFB45309),
      background: const Color(0xFFFEF3C7),
      icon: Icons.priority_high_rounded,
    ),
    AnnouncementPriority.urgent => (
      foreground: const Color(0xFFB91C1C),
      background: const Color(0xFFFEE2E2),
      icon: Icons.crisis_alert_rounded,
    ),
  };
}

String formatAnnouncementDate(DateTime value, {bool includeTime = true}) {
  final date = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = today.difference(target).inDays;
  final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

  if (difference == 0) return includeTime ? 'Hôm nay, $time' : 'Hôm nay';
  if (difference == 1) return includeTime ? 'Hôm qua, $time' : 'Hôm qua';

  final formatted =
      '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  return includeTime ? '$formatted, $time' : formatted;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
