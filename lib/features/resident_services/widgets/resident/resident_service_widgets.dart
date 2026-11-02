import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/core/widgets/status_badge.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';

String formatServiceMoney(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${rounded < 0 ? '-' : ''}${buffer.toString()} đ';
}

String formatServiceDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)} · '
      '${two(value.day)}/${two(value.month)}/${value.year}';
}

IconData serviceCategoryIcon(ServiceCategory category) => switch (category) {
  ServiceCategory.cleaning => Icons.cleaning_services_rounded,
  ServiceCategory.laundry => Icons.local_laundry_service_rounded,
  ServiceCategory.technical => Icons.handyman_rounded,
  ServiceCategory.transportation => Icons.local_shipping_outlined,
  ServiceCategory.convenience => Icons.room_service_rounded,
};

String? residentServiceImageAsset(ServiceCategory category) =>
    switch (category) {
      ServiceCategory.cleaning => 'assets/images/services/ve-sinh-can-ho.jpg',
      ServiceCategory.laundry => 'assets/images/services/giat-ui.jpg',
      ServiceCategory.technical => 'assets/images/services/ho-tro-ky-thuat.jpg',
      ServiceCategory.convenience =>
        'assets/images/services/giao-nuoc-uong.jpg',
      ServiceCategory.transportation => null,
    };

class ServiceBookingStatusBadge extends StatelessWidget {
  const ServiceBookingStatusBadge({required this.status, super.key});

  final ServiceBookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      ServiceBookingStatus.pending => (
        StatusBadgeTone.warning,
        Icons.schedule_rounded,
      ),
      ServiceBookingStatus.confirmed => (
        StatusBadgeTone.info,
        Icons.event_available_rounded,
      ),
      ServiceBookingStatus.inProgress => (
        StatusBadgeTone.info,
        Icons.miscellaneous_services_rounded,
      ),
      ServiceBookingStatus.waitingResident => (
        StatusBadgeTone.warning,
        Icons.fact_check_outlined,
      ),
      ServiceBookingStatus.completed => (
        StatusBadgeTone.success,
        Icons.task_alt_rounded,
      ),
      ServiceBookingStatus.cancelled => (
        StatusBadgeTone.neutral,
        Icons.block_rounded,
      ),
    };
    return StatusBadge(
      label: status.label,
      tone: tone,
      icon: icon,
      compact: true,
    );
  }
}

class ResidentServiceCard extends StatelessWidget {
  const ResidentServiceCard({
    required this.service,
    required this.onBook,
    this.compact = false,
    super.key,
  });

  final ResidentService service;
  final VoidCallback onBook;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = residentServiceImageAsset(service.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 122,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: AppColors.primaryLight,
                      child: Icon(
                        serviceCategoryIcon(service.category),
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    serviceCategoryIcon(service.category),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.category.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              service.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (compact) const SizedBox(height: 16) else const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Khoảng ${service.estimatedDurationMinutes} phút',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    service.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatServiceMoney(service.unitPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'mỗi ${service.unitLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.add_task_rounded, size: 19),
                  label: const Text('Đăng ký'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResidentServiceBookingCard extends StatelessWidget {
  const ResidentServiceBookingCard({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final ServiceBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.room_service_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.code,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          booking.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ServiceBookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 16),
              _BookingInfo(
                icon: Icons.event_outlined,
                text: formatServiceDateTime(booking.scheduledAt),
              ),
              const SizedBox(height: 8),
              _BookingInfo(
                icon: Icons.numbers_rounded,
                text: 'Số lượng: ${booking.quantity}',
              ),
              const Spacer(),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatServiceMoney(booking.totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'Xem chi tiết',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingInfo extends StatelessWidget {
  const _BookingInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
