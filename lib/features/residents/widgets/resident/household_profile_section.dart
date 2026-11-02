import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/residents/models/household_member.dart';

class HouseholdProfileSection extends StatelessWidget {
  const HouseholdProfileSection({
    required this.members,
    this.onAdd,
    this.onEnd,
    this.title = 'Thành viên trong hộ',
    this.subtitle =
        'Người sinh sống lâu dài, không có tài khoản đăng nhập riêng',
    this.emptyMessage = 'Chưa có thành viên nào được ghi nhận trong hộ.',
    super.key,
  });

  final List<HouseholdMember> members;
  final VoidCallback? onAdd;
  final ValueChanged<HouseholdMember>? onEnd;
  final String title;
  final String subtitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final active = members.where((member) => member.isActive).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (onAdd != null)
                  FilledButton.tonalIcon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Thêm'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      emptyMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: active.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final member = active[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.successContainer,
                    foregroundColor: AppColors.success,
                    child: Text(
                      _initials(member.fullName),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(
                    member.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Info(
                          icon: Icons.people_outline,
                          text: member.relationship,
                        ),
                        if (member.dateOfBirth != null)
                          _Info(
                            icon: Icons.cake_outlined,
                            text: _formatDate(member.dateOfBirth!),
                          ),
                        if (member.phone.isNotEmpty)
                          _Info(icon: Icons.phone_outlined, text: member.phone),
                      ],
                    ),
                  ),
                  trailing: onEnd == null
                      ? null
                      : IconButton(
                          tooltip: 'Kết thúc cư trú',
                          onPressed: () => onEnd!(member),
                          icon: const Icon(Icons.person_remove_outlined),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textDisabled),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return 'TV';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
