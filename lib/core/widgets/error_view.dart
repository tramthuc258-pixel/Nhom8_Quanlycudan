import 'package:flutter/material.dart';

import 'app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    this.title = 'Không thể tải dữ liệu',
    this.message = 'Đã có lỗi xảy ra. Vui lòng thử lại.',
    this.retryLabel = 'Thử lại',
    this.onRetry,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });

  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.error.withValues(alpha: .16)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0C173B76),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 36,
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  AppButton(
                    label: retryLabel,
                    onPressed: onRetry,
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.outlined,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
