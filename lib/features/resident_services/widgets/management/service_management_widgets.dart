import 'package:flutter/material.dart';

import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/core/widgets/status_badge.dart';

class ServiceManagementOverview extends StatelessWidget {
  const ServiceManagementOverview({
    required this.bookings,
    required this.services,
    super.key,
  });

  final List<ServiceBooking> bookings;
  final List<ResidentService> services;

  @override
  Widget build(BuildContext context) {
    final waiting = bookings
        .where((item) => item.status == ServiceBookingStatus.pending)
        .length;
    final processing = bookings
        .where(
          (item) =>
              item.status == ServiceBookingStatus.confirmed ||
              item.status == ServiceBookingStatus.inProgress,
        )
        .length;
    final completed = bookings
        .where((item) => item.status == ServiceBookingStatus.completed)
        .toList(growable: false);
    final revenue = completed.fold<double>(
      0,
      (total, item) => total + item.totalAmount,
    );

    final items = <_OverviewItem>[
      _OverviewItem(
        label: 'Chờ tiếp nhận',
        value: '$waiting đơn',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFB45309),
      ),
      _OverviewItem(
        label: 'Đang thực hiện',
        value: '$processing đơn',
        icon: Icons.engineering_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      _OverviewItem(
        label: 'Đã hoàn thành',
        value: '${completed.length} đơn',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF15803D),
      ),
      _OverviewItem(
        label: 'Giá trị dịch vụ hoàn thành',
        value: formatServicePrice(revenue),
        icon: Icons.payments_outlined,
        color: const Color(0xFF2563EB),
      ),
      _OverviewItem(
        label: 'Dịch vụ đang mở',
        value: '${services.where((item) => item.isActive).length} dịch vụ',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width < 760) {
            final halfWidth = (width - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < items.length; index++)
                  SizedBox(
                    width: index == items.length - 1 ? width : halfWidth,
                    height: index == items.length - 1 ? 72 : 96,
                    child: _OverviewCard(item: items[index], compact: true),
                  ),
              ],
            );
          }
          final columns = width >= 1140
              ? 5
              : width >= 760
              ? 3
              : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) => _OverviewCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class ServiceBookingCard extends StatelessWidget {
  const ServiceBookingCard({
    required this.booking,
    required this.apartment,
    required this.onView,
    this.busy = false,
    this.compact = false,
    super.key,
  });

  final ServiceBooking booking;
  final Apartment? apartment;
  final VoidCallback onView;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onView,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.room_service_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          apartment == null
                              ? 'Căn hộ không xác định'
                              : '${apartment!.code} · ${apartment!.buildingName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 15),
              ServiceBookingStatusBadge(status: booking.status),
              const SizedBox(height: 15),
              Text(
                booking.serviceName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                '${formatServiceQuantity(booking.quantity)} × '
                '${formatServicePrice(booking.unitPrice)}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 5),
              Text(
                formatServicePrice(booking.totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (compact) const SizedBox(height: 12) else const Spacer(),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.person_outline_rounded,
                text: booking.residentName,
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.event_available_outlined,
                text: formatServiceDateTime(booking.scheduledAt),
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: booking.assignedTo == null
                    ? Icons.person_search_rounded
                    : Icons.engineering_outlined,
                text: booking.assignedTo ?? 'Chưa phân công',
                color: booking.assignedTo == null
                    ? const Color(0xFFB45309)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCatalogCard extends StatelessWidget {
  const ServiceCatalogCard({
    required this.service,
    required this.onToggle,
    this.busy = false,
    this.compact = false,
    super.key,
  });

  final ResidentService service;
  final ValueChanged<bool>? onToggle;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = serviceCategoryIcon(service.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: service.isActive
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: service.isActive
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (busy)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (onToggle != null)
                  Semantics(
                    label: service.isActive
                        ? 'Tắt ${service.name}'
                        : 'Bật ${service.name}',
                    child: Switch.adaptive(
                      value: service.isActive,
                      onChanged: onToggle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(
                  label: serviceCategoryLabel(service.category),
                  tone: StatusBadgeTone.info,
                  compact: true,
                ),
                StatusBadge(
                  label: service.isActive ? 'Đang cung cấp' : 'Đang tạm ẩn',
                  tone: service.isActive
                      ? StatusBadgeTone.success
                      : StatusBadgeTone.neutral,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              service.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.35),
            ),
            if (compact) const SizedBox(height: 12) else const Spacer(),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatServicePrice(service.unitPrice),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        service.unitLabel,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.schedule_rounded, size: 18, color: colors.outline),
                const SizedBox(width: 5),
                Text('${service.estimatedDurationMinutes} phút'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceBookingStatusBadge extends StatelessWidget {
  const ServiceBookingStatusBadge({required this.status, super.key});

  final ServiceBookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusBadge(
        label: serviceBookingStatusLabel(status),
        tone: switch (status) {
          ServiceBookingStatus.pending => StatusBadgeTone.warning,
          ServiceBookingStatus.confirmed => StatusBadgeTone.info,
          ServiceBookingStatus.inProgress => StatusBadgeTone.info,
          ServiceBookingStatus.waitingResident => StatusBadgeTone.warning,
          ServiceBookingStatus.completed => StatusBadgeTone.success,
          ServiceBookingStatus.cancelled => StatusBadgeTone.neutral,
        },
      ),
    );
  }
}

Future<void> showServiceBookingDetailDialog(
  BuildContext context, {
  required ServiceBooking booking,
  required Apartment? apartment,
  required VoidCallback? onAssign,
  required VoidCallback? onUpdateStatus,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ServiceBookingDetailDialog(
      booking: booking,
      apartment: apartment,
      onAssign: onAssign,
      onUpdateStatus: onUpdateStatus,
    ),
  );
}

class _ServiceBookingDetailDialog extends StatelessWidget {
  const _ServiceBookingDetailDialog({
    required this.booking,
    required this.apartment,
    required this.onAssign,
    required this.onUpdateStatus,
  });

  final ServiceBooking booking;
  final Apartment? apartment;
  final VoidCallback? onAssign;
  final VoidCallback? onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final terminal =
        booking.status == ServiceBookingStatus.completed ||
        booking.status == ServiceBookingStatus.cancelled;
    final summary = <({IconData icon, String label, String value})>[
      (
        icon: Icons.apartment_rounded,
        label: 'Căn hộ',
        value: apartment == null
            ? 'Không xác định'
            : '${apartment!.code} · ${apartment!.buildingName}',
      ),
      (
        icon: Icons.person_outline_rounded,
        label: 'Cư dân',
        value: booking.residentName,
      ),
      (
        icon: Icons.event_available_outlined,
        label: 'Lịch thực hiện',
        value: formatServiceDateTime(booking.scheduledAt),
      ),
      (
        icon: Icons.engineering_outlined,
        label: 'Phụ trách',
        value: booking.assignedTo ?? 'Chưa phân công',
      ),
      (
        icon: Icons.history_rounded,
        label: 'Ngày tạo',
        value: formatServiceDateTime(booking.createdAt),
      ),
      (
        icon: Icons.update_rounded,
        label: 'Cập nhật gần nhất',
        value: formatServiceDateTime(booking.updatedAt),
      ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 18),
              color: colors.primaryContainer.withValues(alpha: 0.48),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.room_service_rounded,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.code,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          booking.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ServiceBookingStatusBadge(status: booking.status),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = constraints.maxWidth >= 590
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final item in summary)
                              SizedBox(
                                width: tileWidth,
                                child: _DetailTile(
                                  icon: item.icon,
                                  label: item.label,
                                  value: item.value,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _PriceSummary(booking: booking),
                    if (booking.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _NoteBlock(
                        title: 'Ghi chú của cư dân',
                        note: booking.note,
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ],
                    if ((booking.managementNote ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NoteBlock(
                        title: 'Ghi chú xử lý',
                        note: booking.managementNote!,
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                  if (!terminal && onAssign != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onAssign!();
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        booking.assignedTo == null
                            ? 'Phân công'
                            : 'Đổi phân công',
                      ),
                    ),
                  if (!terminal && onUpdateStatus != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateStatus!();
                      },
                      icon: const Icon(Icons.update_rounded),
                      label: const Text('Cập nhật trạng thái'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item, this.compact = false});

  final _OverviewItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 11 : 15),
        child: Row(
          children: [
            Container(
              width: compact ? 34 : 42,
              height: compact ? 34 : 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: compact ? 20 : 24,
              ),
            ),
            SizedBox(width: compact ? 8 : 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 17, color: effective),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: effective),
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.booking});

  final ServiceBooking booking;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chi phí dịch vụ'),
                  const SizedBox(height: 4),
                  Text(
                    '${formatServiceQuantity(booking.quantity)} × '
                    '${formatServicePrice(booking.unitPrice)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              formatServicePrice(booking.totalAmount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({
    required this.title,
    required this.note,
    required this.icon,
  });

  final String title;
  final String note;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(note, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String serviceBookingStatusLabel(ServiceBookingStatus status) =>
    switch (status) {
      ServiceBookingStatus.pending => 'Chờ xác nhận',
      ServiceBookingStatus.confirmed => 'Đã xác nhận',
      ServiceBookingStatus.inProgress => 'Đang thực hiện',
      ServiceBookingStatus.waitingResident => 'Chờ cư dân xác nhận',
      ServiceBookingStatus.completed => 'Hoàn thành',
      ServiceBookingStatus.cancelled => 'Đã hủy',
    };

String serviceCategoryLabel(ServiceCategory category) => switch (category) {
  ServiceCategory.cleaning => 'Vệ sinh',
  ServiceCategory.laundry => 'Giặt ủi',
  ServiceCategory.technical => 'Kỹ thuật',
  ServiceCategory.transportation => 'Di chuyển',
  ServiceCategory.convenience => 'Tiện ích',
};

IconData serviceCategoryIcon(ServiceCategory category) => switch (category) {
  ServiceCategory.cleaning => Icons.cleaning_services_rounded,
  ServiceCategory.laundry => Icons.local_laundry_service_rounded,
  ServiceCategory.technical => Icons.home_repair_service_rounded,
  ServiceCategory.transportation => Icons.directions_car_filled_rounded,
  ServiceCategory.convenience => Icons.widgets_rounded,
};

String formatServicePrice(double amount) {
  final rounded = amount.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}${buffer.toString()} đ';
}

String formatServiceQuantity(num quantity) => quantity == quantity.round()
    ? quantity.toInt().toString()
    : quantity
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');

String formatServiceDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)} · '
      '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}
