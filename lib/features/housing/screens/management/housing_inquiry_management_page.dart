import 'package:flutter/material.dart';

import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/housing/models/housing_inquiry.dart';

class HousingInquiryManagementPage extends StatefulWidget {
  const HousingInquiryManagementPage({required this.controller, super.key});

  final HousingController controller;

  @override
  State<HousingInquiryManagementPage> createState() =>
      _HousingInquiryManagementPageState();
}

class _HousingInquiryManagementPageState
    extends State<HousingInquiryManagementPage> {
  bool _waitingForFirstLoad = true;
  HousingInquiryStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await widget.controller.loadInquiries();
    if (mounted) setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu từ khách'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tải lại',
            onPressed: widget.controller.isLoading ? null : _load,
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
            if (_waitingForFirstLoad ||
                (widget.controller.isLoading &&
                    widget.controller.inquiries.isEmpty)) {
              return const LoadingView(message: 'Đang tải yêu cầu liên hệ…');
            }
            if (widget.controller.errorMessage != null &&
                widget.controller.inquiries.isEmpty) {
              return ErrorView(
                title: 'Không thể tải yêu cầu',
                message: widget.controller.errorMessage,
                onRetry: _load,
              );
            }
            return _buildContent();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    final inquiries = widget.controller.inquiries
        .where((item) => _statusFilter == null || item.status == _statusFilter)
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _buildHeader()),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  widget.controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          if (inquiries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.contact_phone_outlined,
                title: 'Chưa có yêu cầu phù hợp',
                message:
                    'Thông tin khách quan tâm căn hộ sẽ xuất hiện tại đây.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: inquiries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _InquiryCard(
                  inquiry: inquiries[index],
                  busy: widget.controller.isLoading,
                  onContacted: () =>
                      _update(inquiries[index], HousingInquiryStatus.contacted),
                  onClose: () =>
                      _update(inquiries[index], HousingInquiryStatus.closed),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final inquiries = widget.controller.inquiries;
    final newCount = inquiries
        .where((item) => item.status == HousingInquiryStatus.newRequest)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Khách quan tâm mua hoặc thuê',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('$newCount yêu cầu mới • ${inquiries.length} yêu cầu tổng cộng'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _filterChip(null, 'Tất cả'),
              _filterChip(HousingInquiryStatus.newRequest, 'Mới'),
              _filterChip(HousingInquiryStatus.contacted, 'Đã liên hệ'),
              _filterChip(HousingInquiryStatus.closed, 'Đã đóng'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(HousingInquiryStatus? status, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == status,
      onSelected: (_) => setState(() => _statusFilter = status),
    );
  }

  Future<void> _update(
    HousingInquiry inquiry,
    HousingInquiryStatus status,
  ) async {
    final noteController = TextEditingController(text: inquiry.staffNote);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == HousingInquiryStatus.contacted
              ? 'Xác nhận đã liên hệ'
              : 'Đóng yêu cầu',
        ),
        content: TextField(
          controller: noteController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Ghi chú nội bộ',
            alignLabelWithHint: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true) return;
    final success = await widget.controller.updateInquiry(
      inquiryId: inquiry.id,
      status: status,
      staffNote: note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã cập nhật yêu cầu ${inquiry.code}.'
                : widget.controller.errorMessage ?? 'Không thể cập nhật.',
          ),
        ),
      );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.inquiry,
    required this.busy,
    required this.onContacted,
    required this.onClose,
  });

  final HousingInquiry inquiry;
  final bool busy;
  final VoidCallback onContacted;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (inquiry.status) {
      HousingInquiryStatus.newRequest => colors.primary,
      HousingInquiryStatus.contacted => const Color(0xFFB46A00),
      HousingInquiryStatus.closed => colors.onSurfaceVariant,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${inquiry.code} • ${inquiry.apartmentCode}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    inquiry.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(inquiry.listingTitle),
            const Divider(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: <Widget>[
                _Info(icon: Icons.person_outline, text: inquiry.fullName),
                _Info(icon: Icons.phone_outlined, text: inquiry.phone),
                if (inquiry.email != null)
                  _Info(icon: Icons.mail_outline, text: inquiry.email!),
                _Info(
                  icon: Icons.schedule_outlined,
                  text: _formatDate(inquiry.createdAt),
                ),
              ],
            ),
            if (inquiry.message case final message?) ...<Widget>[
              const SizedBox(height: 14),
              Text('Lời nhắn: $message'),
            ],
            if (inquiry.staffNote case final note?) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Ghi chú nội bộ: $note',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            if (inquiry.status != HousingInquiryStatus.closed) ...<Widget>[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: <Widget>[
                  if (inquiry.status == HousingInquiryStatus.newRequest)
                    FilledButton.icon(
                      onPressed: busy ? null : onContacted,
                      icon: const Icon(Icons.phone_in_talk_outlined),
                      label: const Text('Đã liên hệ'),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onClose,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Đóng yêu cầu'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} ${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
