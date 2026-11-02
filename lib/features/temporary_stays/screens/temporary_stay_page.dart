import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/status_badge.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';

import '../controllers/temporary_stay_controller.dart';
import '../models/temporary_stay.dart';
import '../models/temporary_stay_status.dart';

class TemporaryStayPage extends StatefulWidget {
  const TemporaryStayPage({
    required this.controller,
    required this.membershipController,
    required this.user,
    required this.managementMode,
    super.key,
  });
  final TemporaryStayController controller;
  final ApartmentMembershipController membershipController;
  final User user;
  final bool managementMode;

  @override
  State<TemporaryStayPage> createState() => _TemporaryStayPageState();
}

class _TemporaryStayPageState extends State<TemporaryStayPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => Future.wait([
    widget.controller.load(),
    widget.membershipController.load(),
  ]);

  @override
  Widget build(BuildContext context) => ResidentPageScaffold(
    title: widget.managementMode
        ? 'Quản lý khách lưu trú'
        : 'Đăng ký khách lưu trú',
    subtitle: widget.managementMode
        ? 'Tiếp nhận và duyệt khai báo của cư dân'
        : '${widget.membershipController.apartmentById(widget.membershipController.activeMembershipForResident(widget.user.id)?.apartmentId ?? '')?.code ?? 'Chưa chọn căn'} · Khách lưu trú',
    icon: Icons.badge_outlined,
    accentColor: AppColors.secondary,
    accentSoftColor: AppColors.secondaryLight,
    actions: [
      IconButton(
        tooltip: 'Tải lại dữ liệu',
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    floatingActionButton: widget.managementMode
        ? null
        : ResidentFloatingAction(
            onPressed: _create,
            icon: Icons.person_add_alt_1,
            label: 'Đăng ký',
            color: AppColors.secondary,
            endColor: AppColors.primary,
          ),
    body: ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.membershipController,
      ]),
      builder: (context, child) {
        if (widget.controller.isLoading && widget.controller.stays.isEmpty) {
          return const LoadingView(message: 'Đang tải khách lưu trú…');
        }
        if (widget.controller.errorMessage != null &&
            widget.controller.stays.isEmpty) {
          return ErrorView(
            message: widget.controller.errorMessage,
            onRetry: _load,
          );
        }
        final activeApartmentId = widget.membershipController
            .activeMembershipForResident(widget.user.id)
            ?.apartmentId;
        final visibleStays = widget.managementMode
            ? widget.controller.stays
            : widget.controller.stays
                  .where((stay) => stay.apartmentId == activeApartmentId)
                  .toList(growable: false);
        if (visibleStays.isEmpty) {
          return EmptyView(
            icon: Icons.badge_outlined,
            title: 'Chưa có khách lưu trú',
            message: widget.managementMode
                ? 'Các đăng ký của cư dân sẽ xuất hiện tại đây.'
                : 'Nhấn “Đăng ký” để khai báo khách ở tạm.',
            actionLabel: 'Tải lại',
            onAction: _load,
          );
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
            itemCount: visibleStays.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _StayCard(
              stay: visibleStays[index],
              management:
                  widget.managementMode &&
                  widget.user.role.canReviewTemporaryStays,
              guardMode:
                  widget.user.role == UserRole.security ||
                  widget.user.role == UserRole.admin,
              onApprove: () => _review(visibleStays[index], true),
              onReject: () => _review(visibleStays[index], false),
              onCancel: () => _cancel(visibleStays[index]),
              onCheckIn: () => _gateAction(visibleStays[index], checkIn: true),
              onCheckOut: () =>
                  _gateAction(visibleStays[index], checkIn: false),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _create() async {
    final membership = widget.membershipController.activeMembershipForResident(
      widget.user.id,
    );
    if (membership == null) {
      _message('Bạn chưa được gắn với căn hộ đang cư trú.');
      return;
    }
    final draft = await showDialog<_StayDraft>(
      context: context,
      builder: (_) => const _StayDialog(),
    );
    if (draft == null || !mounted) return;
    final ok = await widget.controller.create(
      apartmentId: membership.apartmentId,
      guestFullName: draft.name,
      guestPhone: draft.phone,
      relationshipToResident: draft.relationship,
      startDate: draft.start,
      endDate: draft.end,
      purpose: draft.purpose,
    );
    if (mounted) {
      _message(
        ok
            ? 'Đã gửi đăng ký khách lưu trú.'
            : widget.controller.errorMessage ?? 'Không thể gửi đăng ký.',
      );
    }
  }

  Future<void> _cancel(TemporaryStay stay) async {
    final ok = await widget.controller.cancel(stay.id);
    if (mounted) {
      _message(
        ok
            ? 'Đã hủy đăng ký.'
            : widget.controller.errorMessage ?? 'Không thể hủy.',
      );
    }
  }

  Future<void> _review(TemporaryStay stay, bool approved) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Duyệt đăng ký' : 'Từ chối đăng ký'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: approved ? 'Ghi chú (không bắt buộc)' : 'Lý do từ chối',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: Text(approved ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !mounted) return;
    final ok = await widget.controller.review(
      id: stay.id,
      approved: approved,
      note: note,
    );
    if (mounted) {
      _message(
        ok
            ? (approved ? 'Đã duyệt đăng ký.' : 'Đã từ chối đăng ký.')
            : widget.controller.errorMessage ?? 'Không thể xử lý.',
      );
    }
  }

  Future<void> _gateAction(TemporaryStay stay, {required bool checkIn}) async {
    final ok = checkIn
        ? await widget.controller.checkIn(stay.id)
        : await widget.controller.checkOut(stay.id);
    if (!mounted) return;
    _message(
      ok
          ? checkIn
                ? 'Đã xác nhận khách vào tòa.'
                : 'Đã xác nhận khách rời tòa.'
          : widget.controller.errorMessage ?? 'Không thể cập nhật khách.',
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
      );
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.stay,
    required this.management,
    required this.guardMode,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onCheckIn,
    required this.onCheckOut,
  });
  final TemporaryStay stay;
  final bool management;
  final bool guardMode;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stay.guestFullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Khách tại căn ${stay.apartmentCode}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _badge(stay.status),
            ],
          ),
          const Divider(height: 28),
          _StayInfoLine(
            icon: Icons.person_outline_rounded,
            text: 'Người khai báo: ${stay.declaredByName}',
          ),
          const SizedBox(height: 9),
          _StayInfoLine(
            icon: Icons.date_range_outlined,
            text: '${_date(stay.startDate)} → ${_date(stay.endDate)}',
          ),
          if ((stay.relationshipToResident ?? '').isNotEmpty) ...[
            const SizedBox(height: 9),
            _StayInfoLine(
              icon: Icons.family_restroom_outlined,
              text: 'Quan hệ: ${stay.relationshipToResident}',
            ),
          ],
          if ((stay.guestPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: 9),
            _StayInfoLine(
              icon: Icons.phone_outlined,
              text: 'Điện thoại: ${stay.guestPhone}',
            ),
          ],
          if ((stay.purpose ?? '').isNotEmpty) ...[
            const SizedBox(height: 9),
            _StayInfoLine(
              icon: Icons.notes_rounded,
              text: 'Mục đích: ${stay.purpose}',
            ),
          ],
          if ((stay.reviewNote ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            Text('Phản hồi: ${stay.reviewNote}'),
          ],
          if (stay.checkedInAt != null) ...[
            const SizedBox(height: 9),
            _StayInfoLine(
              icon: Icons.login_rounded,
              text:
                  'Vào tòa: ${_dateTime(stay.checkedInAt!)} · '
                  '${stay.checkedInByName ?? 'Bảo vệ'}',
            ),
          ],
          if (stay.checkedOutAt != null) ...[
            const SizedBox(height: 9),
            _StayInfoLine(
              icon: Icons.logout_rounded,
              text:
                  'Rời tòa: ${_dateTime(stay.checkedOutAt!)} · '
                  '${stay.checkedOutByName ?? 'Bảo vệ'}',
            ),
          ],
          if (stay.status == TemporaryStayStatus.pending) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: management
                    ? [
                        OutlinedButton(
                          onPressed: onReject,
                          child: const Text('Từ chối'),
                        ),
                        FilledButton(
                          onPressed: onApprove,
                          child: const Text('Duyệt'),
                        ),
                      ]
                    : [
                        OutlinedButton(
                          onPressed: onCancel,
                          child: const Text('Hủy đăng ký'),
                        ),
                      ],
              ),
            ),
          ],
          if (guardMode && stay.status == TemporaryStayStatus.approved) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onCheckIn,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Xác nhận vào tòa'),
              ),
            ),
          ],
          if (guardMode && stay.status == TemporaryStayStatus.checkedIn) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onCheckOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Xác nhận rời tòa'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _dateTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} · ${_date(value)}';
  static StatusBadge _badge(TemporaryStayStatus value) => StatusBadge(
    label: value.label,
    tone: switch (value) {
      TemporaryStayStatus.approved => StatusBadgeTone.success,
      TemporaryStayStatus.checkedIn => StatusBadgeTone.info,
      TemporaryStayStatus.checkedOut => StatusBadgeTone.success,
      TemporaryStayStatus.pending => StatusBadgeTone.warning,
      TemporaryStayStatus.rejected => StatusBadgeTone.danger,
      _ => StatusBadgeTone.neutral,
    },
  );
}

class _StayInfoLine extends StatelessWidget {
  const _StayInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, size: 18, color: AppColors.secondary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
      ),
    ],
  );
}

class _StayDialog extends StatefulWidget {
  const _StayDialog();
  @override
  State<_StayDialog> createState() => _StayDialogState();
}

class _StayDialogState extends State<_StayDialog> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final relationship = TextEditingController();
  final purpose = TextEditingController();
  DateTime start = DateTime.now().add(const Duration(days: 1));
  DateTime end = DateTime.now().add(const Duration(days: 2));
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    relationship.dispose();
    purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đăng ký khách lưu trú'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Họ tên khách *'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            TextField(
              controller: relationship,
              decoration: const InputDecoration(
                labelText: 'Quan hệ với cư dân',
              ),
            ),
            TextField(
              controller: purpose,
              decoration: const InputDecoration(labelText: 'Mục đích lưu trú'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(_StayCard._date(start)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _pick(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày kết thúc'),
              subtitle: Text(_StayCard._date(end)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _pick(false),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (name.text.trim().length < 2) return;
          Navigator.pop(
            context,
            _StayDraft(
              name.text.trim(),
              phone.text.trim(),
              relationship.text.trim(),
              purpose.text.trim(),
              start,
              end,
            ),
          );
        },
        child: const Text('Gửi đăng ký'),
      ),
    ],
  );
  Future<void> _pick(bool isStart) async {
    final first = isStart ? DateTime.now() : start;
    final last = isStart
        ? DateTime.now().add(const Duration(days: 365))
        : start.add(const Duration(days: 30));
    final selected = isStart ? start : end;
    final initial = selected.isAfter(last) ? last : selected;
    final value = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: initial,
    );
    if (value == null) return;
    setState(() {
      if (isStart) {
        start = value;
        if (end.isBefore(start)) end = start;
      } else {
        end = value;
      }
    });
  }
}

class _StayDraft {
  const _StayDraft(
    this.name,
    this.phone,
    this.relationship,
    this.purpose,
    this.start,
    this.end,
  );
  final String name, phone, relationship, purpose;
  final DateTime start, end;
}
