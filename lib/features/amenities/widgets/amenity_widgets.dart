import 'package:flutter/material.dart';

import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/amenities/models/amenity_category.dart';

String amenityDateTime(DateTime value) {
  final date =
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$time · $date';
}

String amenityMoney(double value) {
  if (value == 0) return 'Miễn phí';
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${buffer.toString()} đ/lượt';
}

IconData amenityIcon(AmenityCategory category) => switch (category) {
  AmenityCategory.pool => Icons.pool_outlined,
  AmenityCategory.gym => Icons.fitness_center_outlined,
  AmenityCategory.communityRoom => Icons.groups_outlined,
  AmenityCategory.sport => Icons.sports_tennis_outlined,
  AmenityCategory.barbecue => Icons.outdoor_grill_outlined,
};

String amenityImage(AmenityCategory category) => switch (category) {
  AmenityCategory.pool => 'assets/images/amenities/pool.png',
  AmenityCategory.gym => 'assets/images/amenities/gym.png',
  AmenityCategory.communityRoom => 'assets/images/amenities/community-room.png',
  AmenityCategory.sport => 'assets/images/amenities/badminton.png',
  AmenityCategory.barbecue => 'assets/images/amenities/barbecue.png',
};

class AmenityCard extends StatelessWidget {
  const AmenityCard({
    required this.amenity,
    this.onBook,
    this.onToggle,
    this.compact = false,
    super.key,
  });
  final Amenity amenity;
  final VoidCallback? onBook;
  final VoidCallback? onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 122,
            child: Image.asset(
              amenityImage(amenity.category),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: colors.primaryContainer,
                child: Center(
                  child: Icon(
                    amenityIcon(amenity.category),
                    size: 48,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ),
          if (compact)
            _content(context, colors)
          else
            Expanded(child: _content(context, colors)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme colors) => Padding(
    padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
    child: Column(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(amenityIcon(amenity.category), color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amenity.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    amenity.category.label,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            _AmenityStateBadge(active: amenity.isActive),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amenity.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (compact) const SizedBox(height: 15) else const Spacer(),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _Info(
              icon: Icons.group_outlined,
              text: '${amenity.capacity} người',
            ),
            _Info(
              icon: Icons.schedule_outlined,
              text: '${amenity.slotDurationMinutes} phút',
            ),
            _Info(
              icon: Icons.payments_outlined,
              text: amenityMoney(amenity.fee),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (onBook != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: amenity.isActive ? onBook : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(amenity.isActive ? 'Đặt khung giờ' : 'Tạm ngưng'),
            ),
          )
        else if (onToggle != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onToggle,
              icon: Icon(
                amenity.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              label: Text(
                amenity.isActive ? 'Tạm ngưng tiện ích' : 'Mở lại tiện ích',
              ),
            ),
          ),
      ],
    ),
  );
}

class AmenityBookingCard extends StatelessWidget {
  const AmenityBookingCard({
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onApprove,
    this.onReject,
    this.onCheckIn,
    this.onComplete,
    this.onNoShow,
    super.key,
  });
  final AmenityBooking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCheckIn;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.amenityName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          booking.code,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),
              _Info(
                icon: Icons.schedule_outlined,
                text:
                    '${amenityDateTime(booking.startAt)} – ${booking.endAt.hour.toString().padLeft(2, '0')}:${booking.endAt.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 7),
              _Info(
                icon: Icons.person_outline,
                text: booking.isBlocked
                    ? booking.note
                    : '${booking.residentName} · ${booking.attendeeCount} người',
              ),
              if (booking.managementNote != null) ...[
                const SizedBox(height: 9),
                Text(
                  booking.managementNote!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              if (booking.processedByName != null) ...[
                const SizedBox(height: 7),
                _Info(
                  icon: Icons.badge_outlined,
                  text: 'Xử lý bởi ${booking.processedByName}',
                ),
              ],
              if (onCancel != null ||
                  onApprove != null ||
                  onReject != null ||
                  onCheckIn != null ||
                  onComplete != null ||
                  onNoShow != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onApprove != null)
                      FilledButton.tonalIcon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Duyệt'),
                      ),
                    if (onReject != null)
                      OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Từ chối'),
                      ),
                    if (onCancel != null)
                      OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Hủy lượt đặt'),
                      ),
                    if (onCheckIn != null)
                      FilledButton.tonalIcon(
                        onPressed: onCheckIn,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Check-in'),
                      ),
                    if (onComplete != null)
                      FilledButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('Hoàn tất'),
                      ),
                    if (onNoShow != null)
                      OutlinedButton.icon(
                        onPressed: onNoShow,
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('Không đến'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 17,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}

class _AmenityStateBadge extends StatelessWidget {
  const _AmenityStateBadge({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(active ? 'Đang mở' : 'Tạm ngưng'),
    visualDensity: VisualDensity.compact,
    backgroundColor: active
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest,
  );
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.status});
  final AmenityBookingStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AmenityBookingStatus.pending => Colors.orange,
      AmenityBookingStatus.approved => Colors.green,
      AmenityBookingStatus.checkedIn => Colors.blue,
      AmenityBookingStatus.completed => Colors.teal,
      AmenityBookingStatus.noShow => Colors.deepOrange,
      AmenityBookingStatus.rejected => Colors.red,
      AmenityBookingStatus.cancelled ||
      AmenityBookingStatus.blocked => Colors.grey,
    };
    return Chip(
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .12),
    );
  }
}
