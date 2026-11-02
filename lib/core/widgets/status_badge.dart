import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusBadgeTone { neutral, info, success, warning, danger }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.tone = StatusBadgeTone.neutral,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final StatusBadgeTone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (foreground, background) = _colorsFor(tone, isDark);

    return Semantics(
      label: 'Trạng thái: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: compact ? 13 : 15),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(StatusBadgeTone tone, bool isDark) {
    return switch (tone) {
      StatusBadgeTone.neutral => (
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
      ),
      StatusBadgeTone.info => (
        isDark ? const Color(0xFF93C5FD) : AppColors.info,
        isDark ? const Color(0xFF1E3A8A) : AppColors.infoContainer,
      ),
      StatusBadgeTone.success => (
        isDark ? const Color(0xFF86EFAC) : AppColors.success,
        isDark ? const Color(0xFF14532D) : AppColors.successContainer,
      ),
      StatusBadgeTone.warning => (
        isDark ? const Color(0xFFFCD34D) : AppColors.warning,
        isDark ? const Color(0xFF713F12) : AppColors.warningContainer,
      ),
      StatusBadgeTone.danger => (
        isDark ? const Color(0xFFFCA5A5) : AppColors.error,
        isDark ? const Color(0xFF7F1D1D) : AppColors.errorContainer,
      ),
    };
  }
}
