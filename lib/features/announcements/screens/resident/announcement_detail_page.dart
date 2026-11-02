import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/controllers/announcement_controller.dart';
import 'package:homie/features/announcements/widgets/resident/announcement_badges.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

class AnnouncementDetailPage extends StatefulWidget {
  const AnnouncementDetailPage({
    required this.announcement,
    required this.controller,
    required this.user,
    super.key,
  });

  final Announcement announcement;
  final AnnouncementController controller;
  final User user;

  @override
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  bool _markingAsRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  @override
  void didUpdateWidget(covariant AnnouncementDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.announcement.id != widget.announcement.id ||
        oldWidget.user.id != widget.user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
    }
  }

  Future<void> _markAsRead() async {
    if (_markingAsRead ||
        widget.controller.isRead(widget.announcement.id, widget.user.id)) {
      return;
    }

    setState(() => _markingAsRead = true);
    final success = await widget.controller.markAsRead(
      widget.announcement.id,
      widget.user.id,
    );
    if (!mounted) return;
    setState(() => _markingAsRead = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa thể cập nhật trạng thái đã đọc.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;
    return ResidentPageScaffold(
      title: 'Chi tiết thông báo',
      subtitle: 'Nội dung chính thức từ ban quản lý',
      icon: Icons.article_outlined,
      accentColor: AppColors.community,
      accentSoftColor: AppColors.communitySoft,
      actions: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final isRead = widget.controller.isRead(
              announcement.id,
              widget.user.id,
            );
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: isRead ? 'Đã đọc' : 'Đang cập nhật',
                child: Icon(
                  isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  color: isRead
                      ? AppColors.success
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ],
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: widget.controller.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (announcement.priority ==
                          AnnouncementPriority.urgent) ...[
                        const _UrgentNotice(),
                        const SizedBox(height: 14),
                      ],
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                            MediaQuery.sizeOf(context).width < 600 ? 20 : 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  AnnouncementCategoryBadge(
                                    category: announcement.category,
                                  ),
                                  AnnouncementPriorityBadge(
                                    priority: announcement.priority,
                                  ),
                                  if (announcement.isPinned)
                                    const AnnouncementPinnedBadge(),
                                  AnnouncementReadBadge(
                                    isRead: widget.controller.isRead(
                                      announcement.id,
                                      widget.user.id,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                announcement.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              _PublicationInfo(announcement: announcement),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Divider(),
                              ),
                              SelectableText(
                                announcement.content,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(height: 1.75),
                              ),
                              if (announcement.expiresAt != null) ...[
                                const SizedBox(height: 28),
                                _ExpiryNotice(
                                  expiresAt: announcement.expiresAt!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PublicationInfo extends StatelessWidget {
  const _PublicationInfo({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _InfoItem(
          icon: Icons.schedule_rounded,
          label: formatAnnouncementDate(announcement.publishedAt),
        ),
        _InfoItem(
          icon: Icons.account_circle_outlined,
          label: announcement.authorName,
        ),
        if (announcement.isPinned)
          _InfoItem(icon: Icons.push_pin_outlined, label: 'Ưu tiên hiển thị'),
        if (announcement.isExpired)
          Text(
            'Đã hết hiệu lực',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _UrgentNotice extends StatelessWidget {
  const _UrgentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.crisis_alert_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông báo khẩn — vui lòng đọc kỹ và thực hiện theo hướng dẫn.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryNotice extends StatelessWidget {
  const _ExpiryNotice({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông báo có hiệu lực đến ${formatAnnouncementDate(expiresAt)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
