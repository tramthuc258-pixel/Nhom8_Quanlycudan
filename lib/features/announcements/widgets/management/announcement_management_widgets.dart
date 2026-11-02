import 'package:flutter/material.dart';

import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/core/widgets/status_badge.dart';

class AnnouncementManagementOverview extends StatelessWidget {
  const AnnouncementManagementOverview({
    required this.announcements,
    super.key,
  });

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = announcements.where((item) => _isActive(item, now)).length;
    final drafts = announcements.where((item) => !item.isPublished).length;
    final scheduled = announcements
        .where((item) => item.isPublished && item.publishedAt.isAfter(now))
        .length;

    final items = [
      _OverviewItem(
        label: 'Tổng thông báo',
        value: announcements.length,
        icon: Icons.campaign_rounded,
        tone: _OverviewTone.primary,
      ),
      _OverviewItem(
        label: 'Đang hiển thị',
        value: active,
        icon: Icons.visibility_rounded,
        tone: _OverviewTone.success,
      ),
      _OverviewItem(
        label: 'Bản nháp',
        value: drafts,
        icon: Icons.drafts_outlined,
        tone: _OverviewTone.neutral,
      ),
      _OverviewItem(
        label: 'Đã lên lịch',
        value: scheduled,
        icon: Icons.schedule_rounded,
        tone: _OverviewTone.warning,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 520
              ? 2
              : 2;
          final ratio = constraints.maxWidth < 360 ? 1.25 : 1.65;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: ratio,
            ),
            itemBuilder: (context, index) => _OverviewCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class AnnouncementManagementCard extends StatelessWidget {
  const AnnouncementManagementCard({
    required this.announcement,
    required this.onPreview,
    required this.onTogglePublished,
    required this.onDelete,
    this.busy = false,
    super.key,
  });

  final Announcement announcement;
  final VoidCallback onPreview;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final state = _stateFor(announcement, now);

    return Card(
      child: InkWell(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _CategoryIcon(category: announcement.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.category.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(announcement.publishedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (announcement.isPinned)
                    Tooltip(
                      message: 'Đang ghim',
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.push_pin_rounded,
                          color: colors.onTertiaryContainer,
                          size: 18,
                        ),
                      ),
                    ),
                  PopupMenuButton<_AnnouncementAction>(
                    tooltip: 'Thao tác',
                    enabled: !busy,
                    onSelected: (action) {
                      switch (action) {
                        case _AnnouncementAction.preview:
                          onPreview();
                        case _AnnouncementAction.togglePublished:
                          onTogglePublished();
                        case _AnnouncementAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _AnnouncementAction.preview,
                        child: _MenuLabel(
                          icon: Icons.visibility_outlined,
                          label: 'Xem trước',
                        ),
                      ),
                      PopupMenuItem(
                        value: _AnnouncementAction.togglePublished,
                        child: _MenuLabel(
                          icon: announcement.isPublished
                              ? Icons.visibility_off_outlined
                              : Icons.campaign_outlined,
                          label: announcement.isPublished
                              ? 'Chuyển về bản nháp'
                              : 'Phát hành',
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: _AnnouncementAction.delete,
                        child: _MenuLabel(
                          icon: Icons.delete_outline_rounded,
                          label: 'Xóa thông báo',
                          destructive: true,
                        ),
                      ),
                    ],
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(label: state.label, tone: state.tone),
                  StatusBadge(
                    label: announcement.priority.displayName,
                    tone: _priorityTone(announcement.priority),
                  ),
                  StatusBadge(
                    label: announcement.audience.displayName,
                    tone: StatusBadgeTone.info,
                  ),
                  StatusBadge(
                    label: announcement.buildingName ?? 'Toàn hệ thống',
                    tone: StatusBadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                announcement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  announcement.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 17,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      announcement.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('Chi tiết'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAnnouncementPreviewDialog(
  BuildContext context,
  Announcement announcement,
) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _AnnouncementPreviewDialog(announcement: announcement),
  );
}

class _AnnouncementPreviewDialog extends StatelessWidget {
  const _AnnouncementPreviewDialog({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = Theme.of(context).colorScheme;
    final state = _stateFor(announcement, DateTime.now());

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 18),
              color: colors.primaryContainer.withValues(alpha: 0.5),
              child: Row(
                children: [
                  _CategoryIcon(category: announcement.category, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xem trước thông báo',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          announcement.category.displayName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(label: state.label, tone: state.tone),
                        StatusBadge(
                          label: announcement.priority.displayName,
                          tone: _priorityTone(announcement.priority),
                        ),
                        StatusBadge(
                          label: announcement.audience.displayName,
                          tone: StatusBadgeTone.info,
                        ),
                        if (announcement.isPinned)
                          const StatusBadge(
                            label: 'Đã ghim',
                            tone: StatusBadgeTone.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      announcement.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      announcement.content,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.65),
                    ),
                    const SizedBox(height: 24),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _PreviewInfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Người đăng',
                              value: announcement.authorName,
                            ),
                            const SizedBox(height: 12),
                            _PreviewInfoRow(
                              icon: Icons.schedule_rounded,
                              label: 'Phát hành',
                              value: _formatDateTime(announcement.publishedAt),
                            ),
                            if (announcement.expiresAt != null) ...[
                              const SizedBox(height: 12),
                              _PreviewInfoRow(
                                icon: Icons.event_busy_outlined,
                                label: 'Hết hạn',
                                value: _formatDateTime(announcement.expiresAt!),
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
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewInfoRow extends StatelessWidget {
  const _PreviewInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: colors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category, this.size = 44});

  final AnnouncementCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, foreground, background) = switch (category) {
      AnnouncementCategory.general => (
        Icons.campaign_outlined,
        colors.primary,
        colors.primaryContainer,
      ),
      AnnouncementCategory.maintenance => (
        Icons.build_outlined,
        colors.tertiary,
        colors.tertiaryContainer,
      ),
      AnnouncementCategory.billing => (
        Icons.receipt_long_outlined,
        colors.secondary,
        colors.secondaryContainer,
      ),
      AnnouncementCategory.event => (
        Icons.celebration_outlined,
        const Color(0xFF7C3AED),
        const Color(0xFFEDE9FE),
      ),
      AnnouncementCategory.emergency => (
        Icons.warning_amber_rounded,
        colors.error,
        colors.errorContainer,
      ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});

  final _OverviewItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (foreground, background) = switch (item.tone) {
      _OverviewTone.primary => (colors.primary, colors.primaryContainer),
      _OverviewTone.success => (
        const Color(0xFF15803D),
        const Color(0xFFDCFCE7),
      ),
      _OverviewTone.neutral => (
        colors.onSurfaceVariant,
        colors.surfaceContainerHighest,
      ),
      _OverviewTone.warning => (
        const Color(0xFFB45309),
        const Color(0xFFFEF3C7),
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.value}',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int value;
  final IconData icon;
  final _OverviewTone tone;
}

enum _AnnouncementAction { preview, togglePublished, delete }

enum _OverviewTone { primary, success, neutral, warning }

class _AnnouncementState {
  const _AnnouncementState(this.label, this.tone);

  final String label;
  final StatusBadgeTone tone;
}

_AnnouncementState _stateFor(Announcement item, DateTime now) {
  if (!item.isPublished) {
    return const _AnnouncementState('Bản nháp', StatusBadgeTone.neutral);
  }
  if (item.expiresAt != null && !item.expiresAt!.isAfter(now)) {
    return const _AnnouncementState('Đã hết hạn', StatusBadgeTone.danger);
  }
  if (item.publishedAt.isAfter(now)) {
    return const _AnnouncementState('Đã lên lịch', StatusBadgeTone.warning);
  }
  return const _AnnouncementState('Đang hiển thị', StatusBadgeTone.success);
}

StatusBadgeTone _priorityTone(AnnouncementPriority priority) =>
    switch (priority) {
      AnnouncementPriority.normal => StatusBadgeTone.neutral,
      AnnouncementPriority.important => StatusBadgeTone.warning,
      AnnouncementPriority.urgent => StatusBadgeTone.danger,
    };

bool _isActive(Announcement item, DateTime now) {
  if (!item.isPublished || item.publishedAt.isAfter(now)) return false;
  return item.expiresAt == null || item.expiresAt!.isAfter(now);
}

String _formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)} · '
      '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}
