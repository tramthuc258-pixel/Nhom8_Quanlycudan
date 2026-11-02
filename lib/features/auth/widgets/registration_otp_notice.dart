import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';

class RegistrationOtpNotice extends StatelessWidget {
  const RegistrationOtpNotice({
    required this.email,
    required this.developmentCode,
    super.key,
  });

  final String email;
  final String? developmentCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC9DAFA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.outgoing_mail, color: AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Kiểm tra email $email',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhập mã gồm 6 chữ số. Mã có hiệu lực trong 15 phút.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (developmentCode case final code?) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Mã phát triển khi chưa cấu hình SMTP: $code',
                    key: const ValueKey<String>(
                      'registration-development-code',
                    ),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
