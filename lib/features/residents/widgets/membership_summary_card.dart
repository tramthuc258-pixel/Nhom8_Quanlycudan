import 'package:flutter/material.dart';

import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/core/widgets/status_badge.dart';

class MembershipSummaryCard extends StatelessWidget {
  const MembershipSummaryCard({
    required this.membership,
    required this.resident,
    this.onEnd,
    this.showContact = true,
    super.key,
  });

  final ApartmentMembership membership;
  final Resident resident;
  final VoidCallback? onEnd;
  final bool showContact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final roleColor = _roleColor(membership.type, colors);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: roleColor.withValues(alpha: 0.12),
              foregroundColor: roleColor,
              child: Text(
                _initials(resident.fullName),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          resident.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: membership.type.displayName,
                        tone: _roleTone(membership.type),
                        compact: true,
                      ),
                    ],
                  ),
                  if (showContact) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 5,
                      children: [
                        _InlineInfo(
                          icon: Icons.phone_outlined,
                          label: resident.phone,
                        ),
                        _InlineInfo(
                          icon: Icons.mail_outline_rounded,
                          label: resident.email,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(
                        label: membership.isActive
                            ? 'Đang hiệu lực'
                            : 'Đã kết thúc',
                        tone: membership.isActive
                            ? StatusBadgeTone.success
                            : StatusBadgeTone.neutral,
                        compact: true,
                      ),
                      Text(
                        _periodLabel(membership),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      if (membership.isPrimary)
                        const StatusBadge(
                          label: 'Liên hệ chính',
                          tone: StatusBadgeTone.info,
                          compact: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (membership.isActive && onEnd != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn quan hệ cư trú',
                onSelected: (_) => onEnd?.call(),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'end',
                    child: Row(
                      children: [
                        Icon(Icons.link_off_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Kết thúc quan hệ'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

StatusBadgeTone _roleTone(MembershipType type) => switch (type) {
  MembershipType.owner => StatusBadgeTone.info,
  MembershipType.tenant => StatusBadgeTone.warning,
};

Color _roleColor(MembershipType type, ColorScheme colors) => switch (type) {
  MembershipType.owner => colors.primary,
  MembershipType.tenant => const Color(0xFFB45309),
};

String _periodLabel(ApartmentMembership membership) {
  final start = _formatDate(membership.startDate);
  final end = membership.endDate == null
      ? 'nay'
      : _formatDate(membership.endDate!);
  return '$start – $end';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return 'CD';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
