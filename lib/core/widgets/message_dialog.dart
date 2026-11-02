import 'package:flutter/material.dart';

import '../widgets/app_button.dart';

Future<void> showMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  String closeLabel = 'Đóng',
  IconData icon = Icons.info_outline_rounded,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label: closeLabel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
