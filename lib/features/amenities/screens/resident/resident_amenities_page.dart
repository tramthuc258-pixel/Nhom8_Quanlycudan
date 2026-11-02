import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/amenities/models/amenity.dart';
import 'package:homie/features/amenities/models/amenity_booking.dart';
import 'package:homie/features/amenities/models/amenity_booking_status.dart';
import 'package:homie/features/amenities/controllers/amenity_controller.dart';
import 'package:homie/features/amenities/widgets/amenity_widgets.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

class ResidentAmenitiesPage extends StatefulWidget {
  const ResidentAmenitiesPage({
    required this.controller,
    required this.apartmentMembershipController,
    required this.user,
    super.key,
  });
  final AmenityController controller;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  @override
  State<ResidentAmenitiesPage> createState() => _ResidentAmenitiesPageState();
}

class _ResidentAmenitiesPageState extends State<ResidentAmenitiesPage> {
  bool _loading = true;
  bool _showBookings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait([
      widget.controller.load(),
      widget.apartmentMembershipController.load(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => ResidentPageScaffold(
    title: 'Tiện ích chung',
    subtitle:
        '${widget.apartmentMembershipController.apartmentById(widget.apartmentMembershipController.activeMembershipForResident(widget.user.id)?.apartmentId ?? '')?.code ?? 'Chưa chọn căn'} · Đặt lịch tiện ích',
    icon: Icons.event_available_outlined,
    accentColor: AppColors.amenity,
    accentSoftColor: AppColors.amenitySoft,
    actions: [
      IconButton(
        tooltip: 'Tải lại dữ liệu',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (_loading) {
          return const LoadingView(message: 'Đang tải tiện ích…');
        }
        if (widget.controller.errorMessage != null &&
            widget.controller.amenities.isEmpty) {
          return ErrorView(
            message: widget.controller.errorMessage,
            onRetry: _load,
          );
        }
        return _showBookings ? _buildBookings() : _buildAmenities();
      },
    ),
  );

  Widget _buildAmenities() {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final membership = widget.apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? <Color>[scheme.surface, scheme.surfaceContainerHigh]
                        : <Color>[Colors.white, AppColors.amenitySoft],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.amenity.withValues(alpha: .15),
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
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.amenity,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Không gian dành cho bạn',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.controller.amenities.length} tiện ích sẵn sàng đặt lịch',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionSelector(),
                    if (membership == null)
                      Container(
                        margin: const EdgeInsets.only(top: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Bạn cần có căn hộ đang hiệu lực trước khi đặt tiện ích.',
                                style: TextStyle(color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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
                if (columns == 1) {
                  return SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AmenityCard(
                        amenity: items[index],
                        compact: true,
                        onBook: membership == null
                            ? null
                            : () => _openBooking(
                                items[index],
                                membership.apartmentId,
                              ),
                      ),
                    ),
                  );
                }
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
                    onBook: membership == null
                        ? null
                        : () => _openBooking(
                            items[index],
                            membership.apartmentId,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookings() {
    final scheme = Theme.of(context).colorScheme;
    final apartmentId = widget.apartmentMembershipController
        .activeMembershipForResident(widget.user.id)
        ?.apartmentId;
    final items = widget.controller
        .bookingsForResident(widget.user.id)
        .where((item) => item.apartmentId == apartmentId)
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: _sectionSelector(),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const SizedBox(
              height: 420,
              child: EmptyView(
                title: 'Chưa có lượt đặt',
                message: 'Hãy chọn một tiện ích để đặt khung giờ.',
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AmenityBookingCard(
                  booking: item,
                  onCancel: item.status.canCancelByResident
                      ? () => _cancel(item)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionSelector() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
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
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.grid_view_outlined),
            label: Text('Khám phá tiện ích'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.event_note_outlined),
            label: Text('Lượt đặt của tôi'),
          ),
        ],
        selected: {_showBookings},
        onSelectionChanged: (value) =>
            setState(() => _showBookings = value.first),
      ),
    );
  }

  Future<void> _openBooking(Amenity amenity, String apartmentId) async {
    final draft = await showDialog<_BookingDraft>(
      context: context,
      builder: (_) => _AmenityBookingDialog(amenity: amenity),
    );
    if (draft == null || !mounted) return;
    final success = await widget.controller.createBooking(
      amenityId: amenity.id,
      apartmentId: apartmentId,
      residentId: widget.user.id,
      residentName: widget.user.fullName,
      startAt: draft.startAt,
      attendeeCount: draft.attendees,
      note: draft.note,
    );
    if (!mounted) return;
    setState(() {
      if (success) _showBookings = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã gửi lượt đặt ${amenity.name}.'
              : widget.controller.errorMessage ?? 'Không thể gửi lượt đặt.',
        ),
      ),
    );
  }

  Future<void> _cancel(AmenityBooking booking) async {
    final success = await widget.controller.cancelBooking(booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã hủy lượt đặt.'
              : widget.controller.errorMessage ?? 'Không thể hủy.',
        ),
      ),
    );
  }
}

class _BookingDraft {
  const _BookingDraft(this.startAt, this.attendees, this.note);
  final DateTime startAt;
  final int attendees;
  final String note;
}

class _AmenityBookingDialog extends StatefulWidget {
  const _AmenityBookingDialog({required this.amenity});
  final Amenity amenity;
  @override
  State<_AmenityBookingDialog> createState() => _AmenityBookingDialogState();
}

class _AmenityBookingDialogState extends State<_AmenityBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _attendees = TextEditingController(text: '1');
  final _note = TextEditingController();
  late DateTime _start;
  @override
  void initState() {
    super.initState();
    final tomorrow = DateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 1));
    _start = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      widget.amenity.openingHour < 9 ? 9 : widget.amenity.openingHour,
    );
  }

  @override
  void dispose() {
    _attendees.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Đặt ${widget.amenity.name}'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.amenity.slotDurationMinutes} phút · tối đa ${widget.amenity.capacity} người',
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Thời gian bắt đầu'),
              subtitle: Text(amenityDateTime(_start)),
              onTap: _pickDateTime,
            ),
            TextFormField(
              controller: _attendees,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số người tham gia',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              validator: (value) {
                final amount = int.tryParse(value ?? '');
                if (amount == null ||
                    amount < 1 ||
                    amount > widget.amenity.capacity) {
                  return 'Nhập từ 1 đến ${widget.amenity.capacity} người.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Để sau'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Gửi lượt đặt')),
    ],
  );
  Future<void> _pickDateTime() async {
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
    if (time == null || !mounted) return;
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _BookingDraft(_start, int.parse(_attendees.text), _note.text.trim()),
    );
  }
}
