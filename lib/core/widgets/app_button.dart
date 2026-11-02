import 'package:flutter/material.dart';

enum AppButtonVariant { filled, outlined, text, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final action = isLoading ? null : onPressed;
    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color:
                  variant == AppButtonVariant.filled ||
                      variant == AppButtonVariant.danger
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: action,
        child: content,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: action,
        child: content,
      ),
      AppButtonVariant.text => TextButton(onPressed: action, child: content),
      AppButtonVariant.danger => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: content,
      ),
    };

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      value: isLoading ? 'Đang xử lý' : null,
      child: SizedBox(width: expand ? double.infinity : null, child: button),
    );
  }
}
