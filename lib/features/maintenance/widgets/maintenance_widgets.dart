import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/core/widgets/status_badge.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';

String formatMaintenanceDate(DateTime value, {bool includeTime = false}) {
  String two(int number) => number.toString().padLeft(2, '0');
  final date = '${two(value.day)}/${two(value.month)}/${value.year}';
  return includeTime ? '$date · ${two(value.hour)}:${two(value.minute)}' : date;
}

class MaintenanceStatusBadge extends StatelessWidget {
  const MaintenanceStatusBadge({required this.status, super.key});

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      MaintenanceStatus.submitted => (
        StatusBadgeTone.info,
        Icons.outbox_outlined,
      ),
      MaintenanceStatus.received => (
        StatusBadgeTone.info,
        Icons.mark_email_read_outlined,
      ),
      MaintenanceStatus.inProgress => (
        StatusBadgeTone.warning,
        Icons.build_circle_outlined,
      ),
      MaintenanceStatus.waitingResident => (
        StatusBadgeTone.warning,
        Icons.hourglass_top_rounded,
      ),
      MaintenanceStatus.completed => (
        StatusBadgeTone.success,
        Icons.task_alt_rounded,
      ),
      MaintenanceStatus.cancelled => (
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

class MaintenancePriorityBadge extends StatelessWidget {
  const MaintenancePriorityBadge({required this.priority, super.key});

  final MaintenancePriority priority;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (priority) {
      MaintenancePriority.low => (
        StatusBadgeTone.neutral,
        Icons.arrow_downward_rounded,
      ),
      MaintenancePriority.normal => (
        StatusBadgeTone.info,
        Icons.remove_rounded,
      ),
      MaintenancePriority.high => (
        StatusBadgeTone.warning,
        Icons.arrow_upward_rounded,
      ),
      MaintenancePriority.urgent => (
        StatusBadgeTone.danger,
        Icons.priority_high_rounded,
      ),
    };
    return StatusBadge(
      label: priority.label,
      tone: tone,
      icon: icon,
      compact: true,
    );
  }
}

class MaintenanceRequestCard extends StatelessWidget {
  const MaintenanceRequestCard({
    required this.request,
    required this.apartmentCode,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final MaintenanceRequest request;
  final String apartmentCode;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: request.priority == MaintenancePriority.urgent
                          ? AppColors.errorContainer
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_repair_service_rounded,
                      color: request.priority == MaintenancePriority.urgent
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.code,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: scheme.primary),
                        ),
                        Text(
                          'Căn $apartmentCode · ${request.category.label}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) MaintenanceStatusBadge(status: request.status),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 10),
                MaintenanceStatusBadge(status: request.status),
              ],
              const SizedBox(height: 14),
              Text(
                request.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
              ),
              if (compact) const SizedBox(height: 14) else const Spacer(),
              const Divider(height: 22),
              Row(
                children: [
                  MaintenancePriorityBadge(priority: request.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.assignedTo ?? 'Chưa phân công',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    formatMaintenanceDate(request.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

class MaintenanceTimeline extends StatelessWidget {
  const MaintenanceTimeline({required this.request, super.key});

  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
    final updates = request.history.reversed.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử xử lý',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < updates.length; index++)
          _TimelineEntry(
            update: updates[index],
            isLast: index == updates.length - 1,
          ),
      ],
    );
  }
}

class MaintenanceAttachments extends StatelessWidget {
  const MaintenanceAttachments({required this.urls, super.key});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tệp hiện trường (${urls.length})',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final url in urls) _AttachmentPreview(url: url)],
        ),
      ],
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isPdf =
        Uri.tryParse(url)?.path.toLowerCase().endsWith('.pdf') ?? false;
    if (isPdf) {
      return Container(
        width: 180,
        height: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
            SizedBox(height: 6),
            Text('Tài liệu PDF', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 150,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 150,
          height: 110,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.update, required this.isLast});

  final MaintenanceUpdate update;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          update.status.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        formatMaintenanceDate(
                          update.createdAt,
                          includeTime: true,
                        ),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(update.note),
                  const SizedBox(height: 3),
                  Text(
                    'Cập nhật bởi ${update.actorName}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
