import 'package:flutter/material.dart';

import '../widgets/app_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Hủy',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
        color: isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          variant: isDestructive
              ? AppButtonVariant.danger
              : AppButtonVariant.filled,
        ),
      ],
    ),
  );

  return result ?? false;
}
