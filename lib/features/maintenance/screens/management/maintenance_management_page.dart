import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/maintenance/models/maintenance_request.dart';
import 'package:homie/core/models/work_assignee.dart';

import '../../controllers/maintenance_controller.dart';
import '../../widgets/maintenance_widgets.dart';

class MaintenanceManagementPage extends StatefulWidget {
  const MaintenanceManagementPage({
    required this.controller,
    required this.apartmentMembershipController,
    required this.manager,
    super.key,
  });

  final MaintenanceController controller;
  final ApartmentMembershipController apartmentMembershipController;
  final User manager;

  @override
  State<MaintenanceManagementPage> createState() =>
      _MaintenanceManagementPageState();
}

class _MaintenanceManagementPageState extends State<MaintenanceManagementPage> {
  final _searchController = TextEditingController();
  MaintenanceStatus? _status;
  MaintenancePriority? _priority;
  bool _waiting = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    await Future.wait<void>([
      widget.controller.load(),
      widget.apartmentMembershipController.load(),
    ]);
    if (mounted) setState(() => _waiting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yêu cầu sửa chữa'),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
    final items = _filtered();
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _overview()),
          SliverToBoxAdapter(child: _filters()),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  widget.controller.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.build_circle_outlined,
                title: widget.controller.requests.isEmpty
                    ? 'Chưa có yêu cầu'
                    : 'Không tìm thấy yêu cầu',
                message: widget.controller.requests.isEmpty
                    ? 'Yêu cầu do cư dân gửi sẽ xuất hiện tại đây.'
                    : 'Hãy đổi từ khóa hoặc bộ lọc để xem kết quả khác.',
                actionLabel: widget.controller.requests.isEmpty
                    ? 'Tải lại'
                    : 'Xóa bộ lọc',
                onAction: widget.controller.requests.isEmpty
                    ? _load
                    : _clearFilters,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent >= 1120
                      ? 3
                      : constraints.crossAxisExtent >= 720
                      ? 2
                      : 1;
                  Widget requestCard(int index, {bool compact = false}) {
                    final request = items[index];
                    final apartment = widget.apartmentMembershipController
                        .apartmentById(request.apartmentId);
                    return MaintenanceRequestCard(
                      request: request,
                      apartmentCode: apartment?.code ?? '—',
                      compact: compact,
                      onTap: () => _showDetail(request),
                    );
                  }

                  return columns == 1
                      ? SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: requestCard(index, compact: true),
                          ),
                        )
                      : SliverGrid.builder(
                          itemCount: items.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 292,
                              ),
                          itemBuilder: (context, index) => requestCard(index),
                        );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điều phối yêu cầu cư dân',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tiếp nhận, phân công và ghi lại toàn bộ tiến trình xử lý.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overview() {
    final all = widget.controller.requests;
    final open = all.where((item) => item.isOpen).length;
    final urgent = all
        .where(
          (item) => item.isOpen && item.priority == MaintenancePriority.urgent,
        )
        .length;
    final unassigned = all
        .where((item) => item.isOpen && item.assignedTo == null)
        .length;
    final completed = all
        .where((item) => item.status == MaintenanceStatus.completed)
        .length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final cards = [
                _OverviewCard(
                  label: 'Đang mở',
                  value: open,
                  icon: Icons.pending_actions_rounded,
                  compact: compact,
                ),
                _OverviewCard(
                  label: 'Khẩn cấp',
                  value: urgent,
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  compact: compact,
                ),
                _OverviewCard(
                  label: 'Chưa phân công',
                  value: unassigned,
                  icon: Icons.person_search_rounded,
                  color: AppColors.warning,
                  compact: compact,
                ),
                _OverviewCard(
                  label: 'Hoàn thành',
                  value: completed,
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                  compact: compact,
                ),
              ];
              return compact
                  ? GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.75,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: cards,
                    )
                  : Wrap(spacing: 10, runSpacing: 10, children: cards);
            },
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final search = TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm theo mã, tiêu đề, căn hộ hoặc cư dân…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              );
              final status = DropdownButtonFormField<MaintenanceStatus?>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(compact ? 'Tất cả' : 'Tất cả trạng thái'),
                  ),
                  for (final item in MaintenanceStatus.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: (value) => setState(() => _status = value),
              );
              final priority = DropdownButtonFormField<MaintenancePriority?>(
                isExpanded: true,
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Ưu tiên'),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(compact ? 'Tất cả' : 'Tất cả mức độ'),
                  ),
                  for (final item in MaintenancePriority.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: (value) => setState(() => _priority = value),
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: status),
                        const SizedBox(width: 10),
                        Expanded(child: priority),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: search),
                  const SizedBox(width: 10),
                  Expanded(child: status),
                  const SizedBox(width: 10),
                  Expanded(child: priority),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<MaintenanceRequest> _filtered() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.requests
        .where((request) {
          if (_status != null && request.status != _status) return false;
          if (_priority != null && request.priority != _priority) return false;
          if (query.isEmpty) return true;
          final apartment = widget.apartmentMembershipController.apartmentById(
            request.apartmentId,
          );
          final resident = widget.apartmentMembershipController.residentById(
            request.residentId,
          );
          return '${request.code} ${request.title} ${request.description} ${apartment?.code} ${resident?.fullName}'
              .toLowerCase()
              .contains(query);
        })
        .toList(growable: false);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _status = null;
      _priority = null;
    });
  }

  Future<void> _showDetail(MaintenanceRequest request) async {
    final apartment = widget.apartmentMembershipController.apartmentById(
      request.apartmentId,
    );
    final resident = widget.apartmentMembershipController.residentById(
      request.residentId,
    );
    final action = await showModalBottomSheet<_ManagementAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.code,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      MaintenanceStatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    request.description,
                    style: const TextStyle(height: 1.5),
                  ),
                  const Divider(height: 30),
                  _DetailRow(label: 'Căn hộ', value: apartment?.code ?? '—'),
                  _DetailRow(
                    label: 'Người gửi',
                    value: resident?.fullName ?? '—',
                  ),
                  _DetailRow(label: 'Vị trí', value: request.location),
                  _DetailRow(
                    label: 'Phụ trách',
                    value: request.assignedTo ?? 'Chưa phân công',
                  ),
                  if (request.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    MaintenanceAttachments(urls: request.imageUrls),
                  ],
                  const SizedBox(height: 18),
                  MaintenanceTimeline(request: request),
                  if (request.isOpen) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (widget.manager.role.canAssignMaintenance)
                          AppButton(
                            label: 'Phân công',
                            icon: Icons.person_add_alt_1_rounded,
                            variant: AppButtonVariant.outlined,
                            onPressed: () => Navigator.pop(
                              context,
                              _ManagementAction.assign,
                            ),
                          ),
                        if (_nextStatuses(request).isNotEmpty)
                          AppButton(
                            label: 'Cập nhật trạng thái',
                            icon: Icons.update_rounded,
                            onPressed: () => Navigator.pop(
                              context,
                              _ManagementAction.status,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _ManagementAction.assign) {
      await _assign(request);
    } else {
      await _updateStatus(request);
    }
  }

  Future<void> _assign(MaintenanceRequest request) async {
    List<WorkAssignee> assignees;
    try {
      assignees = await widget.controller.getAssignees(request.id);
    } catch (error) {
      if (!mounted) return;
      _showResult(false, error.toString().replaceFirst('Bad state: ', ''));
      return;
    }
    if (!mounted) return;
    if (assignees.isEmpty) {
      _showResult(
        false,
        'Tòa nhà chưa có kỹ thuật viên đang hoạt động. Hãy phân công nhân viên vào tòa trước.',
      );
      return;
    }
    WorkAssignee? selected;
    final assignee = await showDialog<WorkAssignee>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Phân công kỹ thuật viên'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DropdownButtonFormField<WorkAssignee>(
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nhân viên thuộc tòa nhà',
                prefixIcon: Icon(Icons.engineering_rounded),
              ),
              hint: const Text('Chọn kỹ thuật viên phụ trách'),
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
    final success = await widget.controller.assignRequest(
      requestId: request.id,
      assigneeId: assignee.id,
      assigneeName: assignee.fullName,
      actorName: widget.manager.fullName,
    );
    _showResult(
      success,
      success
          ? 'Đã giao ${request.code} cho ${assignee.fullName}.'
          : widget.controller.errorMessage ?? 'Không thể phân công yêu cầu.',
    );
  }

  Future<void> _updateStatus(MaintenanceRequest request) async {
    final choices = _nextStatuses(request);
    if (choices.isEmpty) return;
    var selected = choices.first;
    final note = TextEditingController();
    final draft = await showDialog<(MaintenanceStatus, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật trạng thái'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<MaintenanceStatus>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái mới',
                  ),
                  items: [
                    for (final item in choices)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selected = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú xử lý',
                    hintText: 'Nội dung cư dân cần biết…',
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
              onPressed: () =>
                  Navigator.pop(context, (selected, note.text.trim())),
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    if (draft == null || !mounted) return;
    final success = await widget.controller.updateStatus(
      requestId: request.id,
      status: draft.$1,
      note: draft.$2,
      actorName: widget.manager.fullName,
    );
    _showResult(success, 'Đã cập nhật trạng thái yêu cầu.');
  }

  List<MaintenanceStatus> _nextStatuses(MaintenanceRequest request) {
    final current = request.status;
    if (widget.manager.role == UserRole.receptionist) {
      return current == MaintenanceStatus.submitted
          ? const [MaintenanceStatus.received, MaintenanceStatus.cancelled]
          : const [];
    }
    if (widget.manager.role == UserRole.technician) {
      if (request.assignedToId != widget.manager.id) return const [];
      return switch (current) {
        MaintenanceStatus.received => const [MaintenanceStatus.inProgress],
        MaintenanceStatus.inProgress => const [
          MaintenanceStatus.waitingResident,
        ],
        _ => const [],
      };
    }
    if (widget.manager.role == UserRole.manager) {
      return switch (current) {
        MaintenanceStatus.submitted => const [
          MaintenanceStatus.received,
          MaintenanceStatus.cancelled,
        ],
        MaintenanceStatus.received ||
        MaintenanceStatus.inProgress ||
        MaintenanceStatus.waitingResident => const [
          MaintenanceStatus.cancelled,
        ],
        _ => const [],
      };
    }
    if (widget.manager.role != UserRole.admin) return const [];
    return switch (current) {
      MaintenanceStatus.submitted => [
        MaintenanceStatus.received,
        MaintenanceStatus.cancelled,
      ],
      MaintenanceStatus.received => [
        MaintenanceStatus.inProgress,
        MaintenanceStatus.waitingResident,
        MaintenanceStatus.cancelled,
      ],
      MaintenanceStatus.inProgress => [
        MaintenanceStatus.waitingResident,
        MaintenanceStatus.cancelled,
      ],
      MaintenanceStatus.waitingResident => [MaintenanceStatus.cancelled],
      MaintenanceStatus.completed || MaintenanceStatus.cancelled => const [],
    };
  }

  void _showResult(bool success, String successMessage) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : widget.controller.errorMessage ?? 'Không thể cập nhật yêu cầu.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _ManagementAction { assign, status }

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.compact = false,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : 205,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: compact ? 20 : 24),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
