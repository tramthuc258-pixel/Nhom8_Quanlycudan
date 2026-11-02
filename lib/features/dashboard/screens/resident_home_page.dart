import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/widgets/user_avatar.dart';
import 'package:homie/features/dashboard/controllers/resident_dashboard_controller.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/features/residents/screens/resident/residence_verification_card.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/residence_verification.dart';
import 'package:homie/features/residents/widgets/resident_apartment_picker.dart';

/// Trang tổng quan dành cho cư dân.
///
/// Dữ liệu trên màn hình được tổng hợp từ các API theo tài khoản đang đăng nhập.
class ResidentHomePage extends StatelessWidget {
  const ResidentHomePage({
    required this.user,
    required this.dashboardController,
    required this.onLogout,
    required this.onOpenHousehold,
    required this.onOpenAnnouncements,
    required this.onOpenInvoices,
    required this.onOpenMaintenance,
    required this.onOpenServices,
    required this.onOpenHousing,
    required this.onOpenAmenities,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.onOpenTemporaryStays,
    required this.onOpenSecurityIncidents,
    this.apartmentCode,
    super.key,
  });

  final User user;
  final ResidentDashboardController dashboardController;
  final VoidCallback onLogout;
  final VoidCallback onOpenHousehold;
  final VoidCallback onOpenAnnouncements;
  final VoidCallback onOpenInvoices;
  final VoidCallback onOpenMaintenance;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenHousing;
  final VoidCallback onOpenAmenities;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenTemporaryStays;
  final VoidCallback onOpenSecurityIncidents;
  final String? apartmentCode;

  static const Color _primary = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;

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
    if (feature == 'Thông tin căn hộ' || feature == 'Căn hộ của tôi') {
      onOpenHousehold();
      return;
    }
    if (feature == 'Thông báo' || feature == 'Tất cả thông báo') {
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
    if (feature == 'Hóa đơn' || feature == 'Chi tiết hóa đơn') {
      onOpenInvoices();
      return;
    }
    if (feature == 'Yêu cầu' ||
        feature == 'Gửi phản ánh' ||
        feature == 'Danh sách yêu cầu') {
      onOpenMaintenance();
      return;
    }
    if (feature == 'Dịch vụ') {
      onOpenServices();
      return;
    }
    if (feature == 'Thuê / mua căn hộ' ||
        feature == 'Nhà ở' ||
        feature == 'Quản lý tài sản') {
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
    _showComingSoon(context, feature);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dashboardController,
      builder: (context, _) {
        final mode = _residentModeFor(dashboardController, user);
        return LayoutBuilder(
          builder: (context, constraints) {
            final useSidebar = constraints.maxWidth >= 980;
            final dark = Theme.of(context).brightness == Brightness.dark;
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? const [
                            Color(0xFF0B1220),
                            Color(0xFF111827),
                            Color(0xFF0B1220),
                          ]
                        : const [
                            Color(0xFFF2F6FF),
                            Color(0xFFF8FAFF),
                            Color(0xFFF0FAF8),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (useSidebar)
                        _ResidentSidebar(
                          user: user,
                          apartmentCode: dashboardController.apartmentCodeFor(
                            user,
                          ),
                          mode: mode,
                          onLogout: onLogout,
                          onSelect: (label) => _handleAction(context, label),
                        ),
                      Expanded(
                        child: _ResidentContent(
                          user: user,
                          controller: dashboardController,
                          apartmentCode: dashboardController.apartmentCodeFor(
                            user,
                          ),
                          compactHeader: !useSidebar,
                          onLogout: onLogout,
                          onAction: (label) => _handleAction(context, label),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: useSidebar
                  ? null
                  : _ResidentBottomNavigation(
                      mode: mode,
                      onSelect: (label) => _handleAction(context, label),
                    ),
            );
          },
        );
      },
    );
  }
}

class _ResidentContent extends StatefulWidget {
  const _ResidentContent({
    required this.user,
    required this.controller,
    required this.apartmentCode,
    required this.compactHeader,
    required this.onLogout,
    required this.onAction,
  });

  final User user;
  final ResidentDashboardController controller;
  final String? apartmentCode;
  final bool compactHeader;
  final VoidCallback onLogout;
  final ValueChanged<String> onAction;

  @override
  State<_ResidentContent> createState() => _ResidentContentState();
}

class _ResidentContentState extends State<_ResidentContent> {
  bool _initializingApartment = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeApartment();
    });
  }

  Future<void> _initializeApartment() async {
    final apartmentController = widget.controller.apartmentController;
    await apartmentController.restoreApartmentForResident(widget.user.id);
    await widget.controller.load(widget.user);
    if (!mounted) return;
    final memberships = apartmentController.activeMembershipsForResident(
      widget.user.id,
    );
    final savedId = apartmentController.selectedApartmentIdForResident(
      widget.user.id,
    );
    setState(() => _initializingApartment = false);
    if (memberships.length > 1 &&
        !memberships.any((membership) => membership.apartmentId == savedId)) {
      await showResidentApartmentPicker(
        context: context,
        controller: apartmentController,
        residentId: widget.user.id,
        requireSelection: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializingApartment) {
      return const Center(child: CircularProgressIndicator());
    }
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final controller = widget.controller;
    final user = widget.user;
    final resolvedApartmentCode =
        controller.apartmentCodeFor(user) ?? widget.apartmentCode;
    final unreadCount = controller.unreadCountFor(user);
    final invoices = controller.outstandingInvoicesFor(user);
    final requests = controller.recentRequestsFor(user);
    final announcements = controller.recentAnnouncementsFor(user);
    final mode = _residentModeFor(controller, user);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.compactHeader ? 16 : 32,
        widget.compactHeader ? 12 : 28,
        widget.compactHeader ? 16 : 32,
        32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.compactHeader)
                _MobileHeader(
                  user: user,
                  mode: mode,
                  unreadCount: unreadCount,
                  onLogout: widget.onLogout,
                  onAction: widget.onAction,
                )
              else
                _DesktopPageTitle(
                  user: user,
                  mode: mode,
                  unreadCount: unreadCount,
                  onAction: widget.onAction,
                ),
              SizedBox(height: widget.compactHeader ? 18 : 26),
              if (controller.apartmentController.activeMembershipForResident(
                    user.id,
                  ) !=
                  null) ...[
                _ActiveApartmentCard(controller: controller, user: user),
                const SizedBox(height: 16),
              ],
              if (controller.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              if (controller.errorMessage != null) ...[
                _ResidentDashboardError(
                  message: controller.errorMessage!,
                  onRetry: () => controller.load(user),
                ),
                const SizedBox(height: 12),
              ],
              _WelcomeBanner(
                user: user,
                mode: mode,
                apartmentCode: resolvedApartmentCode,
                onAction: widget.onAction,
              ),
              const SizedBox(height: 18),
              if (controller.apartmentController.myVerification.state !=
                  ResidenceVerificationState.approved) ...<Widget>[
                ResidenceVerificationCard(
                  controller: controller.apartmentController,
                  user: user,
                ),
                const SizedBox(height: 28),
              ] else
                const SizedBox(height: 10),
              _SectionTitle(
                title: mode == _ResidentMode.ownerManaging
                    ? 'Quản lý căn hộ'
                    : 'Bạn muốn làm gì?',
                subtitle: mode == _ResidentMode.ownerManaging
                    ? 'Các nghiệp vụ dành cho chủ sở hữu đang cho thuê căn hộ'
                    : 'Truy cập nhanh các tiện ích thường dùng',
              ),
              const SizedBox(height: 14),
              _QuickActions(mode: mode, onAction: widget.onAction),
              const SizedBox(height: 18),
              if (mode == _ResidentMode.ownerManaging)
                _OwnerPropertyNotice(onAction: widget.onAction)
              else
                _ResidentActivitySummary(
                  controller: controller,
                  user: user,
                  onAction: widget.onAction,
                ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 760;
                  final billCard = _InvoiceOverview(
                    invoices: invoices,
                    totalOutstanding: controller.outstandingAmountFor(user),
                    onAction: widget.onAction,
                  );
                  final requestCard = _RequestOverview(
                    requests: requests,
                    onAction: widget.onAction,
                  );
                  if (!twoColumns) {
                    return Column(
                      children: [
                        billCard,
                        const SizedBox(height: 18),
                        requestCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: billCard),
                      const SizedBox(width: 18),
                      Expanded(child: requestCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              _Announcements(
                announcements: announcements,
                controller: controller,
                user: user,
                onAction: widget.onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.user,
    required this.mode,
    required this.unreadCount,
    required this.onLogout,
    required this.onAction,
  });

  final User user;
  final _ResidentMode mode;
  final int unreadCount;
  final VoidCallback onLogout;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LogoMark(),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOMIE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  fontSize: 17,
                ),
              ),
              Text(
                _shortPortalTitle(mode),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => onAction('Trung tâm thông báo'),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Tài khoản',
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
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            foregroundColor: ResidentHomePage._primary,
          ),
        ),
      ],
    );
  }
}

class _DesktopPageTitle extends StatelessWidget {
  const _DesktopPageTitle({
    required this.user,
    required this.mode,
    required this.unreadCount,
    required this.onAction,
  });

  final User user;
  final _ResidentMode mode;
  final int unreadCount;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _portalTitle(mode),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_greetingForNow()}, ${_firstName(user.fullName)}',
                style: const TextStyle(
                  color: ResidentHomePage._navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _portalSubtitle(mode),
                style: const TextStyle(color: Color(0xFF7B849E), fontSize: 14),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onAction('Trung tâm thông báo'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      color: ResidentHomePage._navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.user,
    required this.mode,
    required this.apartmentCode,
    required this.onAction,
  });

  final User user;
  final _ResidentMode mode;
  final String? apartmentCode;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final currentApartmentCode = apartmentCode ?? user.apartmentCode;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x352452A4),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth/register-apartments.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF0174AA8),
                    Color(0xDF176BC2),
                    Color(0xA20B8F91),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: -110,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showApartmentPanel = constraints.maxWidth >= 680;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              currentApartmentCode == null
                                  ? 'KHÁM PHÁ HOMIE'
                                  : _modeBadge(mode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Xin chào, ${user.fullName}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 27,
                              height: 1.08,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            currentApartmentCode == null
                                ? 'Khám phá căn hộ phù hợp và bắt đầu trải nghiệm các tiện ích tại Homie.'
                                : _welcomeDescription(mode),
                            style: const TextStyle(
                              color: Color(0xFFE4F1FF),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ResidentHomePage._primary,
                              minimumSize: const Size(0, 46),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => onAction(
                              currentApartmentCode == null
                                  ? 'Thuê / mua căn hộ'
                                  : 'Thông tin căn hộ',
                            ),
                            icon: Icon(
                              currentApartmentCode == null
                                  ? Icons.travel_explore_rounded
                                  : Icons.apartment_rounded,
                              size: 19,
                            ),
                            label: Text(
                              currentApartmentCode == null
                                  ? 'Tìm căn hộ'
                                  : 'Xem căn hộ',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showApartmentPanel) ...[
                      const SizedBox(width: 34),
                      Container(
                        width: 220,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0x66FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                currentApartmentCode == null
                                    ? Icons.real_estate_agent_outlined
                                    : Icons.domain_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              currentApartmentCode == null
                                  ? 'Không gian sống mới'
                                  : 'Căn hộ của bạn',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentApartmentCode ?? 'Chưa liên kết',
                              style: const TextStyle(
                                color: ResidentHomePage._navy,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  currentApartmentCode == null
                                      ? Icons.info_outline_rounded
                                      : Icons.verified_user_rounded,
                                  color: currentApartmentCode == null
                                      ? AppColors.warning
                                      : AppColors.success,
                                  size: 17,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    currentApartmentCode == null
                                        ? 'Có thể liên kết sau'
                                        : 'Dữ liệu đã xác minh',
                                    style: TextStyle(
                                      color: currentApartmentCode == null
                                          ? AppColors.warning
                                          : AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.mode, required this.onAction});

  final _ResidentMode mode;
  final ValueChanged<String> onAction;

  static const _items = [
    _QuickActionData(
      'Gửi phản ánh',
      'Báo sự cố nhanh',
      Icons.handyman_outlined,
      AppColors.maintenanceSoft,
      AppColors.maintenance,
    ),
    _QuickActionData(
      'Hóa đơn',
      'Kiểm tra công nợ',
      Icons.receipt_long_outlined,
      AppColors.billingSoft,
      AppColors.billing,
    ),
    _QuickActionData(
      'Dịch vụ',
      'Đặt dịch vụ cư dân',
      Icons.room_service_rounded,
      AppColors.serviceSoft,
      AppColors.service,
    ),
    _QuickActionData(
      'Tiện ích',
      'Đặt không gian chung',
      Icons.sports_tennis_rounded,
      AppColors.amenitySoft,
      AppColors.amenity,
    ),
    _QuickActionData(
      'Thông báo',
      'Tin mới từ ban quản lý',
      Icons.notifications_active_outlined,
      AppColors.communitySoft,
      AppColors.community,
    ),
    _QuickActionData(
      'Khách lưu trú',
      'Khai báo khách ở tạm',
      Icons.person_pin_circle_outlined,
      AppColors.serviceSoft,
      AppColors.service,
    ),
    _QuickActionData(
      'An ninh',
      'Báo sự cố an ninh',
      Icons.health_and_safety_outlined,
      AppColors.securitySoft,
      AppColors.security,
    ),
    _QuickActionData(
      'Thuê / mua căn hộ',
      'Khám phá thuê và mua',
      Icons.apartment_rounded,
      AppColors.billingSoft,
      AppColors.billing,
    ),
  ];

  static const _ownerManagingItems = [
    _QuickActionData(
      'Căn hộ của tôi',
      'Thông tin tài sản',
      Icons.domain_outlined,
      AppColors.primaryLight,
      AppColors.primary,
    ),
    _QuickActionData(
      'Quản lý tài sản',
      'Bài đăng và hợp đồng',
      Icons.real_estate_agent_outlined,
      AppColors.billingSoft,
      AppColors.billing,
    ),
    _QuickActionData(
      'Hóa đơn',
      'Khoản phí giao cho bạn',
      Icons.receipt_long_outlined,
      AppColors.billingSoft,
      AppColors.billing,
    ),
    _QuickActionData(
      'Gửi phản ánh',
      'Sự cố liên quan tài sản',
      Icons.handyman_outlined,
      AppColors.maintenanceSoft,
      AppColors.maintenance,
    ),
    _QuickActionData(
      'Thông báo',
      'Tin mới từ ban quản lý',
      Icons.notifications_active_outlined,
      AppColors.communitySoft,
      AppColors.community,
    ),
    _QuickActionData(
      'An ninh',
      'Báo sự cố tại căn hộ',
      Icons.health_and_safety_outlined,
      AppColors.securitySoft,
      AppColors.security,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = mode == _ResidentMode.ownerManaging
            ? _ownerManagingItems
            : _items;
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 2;
        final aspectRatio = constraints.maxWidth < 380 ? 1.2 : 1.55;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _QuickActionCard(
              data: item,
              onTap: () => onAction(item.title),
            );
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data, required this.onTap});

  final _QuickActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [
                      Color.lerp(data.foreground, scheme.surface, .84)!,
                      scheme.surface,
                    ]
                  : [data.background, Colors.white],
            ),
            border: Border.all(color: data.foreground.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B173B76),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: dark
                          ? scheme.surfaceContainerHigh
                          : Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(data.icon, color: data.foreground, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: dark
                          ? scheme.surfaceContainerHigh
                          : Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: data.foreground,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResidentDashboardError extends StatelessWidget {
  const _ResidentDashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD65D28)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _OwnerPropertyNotice extends StatelessWidget {
  const _OwnerPropertyNotice({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [scheme.surface, scheme.surfaceContainerHigh]
              : [const Color(0xFFFFF8E6), const Color(0xFFF2F7FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD98A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionIcon(
            icon: Icons.admin_panel_settings_outlined,
            color: AppColors.warning,
            background: AppColors.warningContainer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Căn hộ đang có người thuê',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Bạn đang ở chế độ quản lý tài sản. Dịch vụ sinh hoạt, đặt tiện ích, khai báo khách và thành viên trong hộ thuộc tài khoản người thuê.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => onAction('Căn hộ của tôi'),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                  label: const Text('Xem quyền và trạng thái căn hộ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentActivitySummary extends StatelessWidget {
  const _ResidentActivitySummary({
    required this.controller,
    required this.user,
    required this.onAction,
  });

  final ResidentDashboardController controller;
  final User user;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (
        'Dịch vụ đang xử lý',
        controller.activeServiceCountFor(user),
        Icons.room_service_outlined,
        AppColors.service,
        AppColors.serviceSoft,
        'Dịch vụ',
      ),
      (
        'Lịch tiện ích sắp tới',
        controller.activeAmenityBookingsFor(user).length,
        Icons.event_available_outlined,
        AppColors.billing,
        AppColors.billingSoft,
        'Tiện ích',
      ),
      (
        'Đăng ký khách lưu trú',
        controller.activeTemporaryStaysFor(user).length,
        Icons.badge_outlined,
        AppColors.amenity,
        AppColors.amenitySoft,
        'Khách lưu trú',
      ),
      (
        'Sự cố đang theo dõi',
        controller.activeSecurityIncidentsFor(user).length,
        Icons.shield_outlined,
        AppColors.security,
        AppColors.securitySoft,
        'An ninh',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onAction(item.$6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: item.$4.withValues(alpha: 0.13)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A173B76),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: dark
                              ? item.$4.withValues(alpha: .18)
                              : item.$5,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.$3, color: item.$4, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.$2}',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              item.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: item.$4,
                        size: 20,
                      ),
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

class _InvoiceOverview extends StatelessWidget {
  const _InvoiceOverview({
    required this.invoices,
    required this.totalOutstanding,
    required this.onAction,
  });

  final List<Invoice> invoices;
  final double totalOutstanding;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final nextInvoice = invoices.firstOrNull;
    final hasDebt = invoices.isNotEmpty;
    final hasOverdue = invoices.any(
      (item) => item.effectiveStatus.name == 'overdue',
    );
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: hasDebt
                      ? AppColors.maintenanceSoft
                      : AppColors.serviceSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  hasDebt
                      ? Icons.account_balance_wallet_outlined
                      : Icons.verified_rounded,
                  color: hasDebt ? AppColors.maintenance : AppColors.service,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _SectionTitle(
                  title: hasDebt ? 'Công nợ hiện tại' : 'Tình trạng hóa đơn',
                  subtitle: nextInvoice == null
                      ? 'Không có khoản cần thanh toán'
                      : 'Hạn gần nhất ${_formatDate(nextInvoice.dueDate)}',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasDebt
                      ? const Color(0xFFFFF0E8)
                      : const Color(0xFFE5F8EF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  hasOverdue
                      ? 'Quá hạn'
                      : hasDebt
                      ? '${invoices.length} hóa đơn'
                      : 'Đã thanh toán',
                  style: TextStyle(
                    color: hasDebt
                        ? const Color(0xFFD65D28)
                        : const Color(0xFF238B5B),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _formatCurrency(totalOutstanding),
            style: const TextStyle(
              color: ResidentHomePage._navy,
              fontWeight: FontWeight.w800,
              fontSize: 29,
            ),
          ),
          const SizedBox(height: 16),
          if (nextInvoice == null)
            const Text(
              'Bạn hiện không có công nợ.',
              style: TextStyle(color: Color(0xFF707991), fontSize: 13),
            )
          else
            for (
              var index = 0;
              index < nextInvoice.items.take(3).length;
              index++
            ) ...[
              if (index > 0) const SizedBox(height: 9),
              _AmountRow(
                label: nextInvoice.items[index].name,
                amount: _formatCurrency(nextInvoice.items[index].amount),
              ),
            ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onAction('Chi tiết hóa đơn'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Xem chi tiết hóa đơn'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestOverview extends StatelessWidget {
  const _RequestOverview({required this.requests, required this.onAction});

  final List<MaintenanceRequest> requests;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SectionIcon(
                icon: Icons.handyman_outlined,
                color: AppColors.maintenance,
                background: AppColors.maintenanceSoft,
              ),
              SizedBox(width: 13),
              Expanded(
                child: _SectionTitle(
                  title: 'Yêu cầu gần đây',
                  subtitle: 'Cập nhật tiến độ xử lý của bạn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (requests.isEmpty)
            const Text(
              'Bạn chưa gửi yêu cầu sửa chữa nào.',
              style: TextStyle(color: Color(0xFF707991), fontSize: 13),
            )
          else
            for (var index = 0; index < requests.length; index++) ...[
              if (index > 0) const Divider(height: 28),
              _requestTile(requests[index]),
            ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onAction('Danh sách yêu cầu'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Xem tất cả yêu cầu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Announcements extends StatelessWidget {
  const _Announcements({
    required this.announcements,
    required this.controller,
    required this.user,
    required this.onAction,
  });

  final List<Announcement> announcements;
  final ResidentDashboardController controller;
  final User user;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionIcon(
              icon: Icons.campaign_outlined,
              color: AppColors.community,
              background: AppColors.communitySoft,
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: _SectionTitle(
                title: 'Thông báo mới',
                subtitle: 'Cập nhật từ ban quản lý',
              ),
            ),
            TextButton(
              onPressed: () => onAction('Tất cả thông báo'),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: announcements.isEmpty
                ? const [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Hiện chưa có thông báo mới.'),
                    ),
                  ]
                : [
                    for (
                      var index = 0;
                      index < announcements.length;
                      index++
                    ) ...[
                      if (index > 0) const Divider(height: 1, indent: 72),
                      _AnnouncementTile(
                        isNew: !controller.announcementController.isRead(
                          announcements[index].id,
                          user.id,
                        ),
                        icon: _announcementIcon(announcements[index].category),
                        color: _announcementColor(
                          announcements[index].category,
                        ),
                        background: _announcementBackground(
                          announcements[index].category,
                        ),
                        title: announcements[index].title,
                        description: announcements[index].content,
                        date: _relativeDate(announcements[index].publishedAt),
                        onTap: () {
                          controller.announcementController.markAsRead(
                            announcements[index].id,
                            user.id,
                          );
                          onAction('Tất cả thông báo');
                        },
                      ),
                    ],
                  ],
          ),
        ),
      ],
    );
  }
}

class _ResidentSidebar extends StatelessWidget {
  const _ResidentSidebar({
    required this.user,
    required this.apartmentCode,
    required this.mode,
    required this.onLogout,
    required this.onSelect,
  });

  final User user;
  final String? apartmentCode;
  final _ResidentMode mode;
  final VoidCallback onLogout;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const residentItems = [
      ('Trang chủ', Icons.grid_view_rounded),
      ('Hóa đơn', Icons.receipt_long_outlined),
      ('Yêu cầu', Icons.build_circle_outlined),
      ('Dịch vụ', Icons.room_service_outlined),
      ('Thuê / mua căn hộ', Icons.real_estate_agent_outlined),
      ('Tiện ích', Icons.event_available_outlined),
      ('Khách lưu trú', Icons.badge_outlined),
      ('An ninh', Icons.shield_outlined),
      ('Thông báo', Icons.notifications_none_rounded),
      ('Trung tâm thông báo', Icons.notifications_active_outlined),
      ('Hồ sơ cá nhân', Icons.person_outline_rounded),
    ];
    const ownerManagingItems = [
      ('Trang chủ', Icons.grid_view_rounded),
      ('Căn hộ của tôi', Icons.domain_outlined),
      ('Quản lý tài sản', Icons.real_estate_agent_outlined),
      ('Hóa đơn', Icons.receipt_long_outlined),
      ('Yêu cầu', Icons.build_circle_outlined),
      ('An ninh', Icons.shield_outlined),
      ('Thông báo', Icons.notifications_none_rounded),
      ('Trung tâm thông báo', Icons.notifications_active_outlined),
      ('Hồ sơ cá nhân', Icons.person_outline_rounded),
    ];
    final items = mode == _ResidentMode.ownerManaging
        ? ownerManagingItems
        : residentItems;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 268,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [scheme.surface, scheme.surfaceContainer]
              : [Colors.white, const Color(0xFFF8FAFF)],
        ),
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _LogoMark(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Homie',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _shortPortalTitle(mode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const SizedBox(height: 6),
                    _SidebarItem(
                      label: items[index].$1,
                      icon: items[index].$2,
                      selected: index == 0,
                      onTap: index == 0
                          ? () {}
                          : () => onSelect(items[index].$1),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF1FF), Color(0xFFEAF9F7)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE8F7)),
            ),
            child: Row(
              children: [
                UserAvatar(
                  user: user,
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: ResidentHomePage._primary,
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
                          color: ResidentHomePage._navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apartmentCode ?? user.apartmentCode ?? _roleLabel(mode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8B93A8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đăng xuất',
                  visualDensity: VisualDensity.compact,
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 19),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentBottomNavigation extends StatelessWidget {
  const _ResidentBottomNavigation({required this.mode, required this.onSelect});

  final _ResidentMode mode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final destinations = mode == _ResidentMode.ownerManaging
        ? const [
            (
              label: 'Trang chủ',
              action: 'Trang chủ',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
            ),
            (
              label: 'Căn hộ',
              action: 'Căn hộ của tôi',
              icon: Icons.apartment_outlined,
              selectedIcon: Icons.apartment_rounded,
            ),
            (
              label: 'Hóa đơn',
              action: 'Hóa đơn',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
            ),
            (
              label: 'Yêu cầu',
              action: 'Yêu cầu',
              icon: Icons.home_repair_service_outlined,
              selectedIcon: Icons.home_repair_service_rounded,
            ),
            (
              label: 'Tài khoản',
              action: 'Hồ sơ cá nhân',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ]
        : const [
            (
              label: 'Trang chủ',
              action: 'Trang chủ',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
            ),
            (
              label: 'Hóa đơn',
              action: 'Hóa đơn',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
            ),
            (
              label: 'Yêu cầu',
              action: 'Yêu cầu',
              icon: Icons.home_repair_service_outlined,
              selectedIcon: Icons.home_repair_service_rounded,
            ),
            (
              label: 'Dịch vụ',
              action: 'Dịch vụ',
              icon: Icons.room_service_outlined,
              selectedIcon: Icons.room_service_rounded,
            ),
            (
              label: 'Tài khoản',
              action: 'Hồ sơ cá nhân',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ];

    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A173B76),
                blurRadius: 24,
                offset: Offset(0, 9),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 70,
              elevation: 0,
              backgroundColor: Colors.transparent,
              indicatorColor: scheme.primaryContainer,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: states.contains(WidgetState.selected) ? 24 : 22,
                  color: states.contains(WidgetState.selected)
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: states.contains(WidgetState.selected)
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                if (index == 0) return;
                onSelect(destinations[index].action);
              },
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D6BFF), Color(0xFF00BDD3)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x302F6FED),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 23),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFE8F0FF), Color(0xFFE8F9F6)],
                  )
                : null,
            borderRadius: BorderRadius.circular(15),
            border: selected
                ? Border.all(color: const Color(0xFFD5E4FA))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? ResidentHomePage._primary
                        : const Color(0xFF77829A),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? ResidentHomePage._primary
                          : const Color(0xFF525C75),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173B76),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF707991), fontSize: 13),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: ResidentHomePage._navy,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.icon,
    required this.title,
    required this.code,
    required this.status,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String code;
  final String status;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ResidentHomePage._navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: const TextStyle(color: Color(0xFF8B93A8), fontSize: 11),
              ),
              const SizedBox(height: 7),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.isNew,
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.description,
    required this.date,
    this.onTap,
  });

  final bool isNew;
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String description;
  final String date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ResidentHomePage._navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isNew)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: ResidentHomePage._primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF707991),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFFA0A7B8),
                      fontSize: 10,
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

class _ActiveApartmentCard extends StatelessWidget {
  const _ActiveApartmentCard({required this.controller, required this.user});

  final ResidentDashboardController controller;
  final User user;

  @override
  Widget build(BuildContext context) {
    final apartmentController = controller.apartmentController;
    final membership = apartmentController.activeMembershipForResident(user.id);
    if (membership == null) return const SizedBox.shrink();
    final apartment = apartmentController.apartmentById(membership.apartmentId);
    final canSwitch =
        apartmentController.activeMembershipsForResident(user.id).length > 1;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: canSwitch
            ? () => showResidentApartmentPicker(
                context: context,
                controller: apartmentController,
                residentId: user.id,
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.apartment_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Căn đang sử dụng',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      '${apartment?.code ?? 'Căn hộ'} · ${apartment?.buildingName ?? 'Tòa nhà'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      membership.type.displayName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              if (canSwitch) const Icon(Icons.swap_horiz_rounded, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ResidentMode { unverified, tenant, ownerLiving, ownerManaging }

_ResidentMode _residentModeFor(
  ResidentDashboardController controller,
  User user,
) {
  final membership = controller.apartmentController.activeMembershipForResident(
    user.id,
  );
  if (membership == null) return _ResidentMode.unverified;
  if (membership.type == MembershipType.tenant) return _ResidentMode.tenant;
  final hasTenant = controller.apartmentController
      .membershipsForApartment(membership.apartmentId, includeEnded: false)
      .any((item) => item.type == MembershipType.tenant);
  return hasTenant ? _ResidentMode.ownerManaging : _ResidentMode.ownerLiving;
}

String _portalTitle(_ResidentMode mode) => switch (mode) {
  _ResidentMode.ownerManaging ||
  _ResidentMode.ownerLiving => 'KHÔNG GIAN CHỦ SỞ HỮU',
  _ResidentMode.tenant => 'KHÔNG GIAN NGƯỜI THUÊ',
  _ResidentMode.unverified => 'KHÔNG GIAN KHÁCH HÀNG',
};

String _shortPortalTitle(_ResidentMode mode) => switch (mode) {
  _ResidentMode.ownerManaging || _ResidentMode.ownerLiving => 'Chủ sở hữu',
  _ResidentMode.tenant => 'Người thuê',
  _ResidentMode.unverified => 'Tài khoản chưa xác minh',
};

String _roleLabel(_ResidentMode mode) => switch (mode) {
  _ResidentMode.ownerManaging || _ResidentMode.ownerLiving => 'Chủ sở hữu',
  _ResidentMode.tenant => 'Người thuê',
  _ResidentMode.unverified => 'Khách hàng',
};

String _portalSubtitle(_ResidentMode mode) => switch (mode) {
  _ResidentMode.ownerManaging =>
    'Theo dõi tài sản, bài đăng và nghĩa vụ được giao cho bạn',
  _ResidentMode.ownerLiving =>
    'Quản lý căn hộ và sử dụng các dịch vụ dành cho cư dân',
  _ResidentMode.tenant =>
    'Dịch vụ sinh hoạt và quyền lợi trong thời gian thuê căn hộ',
  _ResidentMode.unverified =>
    'Xác minh căn hộ để sử dụng đầy đủ chức năng cư dân',
};

String _modeBadge(_ResidentMode mode) => switch (mode) {
  _ResidentMode.ownerManaging => 'CHỦ SỞ HỮU · ĐANG CHO THUÊ',
  _ResidentMode.ownerLiving => 'CHỦ SỞ HỮU · ĐANG SINH SỐNG',
  _ResidentMode.tenant => 'NGƯỜI THUÊ ĐÃ XÁC MINH',
  _ResidentMode.unverified => 'CHƯA XÁC MINH CĂN HỘ',
};

String _welcomeDescription(_ResidentMode mode) => switch (mode) {
  _ResidentMode.ownerManaging => 'Theo dõi căn hộ và nghĩa vụ của chủ sở hữu mà không truy cập dữ liệu sinh hoạt riêng của người thuê.',
  _ResidentMode.ownerLiving =>
    'Bạn đang trực tiếp sinh sống và có thể sử dụng đầy đủ dịch vụ cư dân.',
  _ResidentMode.tenant =>
    'Đặt dịch vụ, tiện ích và quản lý sinh hoạt của bạn trong thời gian thuê.',
  _ResidentMode.unverified =>
    'Khám phá căn hộ phù hợp và gửi yêu cầu xác minh khi cần.',
};

class _QuickActionData {
  const _QuickActionData(
    this.title,
    this.subtitle,
    this.icon,
    this.background,
    this.foreground,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
}

Widget _requestTile(MaintenanceRequest request) {
  final completed = !request.isOpen;
  return _RequestTile(
    icon: switch (request.category) {
      MaintenanceCategory.electrical => Icons.electrical_services_outlined,
      MaintenanceCategory.plumbing => Icons.water_drop_outlined,
      MaintenanceCategory.elevator => Icons.elevator_outlined,
      MaintenanceCategory.commonArea => Icons.apartment_outlined,
      MaintenanceCategory.security => Icons.shield_outlined,
      MaintenanceCategory.other => Icons.build_outlined,
    },
    title: request.title,
    code: '${request.code} · ${_formatDate(request.updatedAt)}',
    status: request.status.label,
    color: completed ? const Color(0xFF238B5B) : const Color(0xFF3178C6),
    background: completed ? const Color(0xFFE5F8EF) : const Color(0xFFE6F1FF),
  );
}

IconData _announcementIcon(AnnouncementCategory category) => switch (category) {
  AnnouncementCategory.general => Icons.campaign_outlined,
  AnnouncementCategory.maintenance => Icons.build_outlined,
  AnnouncementCategory.billing => Icons.receipt_long_outlined,
  AnnouncementCategory.event => Icons.celebration_outlined,
  AnnouncementCategory.emergency => Icons.warning_amber_rounded,
};

Color _announcementColor(AnnouncementCategory category) => switch (category) {
  AnnouncementCategory.general => AppColors.billing,
  AnnouncementCategory.maintenance => AppColors.maintenance,
  AnnouncementCategory.billing => AppColors.service,
  AnnouncementCategory.event => AppColors.amenity,
  AnnouncementCategory.emergency => AppColors.security,
};

Color _announcementBackground(AnnouncementCategory category) =>
    switch (category) {
      AnnouncementCategory.general => AppColors.billingSoft,
      AnnouncementCategory.maintenance => AppColors.maintenanceSoft,
      AnnouncementCategory.billing => AppColors.serviceSoft,
      AnnouncementCategory.event => AppColors.amenitySoft,
      AnnouncementCategory.emergency => AppColors.securitySoft,
    };

String _formatCurrency(double value) {
  final digits = value.round().toString();
  return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} ₫';
}

String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Chào buổi sáng';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

String _firstName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.isEmpty || parts.first.isEmpty ? 'bạn' : parts.last;
}

String _formatDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}

String _relativeDate(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final difference = today.difference(date).inDays;
  if (difference == 0) return 'Hôm nay';
  if (difference == 1) return 'Hôm qua';
  return _formatDate(value);
}
