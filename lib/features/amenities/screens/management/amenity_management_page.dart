import 'package:flutter/material.dart';

import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/amenities/controllers/amenity_controller.dart';
import 'package:homie/features/amenities/widgets/amenity_widgets.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/enums/user_role.dart';

class AmenityManagementPage extends StatefulWidget {
  const AmenityManagementPage({
    required this.controller,
    required this.operator,
    this.canManageCatalog = true,
    super.key,
  });
  final AmenityController controller;
  final User operator;
  final bool canManageCatalog;
  @override
  State<AmenityManagementPage> createState() => _AmenityManagementPageState();
}

class _AmenityManagementPageState extends State<AmenityManagementPage> {
  bool _loading = true;
  bool _showAmenities = false;
  AmenityBookingStatus? _filter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await widget.controller.load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quản lý tiện ích'),
      actions: [
        if (widget.canManageCatalog)
          IconButton(
            tooltip: 'Khóa khung giờ',
            onPressed: _loading ? null : _blockSlot,
            icon: const Icon(Icons.block_outlined),
          ),
        IconButton(
          tooltip: 'Tải lại dữ liệu',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (_loading) {
          return const LoadingView(message: 'Đang tải dữ liệu tiện ích…');
        }
        if (widget.controller.errorMessage != null &&
            widget.controller.amenities.isEmpty) {
          return ErrorView(
            message: widget.controller.errorMessage,
            onRetry: _load,
          );
        }
        return _showAmenities ? _amenitiesView() : _bookingsView();
      },
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Điều phối tiện ích',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          'Duyệt lượt đặt, quản lý khả dụng và khóa lịch bảo trì.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.event_note_outlined),
              label: Text('Lượt đặt'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.apartment_outlined),
              label: Text('Tiện ích'),
            ),
          ],
          selected: {_showAmenities},
          onSelectionChanged: (value) => setState(() {
            _showAmenities = value.first;
            _filter = null;
          }),
        ),
      ],
    ),
  );

  Widget _bookingsView() {
    final all = widget.controller.bookings;
    final items = _filter == null
        ? all
        : all.where((item) => item.status == _filter).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                ...AmenityBookingStatus.values.map(
                  (status) => ChoiceChip(
                    label: Text(status.label),
                    selected: _filter == status,
                    onSelected: (_) => setState(() => _filter = status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const SizedBox(
              height: 350,
              child: EmptyView(title: 'Không có lượt đặt phù hợp'),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AmenityBookingCard(
                  booking: item,
                  onApprove: item.status == AmenityBookingStatus.pending
                      ? () => _review(item, true)
                      : null,
                  onReject: item.status == AmenityBookingStatus.pending
                      ? () => _review(item, false)
                      : null,
                  onCheckIn:
                      _canOperate &&
                          item.status == AmenityBookingStatus.approved
                      ? () => _operate(item, _AmenityAction.checkIn)
                      : null,
                  onComplete:
                      _canOperate &&
                          item.status == AmenityBookingStatus.checkedIn
                      ? () => _operate(item, _AmenityAction.complete)
                      : null,
                  onNoShow:
                      _canOperate &&
                          item.status == AmenityBookingStatus.approved &&
                          DateTime.now().isAfter(item.endAt)
                      ? () => _operate(item, _AmenityAction.noShow)
                      : null,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _amenitiesView() => RefreshIndicator(
    onRefresh: _load,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final items = widget.controller.amenities;
              final columns = constraints.crossAxisExtent >= 950
                  ? 3
                  : constraints.crossAxisExtent >= 620
                  ? 2
                  : 1;
              return SliverGrid.builder(
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: 410,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (_, index) => AmenityCard(
                  amenity: items[index],
                  onToggle: widget.canManageCatalog
                      ? () => _toggle(items[index])
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  bool get _canOperate =>
      widget.operator.role == UserRole.receptionist ||
      widget.operator.role == UserRole.admin;

  Future<void> _operate(AmenityBooking booking, _AmenityAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action.confirmTitle),
        content: Text('${action.confirmMessage} ${booking.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action.buttonLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = switch (action) {
      _AmenityAction.checkIn => widget.controller.checkInBooking(booking.id),
      _AmenityAction.complete => widget.controller.completeBooking(booking.id),
      _AmenityAction.noShow => widget.controller.markNoShow(booking.id),
    };
    final ok = await success;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? action.successMessage
              : widget.controller.errorMessage ?? 'Không thể cập nhật.',
        ),
      ),
    );
  }

  Future<void> _toggle(Amenity amenity) async {
    final success = await widget.controller.toggleAmenityActive(amenity.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${amenity.name} đã ${amenity.isActive ? 'tạm ngưng' : 'mở lại'}.'
              : widget.controller.errorMessage ?? 'Không thể cập nhật.',
        ),
      ),
    );
  }

  Future<void> _review(AmenityBooking booking, bool approve) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
            approve ? 'Duyệt ${booking.code}' : 'Từ chối ${booking.code}',
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: approve ? 'Ghi chú (không bắt buộc)' : 'Lý do từ chối',
              hintText: approve ? 'Đã kiểm tra lịch.' : 'Nhập ít nhất 5 ký tự',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(approve ? 'Duyệt' : 'Từ chối'),
            ),
          ],
        );
      },
    );
    if (note == null || !mounted) return;
    final success = await widget.controller.reviewBooking(
      bookingId: booking.id,
      approved: approve,
      note: note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã ${approve ? 'duyệt' : 'từ chối'} lượt đặt.'
              : widget.controller.errorMessage ?? 'Không thể xử lý.',
        ),
      ),
    );
  }

  Future<void> _blockSlot() async {
    final draft = await showDialog<_BlockDraft>(
      context: context,
      builder: (_) => _BlockSlotDialog(amenities: widget.controller.amenities),
    );
    if (draft == null || !mounted) return;
    final success = await widget.controller.blockTimeSlot(
      amenityId: draft.amenityId,
      startAt: draft.startAt,
      endAt: draft.endAt,
      note: draft.note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã khóa khung giờ.'
              : widget.controller.errorMessage ?? 'Không thể khóa khung giờ.',
        ),
      ),
    );
  }
}

enum _AmenityAction { checkIn, complete, noShow }

extension on _AmenityAction {
  String get buttonLabel => switch (this) {
    _AmenityAction.checkIn => 'Check-in',
    _AmenityAction.complete => 'Hoàn tất',
    _AmenityAction.noShow => 'Xác nhận',
  };
  String get confirmTitle => switch (this) {
    _AmenityAction.checkIn => 'Xác nhận khách đến',
    _AmenityAction.complete => 'Hoàn tất lượt sử dụng',
    _AmenityAction.noShow => 'Ghi nhận không đến',
  };
  String get confirmMessage => switch (this) {
    _AmenityAction.checkIn => 'Check-in lượt đặt',
    _AmenityAction.complete => 'Đánh dấu hoàn tất lượt đặt',
    _AmenityAction.noShow => 'Đánh dấu cư dân không đến với lượt đặt',
  };
  String get successMessage => switch (this) {
    _AmenityAction.checkIn => 'Đã check-in lượt đặt.',
    _AmenityAction.complete => 'Đã hoàn tất lượt sử dụng.',
    _AmenityAction.noShow => 'Đã ghi nhận cư dân không đến.',
  };
}

class _BlockDraft {
  const _BlockDraft(this.amenityId, this.startAt, this.endAt, this.note);
  final String amenityId;
  final DateTime startAt;
  final DateTime endAt;
  final String note;
}

class _BlockSlotDialog extends StatefulWidget {
  const _BlockSlotDialog({required this.amenities});
  final List<Amenity> amenities;
  @override
  State<_BlockSlotDialog> createState() => _BlockSlotDialogState();
}

class _BlockSlotDialogState extends State<_BlockSlotDialog> {
  late String _amenityId;
  late DateTime _start;
  final _note = TextEditingController();
  @override
  void initState() {
    super.initState();
    _amenityId = widget.amenities.first.id;
    final day = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    _start = DateTime(day.year, day.month, day.day, 9);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amenity = widget.amenities.firstWhere(
      (item) => item.id == _amenityId,
    );
    final end = _start.add(Duration(minutes: amenity.slotDurationMinutes));
    return AlertDialog(
      title: const Text('Khóa khung giờ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _amenityId,
              decoration: const InputDecoration(labelText: 'Tiện ích'),
              items: widget.amenities
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _amenityId = value!),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bắt đầu'),
              subtitle: Text(amenityDateTime(_start)),
              leading: const Icon(Icons.schedule_outlined),
              onTap: _pick,
            ),
            Text(
              'Kết thúc: ${amenityDateTime(end)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do khóa',
                hintText: 'Ví dụ: bảo trì thiết bị',
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
          onPressed: () => Navigator.pop(
            context,
            _BlockDraft(_amenityId, _start, end, _note.text.trim()),
          ),
          child: const Text('Khóa lịch'),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time != null && mounted) {
      setState(
        () => _start = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }
}
