import 'package:flutter/material.dart';

import 'package:homie/core/widgets/status_badge.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

String formatHousingMoney(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < rounded.length; index++) {
    if (index > 0 && (rounded.length - index) % 3 == 0) buffer.write('.');
    buffer.write(rounded[index]);
  }
  return '${buffer.toString()} đ';
}

String formatHousingDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year}';
}

String formatHousingDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)} · ${formatHousingDate(value)}';
}

class HousingTransactionBadge extends StatelessWidget {
  const HousingTransactionBadge({required this.type, super.key});

  final HousingTransactionType type;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: type.shortLabel,
      tone: type == HousingTransactionType.rent
          ? StatusBadgeTone.info
          : StatusBadgeTone.success,
      icon: type == HousingTransactionType.rent
          ? Icons.key_outlined
          : Icons.home_work_outlined,
      compact: true,
    );
  }
}

class HousingListingStatusBadge extends StatelessWidget {
  const HousingListingStatusBadge({required this.status, super.key});

  final HousingListingStatus status;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: status.label,
      tone: switch (status) {
        HousingListingStatus.pendingApproval => StatusBadgeTone.warning,
        HousingListingStatus.available => StatusBadgeTone.success,
        HousingListingStatus.rejected => StatusBadgeTone.danger,
        HousingListingStatus.closed => StatusBadgeTone.neutral,
      },
      icon: switch (status) {
        HousingListingStatus.pendingApproval => Icons.hourglass_top_rounded,
        HousingListingStatus.available => Icons.check_circle_outline_rounded,
        HousingListingStatus.rejected => Icons.cancel_outlined,
        HousingListingStatus.closed => Icons.lock_outline_rounded,
      },
      compact: true,
    );
  }
}

class HousingApplicationStatusBadge extends StatelessWidget {
  const HousingApplicationStatusBadge({required this.status, super.key});

  final HousingApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: status.label,
      tone: switch (status) {
        HousingApplicationStatus.pending => StatusBadgeTone.warning,
        HousingApplicationStatus.completed => StatusBadgeTone.success,
        HousingApplicationStatus.rejected => StatusBadgeTone.danger,
        HousingApplicationStatus.cancelled => StatusBadgeTone.neutral,
      },
      icon: switch (status) {
        HousingApplicationStatus.pending => Icons.hourglass_top_rounded,
        HousingApplicationStatus.completed => Icons.verified_outlined,
        HousingApplicationStatus.rejected => Icons.cancel_outlined,
        HousingApplicationStatus.cancelled => Icons.block_outlined,
      },
      compact: true,
    );
  }
}
