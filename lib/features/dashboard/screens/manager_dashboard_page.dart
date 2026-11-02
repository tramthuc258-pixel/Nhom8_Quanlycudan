import 'package:flutter/material.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/widgets/user_avatar.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/notifications/controllers/notification_controller.dart';
import 'package:homie/features/reports/controllers/report_controller.dart';
import 'package:homie/features/reports/models/management_report.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/membership_type.dart';

/// Bảng điều khiển tổng quan dành cho ban quản lý.
///
/// Số liệu tổng quan được tổng hợp từ dữ liệu API của các phân hệ.
/// Trên màn hình lớn, menu được hiển thị dạng sidebar; trên điện thoại, menu
/// chuyển thành drawer để cùng một mã nguồn có thể chạy đa nền tảng.
class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({
    required this.user,
    required this.reportController,
    required this.notificationController,
    required this.onLogout,
    required this.onOpenApartments,
    required this.onOpenResidents,
    required this.onOpenAnnouncements,
    required this.onOpenInvoices,
    required this.onOpenMaintenance,
    required this.onOpenServices,
    required this.onOpenHousing,
    required this.onOpenAmenities,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.onOpenReports,
    required this.onOpenTemporaryStays,
    required this.onOpenSecurityIncidents,
    required this.onOpenStaffAssignments,
    required this.onOpenAuditLogs,
    super.key,
  });

  final User user;
  final ReportController reportController;
  final NotificationController notificationController;
  final VoidCallback onLogout;
  final VoidCallback onOpenApartments;
  final VoidCallback onOpenResidents;
  final VoidCallback onOpenAnnouncements;
  final VoidCallback onOpenInvoices;
  final VoidCallback onOpenMaintenance;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenHousing;
  final VoidCallback onOpenAmenities;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenTemporaryStays;
  final VoidCallback onOpenSecurityIncidents;
  final VoidCallback onOpenStaffAssignments;
  final VoidCallback onOpenAuditLogs;

  static const Color _primary = Color(0xFF3157D5);
  static const Color _navy = Color(0xFF17213B);
  static const Color _surface = Color(0xFFF5F7FB);

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$feature sẽ được hoàn thiện ở bước tiếp theo.'),
        ),
      );
  }

  void _handleAction(BuildContext context, String feature) {
    if (!_canAccessFeature(user.role, feature)) {
      _showComingSoon(context, 'Tài khoản không có quyền mở $feature');
      return;
    }
    if (feature == 'Căn hộ' || feature == 'Quản lý căn hộ') {
      onOpenApartments();
      return;
    }
    if (feature == 'Cư dân' || feature == 'Quản lý cư dân') {
      onOpenResidents();
      return;
    }
    if (feature == 'Thông báo' || feature == 'Tạo thông báo') {
      onOpenAnnouncements();
      return;
    }
    if (feature == 'Trung tâm thông báo') {
      onOpenNotifications();
      return;
    }
    if (feature == 'Hồ sơ cá nhân') {
      onOpenProfile();
      return;
    }
    if (feature == 'Báo cáo') {
      onOpenReports();
      return;
    }
    if (feature == 'Hóa đơn & công nợ') {
      onOpenInvoices();
      return;
    }
    if (feature == 'Yêu cầu sửa chữa' || feature == 'Quản lý yêu cầu') {
      onOpenMaintenance();
      return;
    }
    if (feature == 'Dịch vụ') {
      onOpenServices();
      return;
    }
    if (feature == 'Hồ sơ thuê/mua') {
      onOpenHousing();
      return;
    }
    if (feature == 'Tiện ích') {
      onOpenAmenities();
      return;
    }
    if (feature == 'Khách lưu trú') {
      onOpenTemporaryStays();
      return;
    }
    if (feature == 'An ninh') {
      onOpenSecurityIncidents();
      return;
    }
    if (feature == 'Nhân sự & phân công') {
      onOpenStaffAssignments();
      return;
    }
    if (feature == 'Nhật ký quản trị') {
      onOpenAuditLogs();
      return;
    }
    _showComingSoon(context, feature);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidebar = constraints.maxWidth >= 1000;
        return Scaffold(
          backgroundColor: _surface,
          drawer: useSidebar
              ? null
              : Drawer(
                  width: 282,
                  child: SafeArea(
                    child: _ManagerNavigation(
                      user: user,
                      onLogout: onLogout,
                      onSelect: (label) {
                        Navigator.of(context).pop();
                        if (label != 'Tổng quan') {
                          _handleAction(context, label);
                        }
                      },
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (useSidebar)
                  SizedBox(
                    width: 264,
                    child: _ManagerNavigation(
                      user: user,
                      onLogout: onLogout,
                      onSelect: (label) {
                        if (label != 'Tổng quan') {
                          _handleAction(context, label);
                        }
                      },
                    ),
                  ),
                Expanded(
                  child: _ManagerContent(
                    user: user,
                    reportController: reportController,
                    notificationController: notificationController,
                    showMenuButton: !useSidebar,
                    onAction: (label) => _handleAction(context, label),
                    onLogout: onLogout,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ManagerContent extends StatefulWidget {
  const _ManagerContent({
    required this.user,
    required this.reportController,
    required this.notificationController,
    required this.showMenuButton,
    required this.onAction,
    required this.onLogout,
  });

  final User user;
  final ReportController reportController;
  final NotificationController notificationController;
  final bool showMenuButton;
  final ValueChanged<String> onAction;
  final VoidCallback onLogout;

  @override
  State<_ManagerContent> createState() => _ManagerContentState();
}

class _ManagerContentState extends State<_ManagerContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.notificationController.loadForUser(widget.user.id);
      if (widget.user.role.isManager) widget.reportController.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.reportController,
        widget.notificationController,
      ]),
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final report = widget.reportController.report;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.showMenuButton ? 16 : 30,
        widget.showMenuButton ? 10 : 26,
        widget.showMenuButton ? 16 : 30,
        36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ManagerHeader(
                user: widget.user,
                unreadCount: widget.notificationController.unreadCountFor(
                  widget.user.id,
                ),
                showMenuButton: widget.showMenuButton,
                onLogout: widget.onLogout,
                onAction: widget.onAction,
              ),
              const SizedBox(height: 26),
              _WelcomePanel(user: widget.user, onAction: widget.onAction),
              const SizedBox(height: 22),
              if (!widget.user.role.isManager)
                _StaffActionGrid(
                  role: widget.user.role,
                  onAction: widget.onAction,
                )
              else ...[
                if (widget.reportController.isLoading && report == null)
                  const LinearProgressIndicator()
                else if (widget.reportController.errorMessage != null &&
                    report == null)
                  _DashboardError(
                    message: widget.reportController.errorMessage!,
                    onRetry: widget.reportController.load,
                  )
                else if (report != null) ...[
                  _StatisticsGrid(report: report),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 870) {
                        return Column(
                          children: [
                            _RevenueCard(report: report),
                            const SizedBox(height: 18),
                            _OccupancyCard(
                              report: report,
                              onAction: widget.onAction,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _RevenueCard(report: report),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _OccupancyCard(
                              report: report,
                              onAction: widget.onAction,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 940) {
                        return Column(
                          children: [
                            _RecentRequests(
                              controller: widget.reportController,
                              onAction: widget.onAction,
                            ),
                            const SizedBox(height: 18),
                            _ApartmentChanges(
                              controller: widget.reportController,
                              onAction: widget.onAction,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _RecentRequests(
                              controller: widget.reportController,
                              onAction: widget.onAction,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 2,
                            child: _ApartmentChanges(
                              controller: widget.reportController,
                              onAction: widget.onAction,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerHeader extends StatelessWidget {
  const _ManagerHeader({
    required this.user,
    required this.unreadCount,
    required this.showMenuButton,
    required this.onLogout,
    required this.onAction,
  });

  final User user;
  final int unreadCount;
  final bool showMenuButton;
  final VoidCallback onLogout;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMenuButton) ...[
          Builder(
            builder: (context) => IconButton.filledTonal(
              tooltip: 'Mở menu',
              onPressed: Scaffold.of(context).openDrawer,
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng quan vận hành',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ManagerDashboardPage._navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatDashboardDate(DateTime.now()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF7A849D), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Thông báo',
          onPressed: () => onAction('Trung tâm thông báo'),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Tài khoản quản lý',
          onSelected: (value) {
            if (value == 'logout') {
              onLogout();
            } else {
              onAction('Hồ sơ cá nhân');
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text('Hồ sơ cá nhân')),
            PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
          ],
          child: UserAvatar(
            user: user,
            radius: 20,
            backgroundColor: const Color(0xFFE7ECFF),
            foregroundColor: ManagerDashboardPage._primary,
          ),
        ),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.user, required this.onAction});

  final User user;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E357C), Color(0xFF3157D5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x263157D5),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final greeting = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BẢNG ĐIỀU KHIỂN HOMIE',
                style: TextStyle(
                  color: Color(0xFFBFCBFF),
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chào ${user.fullName},',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user.role.isManager
                    ? 'Theo dõi tình hình vận hành chung của khu căn hộ.'
                    : 'Không gian làm việc dành cho ${user.role.label.toLowerCase()}.',
                style: TextStyle(color: Color(0xFFE4E8FF), fontSize: 13),
              ),
            ],
          );
          final button = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ManagerDashboardPage._primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            onPressed: () => onAction(
              user.role.canManageAnnouncements
                  ? 'Tạo thông báo'
                  : 'Trung tâm thông báo',
            ),
            icon: Icon(
              user.role.canManageAnnouncements
                  ? Icons.add_rounded
                  : Icons.notifications_none_rounded,
              size: 19,
            ),
            label: Text(
              user.role.canManageAnnouncements
                  ? 'Tạo thông báo'
                  : 'Xem thông báo',
            ),
          );
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [greeting, const SizedBox(height: 18), button],
            );
          }
          return Row(
            children: [
              Expanded(child: greeting),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _StaffActionGrid extends StatelessWidget {
  const _StaffActionGrid({required this.role, required this.onAction});

  final UserRole role;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final items = _ManagerNavigation.items
        .where((item) => item.$1 != 'Tổng quan')
        .where((item) => _canAccessFeature(role, item.$1))
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _AdminCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: () => onAction(item.$1),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE7ECFF),
                        foregroundColor: ManagerDashboardPage._primary,
                        child: Icon(item.$2),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC64652)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.report});

  final ManagementReport report;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        'Căn hộ đang sử dụng',
        '${report.occupiedApartments}/${report.totalApartments}',
        '${report.vacantApartments} căn đang trống',
        Icons.apartment_rounded,
        const Color(0xFFE7ECFF),
        const Color(0xFF3157D5),
        true,
      ),
      _StatData(
        'Cư dân đang hoạt động',
        '${report.activeResidents}',
        'Theo quan hệ cư trú hiện tại',
        Icons.groups_2_outlined,
        const Color(0xFFE4F7EF),
        const Color(0xFF25845B),
        true,
      ),
      _StatData(
        'Công nợ',
        _formatCompactCurrency(report.outstandingDebt),
        'Đã thu ${(report.invoiceCollectionRate * 100).round()}%',
        Icons.account_balance_wallet_outlined,
        const Color(0xFFFFF0E5),
        const Color(0xFFD76B2D),
        false,
      ),
      _StatData(
        'Yêu cầu chờ xử lý',
        '${report.openMaintenanceRequests}',
        '${report.completedMaintenanceRequests} yêu cầu đã hoàn thành',
        Icons.build_circle_outlined,
        const Color(0xFFFFE9EB),
        const Color(0xFFC64652),
        false,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 4
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 148,
          ),
          itemBuilder: (context, index) => _StatCard(data: stats[index]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF707991),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ManagerDashboardPage._navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      data.positive
                          ? Icons.trending_up_rounded
                          : Icons.info_outline_rounded,
                      color: data.positive
                          ? const Color(0xFF25845B)
                          : data.foreground,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        data.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: data.positive
                              ? const Color(0xFF25845B)
                              : data.foreground,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(data.icon, color: data.foreground, size: 25),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.report});

  final ManagementReport report;

  @override
  Widget build(BuildContext context) {
    final monthly = report.monthlyRevenue;
    final maxValue = monthly.fold<double>(
      0,
      (maximum, item) => item.value > maximum ? item.value : maximum,
    );
    final total = monthly.fold<double>(0, (sum, item) => sum + item.value);
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _AdminSectionTitle(
                  title: 'Tình hình thu phí',
                  subtitle: 'Tổng thu trong 6 tháng gần nhất',
                ),
              ),
              _PeriodChip(label: '6 tháng'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCompactCurrency(total),
                style: const TextStyle(
                  color: ManagerDashboardPage._navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${monthly.where((item) => item.value > 0).length}/6 tháng có thu',
                  style: const TextStyle(
                    color: Color(0xFF25845B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < monthly.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: maxValue == 0
                                    ? 0.04
                                    : (monthly[index].value / maxValue).clamp(
                                        0.04,
                                        1.0,
                                      ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: index == monthly.length - 1
                                        ? ManagerDashboardPage._primary
                                        : const Color(0xFFDDE4FA),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            monthly[index].label,
                            style: const TextStyle(
                              color: Color(0xFF8B93A8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({required this.report, required this.onAction});

  final ManagementReport report;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final occupancy = report.totalApartments == 0
        ? 0.0
        : report.occupiedApartments / report.totalApartments;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminSectionTitle(
            title: 'Tỷ lệ lấp đầy',
            subtitle: 'Tình trạng ${report.totalApartments} căn hộ',
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 142,
              height: 142,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: occupancy,
                      strokeWidth: 14,
                      color: ManagerDashboardPage._primary,
                      backgroundColor: Color(0xFFE7EBF5),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(occupancy * 100).round()}%',
                        style: const TextStyle(
                          color: ManagerDashboardPage._navy,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'đang sử dụng',
                        style: TextStyle(
                          color: Color(0xFF8B93A8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _LegendRow(
            color: ManagerDashboardPage._primary,
            label: 'Đang sử dụng',
            value: '${report.occupiedApartments}',
          ),
          const SizedBox(height: 9),
          _LegendRow(
            color: Color(0xFFE7EBF5),
            label: 'Đang trống',
            value: '${report.vacantApartments}',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onAction('Quản lý căn hộ'),
              child: const Text('Quản lý căn hộ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRequests extends StatelessWidget {
  const _RecentRequests({required this.controller, required this.onAction});

  final ReportController controller;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final recent = controller.maintenanceController.requests.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final requests = recent
        .take(3)
        .map((request) => _requestData(controller, request))
        .toList(growable: false);
    return _AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: _AdminSectionTitle(
                    title: 'Yêu cầu mới nhất',
                    subtitle: 'Các phản ánh cần được theo dõi',
                  ),
                ),
                TextButton(
                  onPressed: () => onAction('Quản lý yêu cầu'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text('Chưa có yêu cầu sửa chữa nào.'),
            )
          else
            for (var index = 0; index < requests.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, indent: 20, endIndent: 20),
              _ManagementRequestTile(data: requests[index]),
            ],
        ],
      ),
    );
  }
}

class _ManagementRequestTile extends StatelessWidget {
  const _ManagementRequestTile({required this.data});

  final _RequestData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.build_outlined, color: data.foreground, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ManagerDashboardPage._navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.id} · ${data.resident}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B93A8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.status,
              style: TextStyle(
                color: data.foreground,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApartmentChanges extends StatelessWidget {
  const _ApartmentChanges({required this.controller, required this.onAction});

  final ReportController controller;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final memberships = controller.apartmentController.memberships.toList()
      ..sort(
        (a, b) =>
            (b.endDate ?? b.startDate).compareTo(a.endDate ?? a.startDate),
      );
    final recent = memberships.take(3).toList(growable: false);
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _AdminSectionTitle(
                  title: 'Biến động cư trú',
                  subtitle: 'Các thay đổi gần nhất',
                ),
              ),
              IconButton(
                tooltip: 'Xem chi tiết',
                onPressed: () => onAction('Quản lý cư dân'),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recent.isEmpty)
            const Text('Chưa có biến động cư trú.')
          else
            for (var index = 0; index < recent.length; index++) ...[
              if (index > 0) const SizedBox(height: 17),
              _membershipChange(controller, recent[index]),
            ],
        ],
      ),
    );
  }
}

class _ManagerNavigation extends StatelessWidget {
  const _ManagerNavigation({
    required this.user,
    required this.onLogout,
    required this.onSelect,
  });

  final User user;
  final VoidCallback onLogout;
  final ValueChanged<String> onSelect;

  static const items = [
    ('Tổng quan', Icons.grid_view_rounded),
    ('Căn hộ', Icons.apartment_outlined),
    ('Cư dân', Icons.groups_2_outlined),
    ('Hóa đơn & công nợ', Icons.receipt_long_outlined),
    ('Yêu cầu sửa chữa', Icons.build_circle_outlined),
    ('Dịch vụ', Icons.room_service_outlined),
    ('Hồ sơ thuê/mua', Icons.real_estate_agent_outlined),
    ('Tiện ích', Icons.event_available_outlined),
    ('Khách lưu trú', Icons.badge_outlined),
    ('An ninh', Icons.shield_outlined),
    ('Thông báo', Icons.campaign_outlined),
    ('Trung tâm thông báo', Icons.notifications_active_outlined),
    ('Hồ sơ cá nhân', Icons.person_outline_rounded),
    ('Báo cáo', Icons.bar_chart_rounded),
    ('Nhân sự & phân công', Icons.manage_accounts_rounded),
    ('Nhật ký quản trị', Icons.policy_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => _canAccessFeature(user.role, item.$1))
        .toList(growable: false);
    return Container(
      color: const Color(0xFF15213F),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                const _AdminLogo(),
                const SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HOMIE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      user.role.label.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF9EABD1),
                        letterSpacing: 1.1,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: visibleItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return _NavigationItem(
                  label: item.$1,
                  icon: item.$2,
                  selected: index == 0,
                  onTap: () => onSelect(item.$1),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF2B3858)),
          const SizedBox(height: 9),
          Row(
            children: [
              UserAvatar(
                user: user,
                radius: 19,
                backgroundColor: const Color(0xFF3157D5),
                foregroundColor: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.role.label,
                      style: const TextStyle(
                        color: Color(0xFF9EABD1),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: onLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFB7C2E2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF3157D5) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF9EABD1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFD1D8EE),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLogo extends StatelessWidget {
  const _AdminLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF3157D5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 22),
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ManagerDashboardPage._navy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF8B93A8), fontSize: 11),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE8EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0917213B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667089),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 15),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF707991), fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: ManagerDashboardPage._navy,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ManagerDashboardPage._navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8B93A8), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatData {
  const _StatData(
    this.label,
    this.value,
    this.note,
    this.icon,
    this.background,
    this.foreground,
    this.positive,
  );

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool positive;
}

class _RequestData {
  const _RequestData(
    this.id,
    this.title,
    this.resident,
    this.status,
    this.foreground,
    this.background,
  );

  final String id;
  final String title;
  final String resident;
  final String status;
  final Color foreground;
  final Color background;
}

_RequestData _requestData(
  ReportController controller,
  MaintenanceRequest request,
) {
  final apartment = controller.apartmentController.apartmentById(
    request.apartmentId,
  );
  final resident = controller.apartmentController.residentById(
    request.residentId,
  );
  final urgent = request.priority == MaintenancePriority.urgent;
  final active = request.isOpen && !urgent;
  return _RequestData(
    request.code,
    request.title,
    '${apartment?.code ?? 'Chưa rõ căn'} · ${resident?.fullName ?? 'Chưa rõ cư dân'}',
    urgent ? request.priority.label : request.status.label,
    urgent
        ? const Color(0xFFC64652)
        : active
        ? const Color(0xFF3157D5)
        : const Color(0xFF25845B),
    urgent
        ? const Color(0xFFFFE9EB)
        : active
        ? const Color(0xFFE7ECFF)
        : const Color(0xFFE4F7EF),
  );
}

Widget _membershipChange(
  ReportController controller,
  ApartmentMembership membership,
) {
  final apartment = controller.apartmentController.apartmentById(
    membership.apartmentId,
  );
  final resident = controller.apartmentController.residentById(
    membership.residentId,
  );
  final ended = !membership.isActive;
  final (icon, color, background, title) = ended
      ? (
          Icons.person_remove_outlined,
          const Color(0xFFD76B2D),
          const Color(0xFFFFF0E5),
          'Kết thúc ${membership.type.displayName.toLowerCase()}',
        )
      : switch (membership.type) {
          MembershipType.owner => (
            Icons.swap_horiz_rounded,
            const Color(0xFF3157D5),
            const Color(0xFFE7ECFF),
            'Cập nhật chủ sở hữu',
          ),
          MembershipType.tenant => (
            Icons.person_add_alt_1_outlined,
            const Color(0xFF25845B),
            const Color(0xFFE4F7EF),
            'Thêm người thuê',
          ),
        };
  final eventDate = membership.endDate ?? membership.startDate;
  return _ChangeRow(
    icon: icon,
    color: color,
    background: background,
    title: title,
    detail:
        'Căn ${apartment?.code ?? '--'} · ${resident?.fullName ?? 'Chưa rõ'} · ${_formatShortDate(eventDate)}',
  );
}

String _formatCompactCurrency(double value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2).replaceAll('.', ',')} tỷ ₫';
  }
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} tr ₫';
  }
  final digits = value.round().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '$formatted ₫';
}

String _formatDashboardDate(DateTime value) {
  const weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  return '${weekdays[value.weekday - 1]}, ${value.day} tháng ${value.month} năm ${value.year}';
}

String _formatShortDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}

bool _canAccessFeature(UserRole role, String feature) {
  if (feature == 'Tổng quan' ||
      feature == 'Trung tâm thông báo' ||
      feature == 'Hồ sơ cá nhân') {
    return true;
  }
  if (feature == 'Căn hộ' || feature == 'Quản lý căn hộ') {
    return role.canManageApartments;
  }
  if (feature == 'Cư dân' || feature == 'Quản lý cư dân') {
    return role.canManageResidents;
  }
  if (feature == 'Thông báo' || feature == 'Tạo thông báo') {
    return role.canManageAnnouncements;
  }
  if (feature == 'Hóa đơn & công nợ') return role.canViewInvoices;
  if (feature == 'Yêu cầu sửa chữa' || feature == 'Quản lý yêu cầu') {
    return role.canManageMaintenance;
  }
  if (feature == 'Dịch vụ') return role.canManageServices;
  if (feature == 'Hồ sơ thuê/mua') return role.canManageHousing;
  if (feature == 'Tiện ích') return role.canManageAmenities;
  if (feature == 'Khách lưu trú') return role.canManageTemporaryStays;
  if (feature == 'An ninh') return role.canManageSecurityIncidents;
  if (feature == 'Báo cáo') return role.canOpenReports;
  if (feature == 'Nhân sự & phân công') {
    return role.canManageStaffAssignments;
  }
  if (feature == 'Nhật ký quản trị') return role == UserRole.admin;
  return false;
}
