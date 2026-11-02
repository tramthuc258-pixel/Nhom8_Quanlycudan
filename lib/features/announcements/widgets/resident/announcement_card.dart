import 'package:flutter/material.dart';

import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/widgets/resident/announcement_badges.dart';

class ResidentAnnouncementCard extends StatelessWidget {
  const ResidentAnnouncementCard({
    required this.announcement,
    required this.isRead,
    required this.onTap,
    super.key,
  });

  final Announcement announcement;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${announcement.title}, ${isRead ? 'đã đọc' : 'chưa đọc'}',
      child: Card(
        color: isRead
            ? scheme.surface
            : scheme.primaryContainer.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  color: isRead ? Colors.transparent : scheme.primary,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: isRead
                                          ? FontWeight.w700
                                          : FontWeight.w800,
                                      height: 1.3,
                                    ),
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 9,
                                height: 9,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _preview(announcement.content),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 13),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            AnnouncementCategoryBadge(
                              category: announcement.category,
                            ),
                            AnnouncementPriorityBadge(
                              priority: announcement.priority,
                            ),
                            if (announcement.isPinned)
                              const AnnouncementPinnedBadge(),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formatAnnouncementDate(
                                  announcement.publishedAt,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
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
  }

  String _preview(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
