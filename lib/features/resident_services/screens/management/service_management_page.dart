import 'package:flutter/material.dart';
import 'package:homie/core/models/work_assignee.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/enums/user_role.dart';

import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';
import 'package:homie/features/resident_services/models/service_booking.dart';
import 'package:homie/features/resident_services/controllers/service_controller.dart';
import 'package:homie/features/resident_services/widgets/management/service_management_widgets.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';

class ServiceManagementPage extends StatefulWidget {
  const ServiceManagementPage({
    required this.serviceController,
    required this.apartmentMembershipController,
    required this.operator,
    this.canManageCatalog = true,
    super.key,
  });

  final ServiceController serviceController;
  final ApartmentMembershipController apartmentMembershipController;
  final User operator;
  final bool canManageCatalog;

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  final _searchController = TextEditingController();
  final _busyBookingIds = <String>{};
  final _busyServiceIds = <String>{};

  _ManagementSection _section = _ManagementSection.bookings;
  ServiceBookingStatus? _statusFilter;
  ServiceCategory? _categoryFilter;

  Listenable get _controllers => Listenable.merge([
    widget.serviceController,
    widget.apartmentMembershipController,
  ]);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadInitialData() async {
    final tasks = <Future<void>>[];
    if (widget.serviceController.services.isEmpty &&
        widget.serviceController.bookings.isEmpty &&
        !widget.serviceController.isLoading) {
      tasks.add(widget.serviceController.load());
    }
    if (widget.apartmentMembershipController.apartments.isEmpty &&
        !widget.apartmentMembershipController.isLoading) {
      tasks.add(widget.apartmentMembershipController.load());
    }
    if (tasks.isNotEmpty) await Future.wait(tasks);
  }

  Future<void> _reload() async {
    await Future.wait([
      widget.serviceController.load(),
      widget.apartmentMembershipController.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch vụ cư dân'),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _isBusy ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _controllers,
          builder: (context, _) {
            if (_isInitialLoading) {
              return const LoadingView(message: 'Đang tải dữ liệu dịch vụ…');
            }
            if (widget.serviceController.errorMessage != null &&
                widget.serviceController.services.isEmpty &&
                widget.serviceController.bookings.isEmpty) {
              return ErrorView(
                message: widget.serviceController.errorMessage,
                onRetry: _reload,
              );
            }
            return _buildContent();
          },
        ),
      ),
    );
  }

  bool get _isBusy =>
      widget.serviceController.isLoading ||
      widget.apartmentMembershipController.isLoading;

  bool get _isInitialLoading =>
      (widget.serviceController.isLoading &&
          widget.serviceController.services.isEmpty &&
          widget.serviceController.bookings.isEmpty) ||
      (widget.apartmentMembershipController.isLoading &&
          widget.apartmentMembershipController.apartments.isEmpty);

  Widget _buildContent() {
    final bookings = _filteredBookings();
    final services = _filteredServices();
    return RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _PageHeader(
              section: _section,
              onSectionChanged: _changeSection,
            ),
          ),
          SliverToBoxAdapter(
            child: ServiceManagementOverview(
              bookings: widget.serviceController.bookings,
              services: widget.serviceController.services,
            ),
          ),
          if (widget.serviceController.errorMessage != null)
            SliverToBoxAdapter(
              child: _InlineMessage(
                message: widget.serviceController.errorMessage!,
              ),
            ),
          if (widget.apartmentMembershipController.errorMessage != null)
            SliverToBoxAdapter(
              child: _InlineMessage(
                message: widget.apartmentMembershipController.errorMessage!,
              ),
            ),
          SliverToBoxAdapter(
            child: _section == _ManagementSection.bookings
                ? _buildBookingFilters()
                : _buildCatalogFilters(),
          ),
          if (_section == _ManagementSection.bookings)
            ..._bookingSlivers(bookings)
          else
            ..._catalogSlivers(services),
        ],
      ),
    );
  }

  List<Widget> _bookingSlivers(List<ServiceBooking> bookings) {
    if (bookings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.room_service_outlined,
            title: widget.serviceController.bookings.isEmpty
                ? 'Chưa có đơn đăng ký'
                : 'Không tìm thấy đơn phù hợp',
            message: widget.serviceController.bookings.isEmpty
                ? 'Đơn đăng ký từ cư dân sẽ xuất hiện tại đây.'
                : 'Hãy đổi từ khóa hoặc trạng thái để xem kết quả khác.',
            actionLabel: widget.serviceController.bookings.isEmpty
                ? 'Tải lại'
                : 'Xóa bộ lọc',
            onAction: widget.serviceController.bookings.isEmpty
                ? _reload
                : _clearFilters,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.crossAxisExtent >= 1120
                ? 3
                : constraints.crossAxisExtent >= 720
                ? 2
                : 1;
            Widget bookingCard(int index, {bool compact = false}) {
              final booking = bookings[index];
              return ServiceBookingCard(
                booking: booking,
                apartment: _apartmentFor(booking),
                busy: _busyBookingIds.contains(booking.id),
                compact: compact,
                onView: () => _showBookingDetail(booking),
              );
            }

            return columns == 1
                ? SliverList.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: bookingCard(index, compact: true),
                    ),
                  )
                : SliverGrid.builder(
                    itemCount: bookings.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 350,
                    ),
                    itemBuilder: (context, index) => bookingCard(index),
                  );
          },
        ),
      ),
    ];
  }

  List<Widget> _catalogSlivers(List<ResidentService> services) {
    if (services.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.storefront_outlined,
            title: widget.serviceController.services.isEmpty
                ? 'Chưa có dịch vụ'
                : 'Không tìm thấy dịch vụ',
            message: widget.serviceController.services.isEmpty
                ? 'Danh mục dịch vụ chưa có dữ liệu.'
                : 'Hãy đổi từ khóa hoặc nhóm dịch vụ.',
            actionLabel: widget.serviceController.services.isEmpty
                ? 'Tải lại'
                : 'Xóa bộ lọc',
            onAction: widget.serviceController.services.isEmpty
                ? _reload
                : _clearFilters,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.crossAxisExtent >= 1120
                ? 3
                : constraints.crossAxisExtent >= 720
                ? 2
                : 1;
            Widget catalogCard(int index, {bool compact = false}) {
              final service = services[index];
              return ServiceCatalogCard(
                service: service,
                busy: _busyServiceIds.contains(service.id),
                compact: compact,
                onToggle: widget.canManageCatalog
                    ? (_) => _toggleService(service)
                    : null,
              );
            }

            return columns == 1
                ? SliverList.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: catalogCard(index, compact: true),
                    ),
                  )
                : SliverGrid.builder(
                    itemCount: services.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 320,
                    ),
                    itemBuilder: (context, index) => catalogCard(index),
                  );
          },
        ),
      ),
    ];
  }

  Widget _buildBookingFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = _SearchField(
                controller: _searchController,
                hint: 'Mã đơn, dịch vụ, căn hộ, cư dân hoặc người phụ trách',
              );
              final status = DropdownButtonFormField<ServiceBookingStatus?>(
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem<ServiceBookingStatus?>(
                    value: null,
                    child: Text('Tất cả trạng thái'),
                  ),
                  for (final item in ServiceBookingStatus.values)
                    DropdownMenuItem<ServiceBookingStatus?>(
                      value: item,
                      child: Text(serviceBookingStatusLabel(item)),
                    ),
                ],
                onChanged: (value) => setState(() => _statusFilter = value),
              );
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [search, const SizedBox(height: 12), status],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: status),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = _SearchField(
                controller: _searchController,
                hint: 'Tên hoặc mô tả dịch vụ',
              );
              final category = DropdownButtonFormField<ServiceCategory?>(
                initialValue: _categoryFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Nhóm dịch vụ',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<ServiceCategory?>(
                    value: null,
                    child: Text('Tất cả nhóm'),
                  ),
                  for (final item in ServiceCategory.values)
                    DropdownMenuItem<ServiceCategory?>(
                      value: item,
                      child: Text(serviceCategoryLabel(item)),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryFilter = value),
              );
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [search, const SizedBox(height: 12), category],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: category),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<ServiceBooking> _filteredBookings() {
    final query = _searchController.text.trim().toLowerCase();
    final result = widget.serviceController.bookings.where((booking) {
      if (_statusFilter != null && booking.status != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final apartment = _apartmentFor(booking);
      return [
        booking.code,
        booking.serviceName,
        booking.residentName,
        apartment?.code ?? '',
        apartment?.buildingName ?? '',
        booking.assignedTo ?? '',
        serviceBookingStatusLabel(booking.status),
      ].join(' ').toLowerCase().contains(query);
    }).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  List<ResidentService> _filteredServices() {
    final query = _searchController.text.trim().toLowerCase();
    final result = widget.serviceController.services.where((service) {
      if (_categoryFilter != null && service.category != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        service.name,
        service.description,
        service.unitLabel,
        serviceCategoryLabel(service.category),
      ].join(' ').toLowerCase().contains(query);
    }).toList();
    result.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  Apartment? _apartmentFor(ServiceBooking booking) =>
      widget.apartmentMembershipController.apartmentById(booking.apartmentId);

  void _changeSection(_ManagementSection value) {
    _searchController.clear();
    setState(() {
      _section = value;
      _statusFilter = null;
      _categoryFilter = null;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = null;
      _categoryFilter = null;
    });
  }

  Future<void> _showBookingDetail(ServiceBooking booking) {
    return showServiceBookingDetailDialog(
      context,
      booking: booking,
      apartment: _apartmentFor(booking),
      onAssign: _canAssign(booking) ? () => _assignBooking(booking) : null,
      onUpdateStatus: _nextStatuses(booking).isNotEmpty
          ? () => _updateBookingStatus(booking)
          : null,
    );
  }

  Future<void> _assignBooking(ServiceBooking booking) async {
    List<WorkAssignee> assignees;
    try {
      assignees = await widget.serviceController.getAssignees(booking.id);
    } catch (error) {
      if (!mounted) return;
      _showResult(false, error.toString().replaceFirst('Bad state: ', ''));
      return;
    }
    if (!mounted) return;
    if (assignees.isEmpty) {
      _showResult(
        false,
        'Tòa nhà chưa có nhân viên phù hợp đang hoạt động. Hãy phân công nhân viên vào tòa trước.',
      );
      return;
    }
    WorkAssignee? selected;
    final assignee = await showDialog<WorkAssignee>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Phân công thực hiện'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DropdownButtonFormField<WorkAssignee>(
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nhân viên thuộc tòa nhà',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              hint: const Text('Chọn người chịu trách nhiệm'),
              items: [
                for (final item in assignees)
                  DropdownMenuItem(
                    value: item,
                    child: Text(
                      '${item.fullName} · ${item.roleLabel}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setDialogState(() => selected = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(context, selected),
              icon: const Icon(Icons.assignment_ind_rounded),
              label: const Text('Giao việc'),
            ),
          ],
        ),
      ),
    );
    if (assignee == null || !mounted) return;
    await _runBookingAction(
      booking,
      action: () => widget.serviceController.assignBooking(
        bookingId: booking.id,
        assigneeId: assignee.id,
        assigneeName: assignee.fullName,
      ),
      successMessage: 'Đã giao đơn ${booking.code} cho ${assignee.fullName}.',
      fallbackError: 'Không thể phân công đơn dịch vụ.',
    );
  }

  Future<void> _updateBookingStatus(ServiceBooking booking) async {
    final statuses = _nextStatuses(booking);
    if (statuses.isEmpty) return;
    var selected = statuses.first;
    final noteController = TextEditingController();
    final result = await showDialog<(ServiceBookingStatus, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật trạng thái'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ServiceBookingStatus>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái mới',
                  ),
                  items: [
                    for (final item in statuses)
                      DropdownMenuItem(
                        value: item,
                        child: Text(serviceBookingStatusLabel(item)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selected = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú xử lý',
                    hintText: 'Thông tin cư dân cần biết…',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                selected,
                noteController.text.trim(),
              )),
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result == null || !mounted) return;
    await _runBookingAction(
      booking,
      action: () => widget.serviceController.updateBookingStatus(
        bookingId: booking.id,
        status: result.$1,
        note: result.$2,
      ),
      successMessage: 'Đã cập nhật trạng thái đơn ${booking.code}.',
      fallbackError: 'Không thể cập nhật trạng thái đơn dịch vụ.',
    );
  }

  bool _canAssign(ServiceBooking booking) {
    if (booking.status.isTerminal) return false;
    return switch (widget.operator.role) {
      UserRole.admin || UserRole.manager || UserRole.receptionist => true,
      _ => false,
    };
  }

  List<ServiceBookingStatus> _nextStatuses(ServiceBooking booking) {
    final status = booking.status;
    if (widget.operator.role == UserRole.receptionist) {
      return status == ServiceBookingStatus.pending
          ? const [
              ServiceBookingStatus.confirmed,
              ServiceBookingStatus.cancelled,
            ]
          : const [];
    }
    if (widget.operator.role == UserRole.technician) {
      if (booking.assignedToId != widget.operator.id) return const [];
      return switch (status) {
        ServiceBookingStatus.confirmed => const [
          ServiceBookingStatus.inProgress,
        ],
        ServiceBookingStatus.inProgress => const [
          ServiceBookingStatus.waitingResident,
        ],
        _ => const [],
      };
    }
    if (widget.operator.role == UserRole.manager) {
      return switch (status) {
        ServiceBookingStatus.pending => const [
          ServiceBookingStatus.confirmed,
          ServiceBookingStatus.cancelled,
        ],
        ServiceBookingStatus.confirmed ||
        ServiceBookingStatus.inProgress ||
        ServiceBookingStatus.waitingResident => const [
          ServiceBookingStatus.cancelled,
        ],
        _ => const [],
      };
    }
    if (widget.operator.role != UserRole.admin) return const [];
    return switch (status) {
      ServiceBookingStatus.pending => [
        ServiceBookingStatus.confirmed,
        ServiceBookingStatus.cancelled,
      ],
      ServiceBookingStatus.confirmed => [
        ServiceBookingStatus.inProgress,
        ServiceBookingStatus.cancelled,
      ],
      ServiceBookingStatus.inProgress => [
        ServiceBookingStatus.waitingResident,
        ServiceBookingStatus.cancelled,
      ],
      ServiceBookingStatus.waitingResident => [ServiceBookingStatus.cancelled],
      ServiceBookingStatus.completed ||
      ServiceBookingStatus.cancelled => const [],
    };
  }

  Future<void> _runBookingAction(
    ServiceBooking booking, {
    required Future<bool> Function() action,
    required String successMessage,
    required String fallbackError,
  }) async {
    if (_busyBookingIds.contains(booking.id)) return;
    setState(() => _busyBookingIds.add(booking.id));
    final success = await action();
    if (!mounted) return;
    setState(() => _busyBookingIds.remove(booking.id));
    _showResult(
      success,
      success
          ? successMessage
          : widget.serviceController.errorMessage ?? fallbackError,
    );
  }

  Future<void> _toggleService(ResidentService service) async {
    if (_busyServiceIds.contains(service.id)) return;
    setState(() => _busyServiceIds.add(service.id));
    final success = await widget.serviceController.toggleServiceActive(
      service.id,
    );
    if (!mounted) return;
    setState(() => _busyServiceIds.remove(service.id));
    _showResult(
      success,
      success
          ? service.isActive
                ? 'Đã tạm ngừng dịch vụ ${service.name}.'
                : 'Đã mở lại dịch vụ ${service.name}.'
          : widget.serviceController.errorMessage ??
                'Không thể thay đổi trạng thái dịch vụ.',
    );
  }

  void _showResult(bool success, String message) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: colors.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.section, required this.onSectionChanged});

  final _ManagementSection section;
  final ValueChanged<_ManagementSection> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điều phối dịch vụ cư dân',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Tiếp nhận đơn, phân công thực hiện và quản lý dịch vụ đang cung cấp.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          );
          final selector = SegmentedButton<_ManagementSection>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _ManagementSection.bookings,
                icon: Icon(Icons.assignment_outlined),
                label: Text('Đơn đăng ký'),
              ),
              ButtonSegment(
                value: _ManagementSection.catalog,
                icon: Icon(Icons.storefront_outlined),
                label: Text('Danh mục dịch vụ'),
              ),
            ],
            selected: {section},
            onSelectionChanged: (value) => onSectionChanged(value.first),
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [intro, const SizedBox(height: 16), selector],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 20),
              selector,
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Tìm kiếm',
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa từ khóa',
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ManagementSection { bookings, catalog }
