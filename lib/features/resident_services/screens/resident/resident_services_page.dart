import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';

import '../../controllers/service_controller.dart';
import '../../widgets/resident/resident_service_widgets.dart';
import '../../widgets/resident/service_booking_dialog.dart';
import 'service_booking_detail_page.dart';

class ResidentServicesPage extends StatefulWidget {
  const ResidentServicesPage({
    required this.controller,
    required this.apartmentMembershipController,
    required this.user,
    this.invoiceController,
    super.key,
  });

  final ServiceController controller;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  final InvoiceController? invoiceController;

  @override
  State<ResidentServicesPage> createState() => _ResidentServicesPageState();
}

class _ResidentServicesPageState extends State<ResidentServicesPage> {
  bool _waitingForFirstLoad = true;
  _ServicesSection _section = _ServicesSection.catalog;
  ServiceCategory? _category;
  ServiceBookingStatus? _bookingStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant ResidentServicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.apartmentMembershipController !=
            widget.apartmentMembershipController ||
        oldWidget.user.id != widget.user.id) {
      _waitingForFirstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    await Future.wait<void>([
      widget.controller.load(),
      widget.apartmentMembershipController.load(),
    ]);
    if (mounted) setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Dịch vụ cư dân',
      subtitle: 'Đặt dịch vụ và theo dõi lịch thực hiện',
      icon: Icons.room_service_outlined,
      accentColor: AppColors.service,
      accentSoftColor: AppColors.serviceSoft,
      actions: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: widget.controller.isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.controller,
          widget.apartmentMembershipController,
        ]),
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_waitingForFirstLoad ||
        (widget.controller.isLoading && widget.controller.services.isEmpty)) {
      return const LoadingView(message: 'Đang tải dịch vụ cư dân…');
    }

    final membership = widget.apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    if (membership == null) {
      return EmptyView(
        icon: Icons.home_work_outlined,
        title: 'Chưa có căn hộ đang cư trú',
        message: 'Bạn cần được gắn với một căn hộ để đăng ký dịch vụ.',
        actionLabel: 'Tải lại',
        onAction: _load,
      );
    }
    final apartment = widget.apartmentMembershipController.apartmentById(
      membership.apartmentId,
    );
    if (apartment == null) {
      return ErrorView(
        title: 'Không tìm thấy căn hộ',
        message: 'Thông tin cư trú chưa được gắn với căn hộ hợp lệ.',
        onRetry: _load,
      );
    }
    if (widget.controller.errorMessage != null &&
        widget.controller.services.isEmpty) {
      return ErrorView(
        title: 'Không thể tải dịch vụ',
        message: widget.controller.errorMessage,
        onRetry: _load,
      );
    }

    final bookings =
        widget.controller
            .bookingsForResident(widget.user.id)
            .where((item) => item.apartmentId == apartment.id)
            .toList()
          ..sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
    final activeBookingCount = bookings
        .where((item) => item.status.isActive)
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ServicesOverview(
              apartment: apartment,
              serviceCount: widget.controller.activeServices.length,
              activeBookingCount: activeBookingCount,
              completedCount: bookings
                  .where(
                    (item) => item.status == ServiceBookingStatus.completed,
                  )
                  .length,
            ),
          ),
          SliverToBoxAdapter(child: _sectionSelector(bookings.length)),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      widget.controller.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
          if (_section == _ServicesSection.catalog)
            ..._catalogSlivers(apartment.id)
          else
            ..._bookingSlivers(bookings),
        ],
      ),
    );
  }

  Widget _sectionSelector(int bookingCount) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_ServicesSection>(
              segments: [
                const ButtonSegment(
                  value: _ServicesSection.catalog,
                  icon: Icon(Icons.grid_view_rounded),
                  label: Text('Danh mục dịch vụ'),
                ),
                ButtonSegment(
                  value: _ServicesSection.bookings,
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text('Đăng ký của tôi ($bookingCount)'),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (value) =>
                  setState(() => _section = value.first),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _catalogSlivers(String apartmentId) {
    final availableCategories = widget.controller.activeServices
        .map((service) => service.category)
        .toSet();
    final selectedCategory = availableCategories.contains(_category)
        ? _category
        : null;
    final services = widget.controller.activeServices
        .where(
          (service) =>
              selectedCategory == null || service.category == selectedCategory,
        )
        .toList(growable: false);
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: selectedCategory == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    for (final category in ServiceCategory.values)
                      if (availableCategories.contains(category)) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: Icon(serviceCategoryIcon(category), size: 17),
                          label: Text(category.label),
                          selected: selectedCategory == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      if (services.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.room_service_outlined,
            title: 'Chưa có dịch vụ phù hợp',
            message: 'Hãy chọn nhóm dịch vụ khác hoặc tải lại dữ liệu.',
            actionLabel: _category == null ? 'Tải lại' : 'Xem tất cả',
            onAction: _category == null
                ? _load
                : () => setState(() => _category = null),
          ),
        )
      else
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final padding = width > 1212 ? (width - 1180) / 2 : 16.0;
            final columns = width >= 1040
                ? 3
                : width >= 700
                ? 2
                : 1;
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 36),
              sliver: columns == 1
                  ? SliverList.builder(
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ResidentServiceCard(
                            service: service,
                            compact: true,
                            onBook: () => _book(service, apartmentId),
                          ),
                        );
                      },
                    )
                  : SliverGrid.builder(
                      itemCount: services.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 455,
                      ),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ResidentServiceCard(
                          service: service,
                          onBook: () => _book(service, apartmentId),
                        );
                      },
                    ),
            );
          },
        ),
    ];
  }

  List<Widget> _bookingSlivers(List<ServiceBooking> allBookings) {
    final bookings = allBookings
        .where(
          (booking) =>
              _bookingStatus == null || booking.status == _bookingStatus,
        )
        .toList(growable: false);
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _bookingStatus == null,
                      onSelected: (_) => setState(() => _bookingStatus = null),
                    ),
                    for (final status in ServiceBookingStatus.values) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(status.label),
                        selected: _bookingStatus == status,
                        onSelected: (_) =>
                            setState(() => _bookingStatus = status),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      if (bookings.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.assignment_outlined,
            title: allBookings.isEmpty
                ? 'Bạn chưa đăng ký dịch vụ'
                : 'Không có đăng ký phù hợp',
            message: allBookings.isEmpty
                ? 'Chọn một dịch vụ trong danh mục để bắt đầu.'
                : 'Hãy chọn trạng thái khác để xem đăng ký.',
            actionLabel: allBookings.isEmpty ? 'Xem danh mục' : 'Xem tất cả',
            onAction: () => setState(() {
              if (allBookings.isEmpty) {
                _section = _ServicesSection.catalog;
              } else {
                _bookingStatus = null;
              }
            }),
          ),
        )
      else
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final padding = width > 1212 ? (width - 1180) / 2 : 16.0;
            final columns = width >= 820 ? 2 : 1;
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 36),
              sliver: SliverGrid.builder(
                itemCount: bookings.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 230,
                ),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return ResidentServiceBookingCard(
                    booking: booking,
                    onTap: () => _openBooking(booking.id),
                  );
                },
              ),
            );
          },
        ),
    ];
  }

  Future<void> _book(ResidentService service, String apartmentId) async {
    final draft = await showServiceBookingDialog(context, service: service);
    if (draft == null || !mounted) return;
    final success = await widget.controller.createBooking(
      serviceId: service.id,
      apartmentId: apartmentId,
      residentId: widget.user.id,
      residentName: widget.user.fullName,
      quantity: draft.quantity,
      scheduledAt: draft.scheduledAt,
      note: draft.note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã gửi đăng ký dịch vụ đến ban quản lý.'
              : widget.controller.errorMessage ?? 'Không thể đăng ký dịch vụ.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) {
      setState(() {
        _section = _ServicesSection.bookings;
        _bookingStatus = null;
      });
    }
  }

  Future<void> _openBooking(String bookingId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ServiceBookingDetailPage(
          controller: widget.controller,
          apartmentMembershipController: widget.apartmentMembershipController,
          user: widget.user,
          invoiceController: widget.invoiceController,
          bookingId: bookingId,
        ),
      ),
    );
  }
}

enum _ServicesSection { catalog, bookings }

class _ServicesOverview extends StatelessWidget {
  const _ServicesOverview({
    required this.apartment,
    required this.serviceCount,
    required this.activeBookingCount,
    required this.completedCount,
  });

  final Apartment apartment;
  final int serviceCount;
  final int activeBookingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiện nghi cho căn ${apartment.code}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Chọn dịch vụ, đặt thời gian phù hợp và theo dõi tiến độ ngay trong ứng dụng.',
                      style: TextStyle(color: Colors.white70, height: 1.45),
                    ),
                  ],
                );
                final metrics = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _OverviewMetric(
                      icon: Icons.room_service_rounded,
                      value: '$serviceCount',
                      label: 'Dịch vụ',
                    ),
                    _OverviewMetric(
                      icon: Icons.pending_actions_rounded,
                      value: '$activeBookingCount',
                      label: 'Đang xử lý',
                    ),
                    _OverviewMetric(
                      icon: Icons.task_alt_rounded,
                      value: '$completedCount',
                      label: 'Hoàn thành',
                    ),
                  ],
                );
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [intro, const SizedBox(height: 20), metrics],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 24),
                    metrics,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
