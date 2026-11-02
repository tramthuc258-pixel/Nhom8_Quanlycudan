import 'package:flutter/material.dart';

import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/core/widgets/status_badge.dart';

/// Nhãn trạng thái căn hộ thống nhất giữa danh sách và trang chi tiết.
class ApartmentStatusBadge extends StatelessWidget {
  const ApartmentStatusBadge({
    required this.status,
    this.compact = true,
    super.key,
  });

  final ApartmentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      ApartmentStatus.occupied => (
        StatusBadgeTone.success,
        Icons.check_circle_outline_rounded,
      ),
      ApartmentStatus.vacant => (
        StatusBadgeTone.info,
        Icons.meeting_room_outlined,
      ),
      ApartmentStatus.underMaintenance => (
        StatusBadgeTone.warning,
        Icons.handyman_outlined,
      ),
    };

    return StatusBadge(
      label: status.displayName,
      tone: tone,
      icon: icon,
      compact: compact,
    );
  }
}
