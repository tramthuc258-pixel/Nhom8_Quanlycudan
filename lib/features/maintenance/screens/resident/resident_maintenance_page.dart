import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';

import '../../controllers/maintenance_controller.dart';
import '../../widgets/maintenance_request_dialog.dart';
import '../../widgets/maintenance_widgets.dart';

import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/core/storage/file_upload_service.dart';

import 'maintenance_detail_page.dart';

class ResidentMaintenancePage extends StatefulWidget {
  const ResidentMaintenancePage({
    required this.controller,
    required this.apartmentMembershipController,
    required this.user,
    this.fileUploadService,
    super.key,
  });

  final MaintenanceController controller;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  final FileUploadService? fileUploadService;

  @override
  State<ResidentMaintenancePage> createState() =>
      _ResidentMaintenancePageState();
}

class _ResidentMaintenancePageState extends State<ResidentMaintenancePage> {
  bool _waiting = true;
  _ResidentRequestFilter _filter = _ResidentRequestFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait<void>([
      widget.controller.load(),
      widget.apartmentMembershipController.load(),
    ]);
    if (mounted) setState(() => _waiting = false);
  }

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Yêu cầu sửa chữa',
      subtitle: 'Gửi và theo dõi yêu cầu sửa chữa',
      icon: Icons.build_circle_outlined,
      accentColor: AppColors.maintenance,
      accentSoftColor: AppColors.maintenanceSoft,
      actions: [
        IconButton(
          tooltip: 'Tạo yêu cầu',
          onPressed: _create,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
        IconButton(
          tooltip: 'Tải lại dữ liệu',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
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
    if (_waiting ||
        (widget.controller.isLoading && widget.controller.requests.isEmpty)) {
      return const LoadingView(message: 'Đang tải yêu cầu sửa chữa…');
    }
    final membership = widget.apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    final apartment = membership == null
        ? null
        : widget.apartmentMembershipController.apartmentById(
            membership.apartmentId,
          );
    if (apartment == null) {
      return EmptyView(
        icon: Icons.home_work_outlined,
        title: 'Chưa có căn hộ đang cư trú',
        message: 'Bạn cần được gắn với một căn hộ trước khi gửi yêu cầu.',
        actionLabel: 'Tải lại',
        onAction: _load,
      );
    }
    if (widget.controller.errorMessage != null &&
        widget.controller.requests.isEmpty) {
      return ErrorView(
        title: 'Không thể tải yêu cầu',
        message: widget.controller.errorMessage,
        onRetry: _load,
      );
    }

    final all = widget.controller
        .requestsForResident(widget.user.id)
        .where((request) => request.apartmentId == apartment.id)
        .toList(growable: false);
    final filtered = all
        .where((request) {
          return switch (_filter) {
            _ResidentRequestFilter.all => true,
            _ResidentRequestFilter.open => request.isOpen,
            _ResidentRequestFilter.waiting =>
              request.status == MaintenanceStatus.waitingResident,
            _ResidentRequestFilter.completed =>
              request.status == MaintenanceStatus.completed,
          };
        })
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(apartment, all)),
          SliverToBoxAdapter(child: _filters()),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chưa cập nhật được danh sách. Vui lòng thử lại.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.home_repair_service_outlined,
                title: all.isEmpty
                    ? 'Chưa có yêu cầu nào'
                    : 'Không có yêu cầu phù hợp',
                message: all.isEmpty
                    ? 'Tạo yêu cầu khi căn hộ hoặc khu vực chung cần được kiểm tra.'
                    : 'Hãy chọn một bộ lọc khác để xem yêu cầu.',
                actionLabel: all.isEmpty ? 'Tạo yêu cầu' : 'Xem tất cả',
                onAction: all.isEmpty
                    ? _create
                    : () =>
                          setState(() => _filter = _ResidentRequestFilter.all),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent >= 820 ? 2 : 1;
                  return SliverGrid.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 292,
                    ),
                    itemBuilder: (context, index) {
                      final request = filtered[index];
                      return MaintenanceRequestCard(
                        request: request,
                        apartmentCode: apartment.code,
                        onTap: () => _openDetail(request.id),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(Apartment apartment, List<MaintenanceRequest> requests) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final open = requests.where((item) => item.isOpen).length;
    final completed = requests
        .where((item) => item.status == MaintenanceStatus.completed)
        .length;
    final waiting = requests
        .where((item) => item.status == MaintenanceStatus.waitingResident)
        .length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? <Color>[scheme.surface, scheme.surfaceContainerHigh]
                    : <Color>[Colors.white, AppColors.maintenanceSoft],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.maintenance.withValues(alpha: .15),
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0D173B76),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.maintenance,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.home_repair_service_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Hỗ trợ căn ${apartment.code}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Theo dõi toàn bộ tiến độ xử lý trong một nơi.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Stat(
                      label: 'Tổng yêu cầu',
                      value: requests.length,
                      color: AppColors.primary,
                    ),
                    _Stat(
                      label: 'Đang mở',
                      value: open,
                      color: AppColors.maintenance,
                    ),
                    _Stat(
                      label: 'Chờ bạn',
                      value: waiting,
                      color: AppColors.warning,
                    ),
                    _Stat(
                      label: 'Hoàn thành',
                      value: completed,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_ResidentRequestFilter>(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? scheme.onPrimary
                        : scheme.onSurface,
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? scheme.primary
                        : scheme.surface,
                  ),
                ),
                segments: [
                  for (final item in _ResidentRequestFilter.values)
                    ButtonSegment(value: item, label: Text(item.label)),
                ],
                selected: {_filter},
                onSelectionChanged: (value) =>
                    setState(() => _filter = value.first),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    final membership = widget.apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    if (membership == null) return;
    final draft = await showMaintenanceRequestDialog(
      context,
      fileUploadService: widget.fileUploadService,
    );
    if (draft == null || !mounted) return;
    final success = await widget.controller.createRequest(
      apartmentId: membership.apartmentId,
      residentId: widget.user.id,
      residentName: widget.user.fullName,
      title: draft.title,
      description: draft.description,
      location: draft.location,
      category: draft.category,
      priority: draft.priority,
      imageUrls: draft.imageUrls,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã gửi yêu cầu đến ban quản lý.'
              : widget.controller.errorMessage ?? 'Không thể tạo yêu cầu.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDetail(String id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MaintenanceDetailPage(
          controller: widget.controller,
          apartmentMembershipController: widget.apartmentMembershipController,
          user: widget.user,
          requestId: id,
        ),
      ),
    );
  }
}

enum _ResidentRequestFilter { all, open, waiting, completed }

extension on _ResidentRequestFilter {
  String get label => switch (this) {
    _ResidentRequestFilter.all => 'Tất cả',
    _ResidentRequestFilter.open => 'Đang xử lý',
    _ResidentRequestFilter.waiting => 'Chờ cư dân',
    _ResidentRequestFilter.completed => 'Hoàn thành',
  };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark
            ? Color.lerp(color, scheme.surface, .86)
            : Color.lerp(color, Colors.white, .91),
        border: Border.all(color: color.withValues(alpha: .14)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
