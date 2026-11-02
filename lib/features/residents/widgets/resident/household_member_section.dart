import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/resident.dart';

class HouseholdMemberEntry {
  const HouseholdMemberEntry({
    required this.resident,
    required this.membership,
    this.isCurrentUser = false,
  });

  final Resident resident;
  final ApartmentMembership membership;
  final bool isCurrentUser;
}

/// Danh sách một nhóm người có quan hệ với căn hộ.
class HouseholdMemberSection extends StatelessWidget {
  const HouseholdMemberSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.entries,
    this.emptyMessage = 'Chưa có thông tin',
    this.showPeriod = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<HouseholdMemberEntry> entries;
  final String emptyMessage;
  final bool showPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entries.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 19,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      emptyMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72, endIndent: 18),
              itemBuilder: (context, index) {
                return _HouseholdMemberTile(
                  entry: entries[index],
                  showPeriod: showPeriod,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HouseholdMemberTile extends StatelessWidget {
  const _HouseholdMemberTile({required this.entry, required this.showPeriod});

  final HouseholdMemberEntry entry;
  final bool showPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membership = entry.membership;
    final resident = entry.resident;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: _avatarBackground(membership.type),
            foregroundColor: _avatarForeground(membership.type),
            child: Text(
              _initials(resident.fullName),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      resident.fullName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.isCurrentUser)
                      const _SmallBadge(
                        label: 'Bạn',
                        foreground: AppColors.primary,
                        background: AppColors.primaryLight,
                      ),
                    if (membership.isPrimary)
                      _SmallBadge(
                        label: membership.type == MembershipType.owner
                            ? 'Chủ sở hữu đại diện'
                            : 'Người thuê đại diện',
                        foreground: AppColors.info,
                        background: AppColors.infoContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _ContactLabel(
                      icon: Icons.phone_outlined,
                      value: resident.phone,
                    ),
                    _ContactLabel(
                      icon: Icons.mail_outline_rounded,
                      value: resident.email,
                    ),
                  ],
                ),
                if (showPeriod) ...[
                  const SizedBox(height: 9),
                  Text(
                    _periodLabel(membership),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: membership.type.displayName,
            child: Icon(
              _roleIcon(membership.type),
              color: _avatarForeground(membership.type),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLabel extends StatelessWidget {
  const _ContactLabel({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 1),
        Icon(icon, size: 14, color: AppColors.textDisabled),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _avatarBackground(MembershipType type) {
  return switch (type) {
    MembershipType.owner => AppColors.warningContainer,
    MembershipType.tenant => AppColors.infoContainer,
  };
}

Color _avatarForeground(MembershipType type) {
  return switch (type) {
    MembershipType.owner => AppColors.warning,
    MembershipType.tenant => AppColors.info,
  };
}

IconData _roleIcon(MembershipType type) {
  return switch (type) {
    MembershipType.owner => Icons.key_rounded,
    MembershipType.tenant => Icons.home_work_outlined,
  };
}

String _periodLabel(ApartmentMembership membership) {
  final endDate = membership.endDate;
  final endText = endDate == null ? 'nay' : _formatDate(endDate);
  return '${membership.type.displayName} · ${_formatDate(membership.startDate)} – $endText';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return 'H';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
