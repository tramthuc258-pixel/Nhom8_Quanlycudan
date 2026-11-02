import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/residents/models/residence_verification.dart';
import 'package:homie/features/residents/models/membership_type.dart';

class ResidenceVerificationPage extends StatefulWidget {
  const ResidenceVerificationPage({required this.controller, super.key});
  final ApartmentMembershipController controller;

  @override
  State<ResidenceVerificationPage> createState() =>
      _ResidenceVerificationPageState();
}

class _ResidenceVerificationPageState extends State<ResidenceVerificationPage> {
  ResidenceVerificationState? _filter = ResidenceVerificationState.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadVerificationRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyệt cư dân'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: widget.controller.isLoading
                ? null
                : widget.controller.loadVerificationRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final items = widget.controller.verificationRequests
                .where((item) => _filter == null || item.state == _filter)
                .toList();
            final pendingCount = widget.controller.verificationRequests
                .where(
                  (item) => item.state == ResidenceVerificationState.pending,
                )
                .length;
            return Column(
              children: [
                if (widget.controller.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                _OverviewHeader(
                  total: widget.controller.verificationRequests.length,
                  pending: pendingCount,
                ),
                _filters(),
                if (widget.controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MaterialBanner(
                      content: Text(widget.controller.errorMessage!),
                      actions: [
                        TextButton(
                          onPressed: widget.controller.clearError,
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyRequests()
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, index) => _RequestCard(
                                request: items[index],
                                controller: widget.controller,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filters() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              _chip('Tất cả', null, Icons.grid_view_rounded),
              const SizedBox(width: 8),
              _chip(
                'Chờ duyệt',
                ResidenceVerificationState.pending,
                Icons.schedule_rounded,
              ),
              const SizedBox(width: 8),
              _chip(
                'Đã duyệt',
                ResidenceVerificationState.approved,
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _chip(
                'Cần bổ sung',
                ResidenceVerificationState.rejected,
                Icons.info_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, ResidenceVerificationState? value, IconData icon) {
    return ChoiceChip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({required this.total, required this.pending});
  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF244EB8), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x243157D5),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final intro = const Row(
                  children: [
                    _HeaderIcon(),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hồ sơ liên kết căn hộ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kiểm tra thông tin trước khi mở quyền cư dân.',
                            style: TextStyle(color: Color(0xFFDCE7FF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final metrics = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderMetric(value: '$pending', label: 'chờ duyệt'),
                    const SizedBox(width: 10),
                    _HeaderMetric(value: '$total', label: 'tổng hồ sơ'),
                  ],
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      intro,
                      const SizedBox(height: 16),
                      Align(alignment: Alignment.centerLeft, child: metrics),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 20),
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.fact_check_outlined,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFFDCE7FF))),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Không có hồ sơ ở mục này',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Các yêu cầu mới sẽ xuất hiện tại đây.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.controller});
  final ResidenceVerification request;
  final ApartmentMembershipController controller;

  @override
  Widget build(BuildContext context) {
    final pending = request.state == ResidenceVerificationState.pending;
    final stateColor = _stateColor(request.state);
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: stateColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: stateColor.withValues(alpha: .1),
                  child: Text(
                    _initials(request.fullName ?? '?'),
                    style: TextStyle(
                      color: stateColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName ?? 'Tài khoản cư dân',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        request.email ?? '',
                        style: const TextStyle(color: Color(0xFF69748D)),
                      ),
                    ],
                  ),
                ),
                _statusBadge(request.state),
              ],
            ),
            const Divider(height: 30),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _detail(
                  Icons.apartment_rounded,
                  '${request.apartmentCode ?? '—'} · ${request.buildingName ?? '—'}',
                ),
                _detail(
                  Icons.badge_outlined,
                  request.type?.displayName ?? 'Chưa xác định',
                ),
                if (request.phone?.isNotEmpty ?? false)
                  _detail(Icons.phone_outlined, request.phone!),
              ],
            ),
            if (request.note?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              _MessageBox(
                icon: Icons.chat_bubble_outline_rounded,
                label: request.note!,
                color: AppColors.info,
                background: AppColors.infoContainer,
              ),
            ],
            if (request.reviewNote?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _MessageBox(
                icon: Icons.reply_rounded,
                label: request.reviewNote!,
                color: stateColor,
                background: stateColor.withValues(alpha: .08),
              ),
            ],
            if (request.verificationBasis?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _MessageBox(
                icon: Icons.fact_check_outlined,
                label: 'Đã đối chiếu: ${request.verificationBasis}',
                color: AppColors.success,
                background: AppColors.successContainer,
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: Color(0xFFF3B5B5)),
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () => _reject(context),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Từ chối'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () => _approve(context),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Duyệt cư dân'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _statusBadge(ResidenceVerificationState state) {
    final label = switch (state) {
      ResidenceVerificationState.pending => ('Chờ duyệt'),
      ResidenceVerificationState.approved => ('Đã duyệt'),
      ResidenceVerificationState.rejected => ('Cần bổ sung'),
      ResidenceVerificationState.notSubmitted => ('Chưa gửi'),
    };
    final color = _stateColor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _stateColor(ResidenceVerificationState state) => switch (state) {
    ResidenceVerificationState.pending => AppColors.warning,
    ResidenceVerificationState.approved => AppColors.success,
    ResidenceVerificationState.rejected => AppColors.error,
    ResidenceVerificationState.notSubmitted => AppColors.textSecondary,
  };

  Future<void> _approve(BuildContext context) async {
    final basis = await showDialog<String>(
      context: context,
      builder: (context) => _ApprovalDialog(request: request),
    );
    if (basis == null || request.id == null) return;
    await controller.reviewResidenceVerification(
      requestId: request.id!,
      approve: true,
      verificationBasis: basis,
    );
  }

  Future<void> _reject(BuildContext context) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu bổ sung'),
        content: TextField(
          controller: noteController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Thông tin người thuê chưa được chủ hộ xác nhận…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              final value = noteController.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || request.id == null) return;
    await controller.reviewResidenceVerification(
      requestId: request.id!,
      approve: false,
      reviewNote: note,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog({required this.request});
  final ResidenceVerification request;

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  static const _options = [
    'Hồ sơ bàn giao căn hộ',
    'Danh sách chủ sở hữu',
    'Chủ hộ đã xác nhận',
    'Hồ sơ thuê đã đối chiếu',
  ];

  String? _basis;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.verified_user_rounded,
        color: AppColors.success,
        size: 34,
      ),
      title: const Text('Xác nhận cư dân'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.request.fullName} · ${widget.request.apartmentCode}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _basis,
              decoration: const InputDecoration(
                labelText: 'Căn cứ xác minh',
                prefixIcon: Icon(Icons.fact_check_outlined),
              ),
              items: _options
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _basis = value),
            ),
            const SizedBox(height: 10),
            const Text(
              'Thông tin này chỉ dùng nội bộ để lưu lịch sử xét duyệt.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: _basis == null
              ? null
              : () => Navigator.pop(context, _basis),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Duyệt hồ sơ'),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
