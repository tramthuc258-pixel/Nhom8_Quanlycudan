import 'package:flutter/material.dart';

import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

import '../controllers/notification_controller.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({
    required this.controller,
    required this.user,
    required this.onOpenNotification,
    super.key,
  });
  final NotificationController controller;
  final User user;
  final Future<void> Function(BuildContext context, AppNotification item)
  onOpenNotification;
  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  bool _unreadOnly = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.loadForUser(widget.user.id),
    );
  }

  @override
  Widget build(BuildContext context) => ResidentPageScaffold(
    title: 'Trung tâm thông báo',
    subtitle: 'Cập nhật mới nhất từ mọi dịch vụ Homie',
    icon: Icons.notifications_none_rounded,
    accentColor: AppColors.community,
    accentSoftColor: AppColors.communitySoft,
    actions: [
      ListenableBuilder(
        listenable: widget.controller,
        builder: (_, _) => TextButton.icon(
          onPressed: widget.controller.unreadCountFor(widget.user.id) == 0
              ? null
              : () => widget.controller.markAllAsRead(widget.user.id),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Đọc tất cả'),
        ),
      ),
    ],
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.notifications
            .where((item) => !_unreadOnly || !item.isRead)
            .toList();
        if (widget.controller.isLoading && items.isEmpty) {
          return const LoadingView(message: 'Đang tải thông báo…');
        }
        if (widget.controller.errorMessage != null && items.isEmpty) {
          return ErrorView(
            message: widget.controller.errorMessage,
            onRetry: () => widget.controller.loadForUser(widget.user.id),
          );
        }
        return RefreshIndicator(
          onRefresh: () => widget.controller.loadForUser(widget.user.id),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _NotificationOverview(
                        total: widget.controller.notifications.length,
                        unread: widget.controller.unreadCountFor(
                          widget.user.id,
                        ),
                        unreadOnly: _unreadOnly,
                        onFilterChanged: (value) =>
                            setState(() => _unreadOnly = value),
                      ),
                      const SizedBox(height: 18),
                      if (items.isEmpty)
                        const SizedBox(
                          height: 410,
                          child: EmptyView(
                            icon: Icons.notifications_off_outlined,
                            title: 'Không có thông báo phù hợp',
                            message: 'Các cập nhật mới sẽ xuất hiện tại đây.',
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 14.0;
                            final cardWidth = constraints.maxWidth >= 820
                                ? (constraints.maxWidth - gap) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: <Widget>[
                                for (final item in items)
                                  SizedBox(
                                    width: cardWidth,
                                    child: _NotificationCard(
                                      item: item,
                                      icon: _iconFor(item.type),
                                      dateText: _dateText(item.createdAt),
                                      actionLabel: item.referenceType != null
                                          ? 'Mở chi tiết'
                                          : item.isRead
                                          ? 'Đã đọc'
                                          : 'Đánh dấu đã đọc',
                                      onTap:
                                          item.referenceType == null &&
                                              item.isRead
                                          ? null
                                          : () async =>
                                                widget.onOpenNotification(
                                                  context,
                                                  item,
                                                ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.invoice => Icons.receipt_long_outlined,
    AppNotificationType.maintenance => Icons.build_circle_outlined,
    AppNotificationType.housing => Icons.real_estate_agent_outlined,
    AppNotificationType.amenity => Icons.event_available_outlined,
    AppNotificationType.service => Icons.room_service_outlined,
    AppNotificationType.system => Icons.info_outline_rounded,
  };
  String _dateText(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _NotificationOverview extends StatelessWidget {
  const _NotificationOverview({
    required this.total,
    required this.unread,
    required this.unreadOnly,
    required this.onFilterChanged,
  });

  final int total;
  final int unread;
  final bool unreadOnly;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? <Color>[scheme.surface, scheme.surfaceContainerHigh]
              : <Color>[Colors.white, AppColors.communitySoft],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.community.withValues(alpha: .14)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D173B76),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.community,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$unread cập nhật chưa đọc',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$total thông báo trong hộp thư của bạn',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          FilterChip(
            avatar: const Icon(Icons.mark_email_unread_outlined, size: 18),
            label: const Text('Chỉ xem chưa đọc'),
            selected: unreadOnly,
            onSelected: onFilterChanged,
            selectedColor: AppColors.community.withValues(alpha: .14),
            checkmarkColor: AppColors.community,
            side: BorderSide(color: AppColors.community.withValues(alpha: .18)),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.icon,
    required this.dateText,
    required this.actionLabel,
    required this.onTap,
  });

  final AppNotification item;
  final IconData icon;
  final String dateText;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(item.type);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark
                ? (item.isRead ? scheme.surface : Color.lerp(palette.$1, scheme.surface, .88))
                : (item.isRead ? Colors.white : palette.$2),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: item.isRead
                  ? scheme.outlineVariant
                  : palette.$1.withValues(alpha: .20),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A173B76),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dark ? palette.$1.withValues(alpha: .18) : palette.$2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: palette.$1),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: item.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: palette.$1,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: palette.$1,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dateText,
                          style: TextStyle(
                            color: palette.$1,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          actionLabel,
                          style: TextStyle(
                            color: item.isRead
                                ? scheme.onSurfaceVariant
                                : palette.$1,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _paletteFor(AppNotificationType type) => switch (type) {
    AppNotificationType.invoice => (AppColors.billing, AppColors.billingSoft),
    AppNotificationType.maintenance => (
      AppColors.maintenance,
      AppColors.maintenanceSoft,
    ),
    AppNotificationType.housing => (AppColors.primary, AppColors.primaryLight),
    AppNotificationType.amenity => (AppColors.amenity, AppColors.amenitySoft),
    AppNotificationType.service => (AppColors.service, AppColors.serviceSoft),
    AppNotificationType.system => (
      AppColors.secondary,
      AppColors.secondaryLight,
    ),
  };
}
