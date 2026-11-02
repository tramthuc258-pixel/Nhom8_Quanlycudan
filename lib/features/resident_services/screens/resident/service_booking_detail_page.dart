import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_booking_update.dart';
import 'package:homie/core/widgets/confirm_dialog.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/invoices/screens/resident/invoice_detail_page.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

import '../../controllers/service_controller.dart';
import '../../widgets/resident/resident_service_widgets.dart';

class ServiceBookingDetailPage extends StatelessWidget {
  const ServiceBookingDetailPage({
    required this.controller,
    required this.apartmentMembershipController,
    required this.user,
    required this.bookingId,
    this.invoiceController,
    super.key,
  });

  final ServiceController controller;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  final String bookingId;
  final InvoiceController? invoiceController;

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Chi tiết dịch vụ',
      subtitle: 'Lịch hẹn và tiến độ thực hiện',
      icon: Icons.room_service_outlined,
      accentColor: AppColors.service,
      accentSoftColor: AppColors.serviceSoft,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final booking = controller.bookingById(bookingId);
          if (booking == null || booking.residentId != user.id) {
            return const EmptyView(
              icon: Icons.search_off_rounded,
              title: 'Không tìm thấy đăng ký',
              message:
                  'Đăng ký không tồn tại hoặc bạn không có quyền truy cập.',
            );
          }
          final service = controller.serviceById(booking.serviceId);
          final apartment = apartmentMembershipController.apartmentById(
            booking.apartmentId,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: AppColors.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        booking.serviceName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ServiceBookingStatusBadge(
                                  status: booking.status,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            _DetailRow(
                              icon: Icons.apartment_rounded,
                              label: 'Căn hộ',
                              value: apartment?.code ?? '—',
                            ),
                            _DetailRow(
                              icon: Icons.event_outlined,
                              label: 'Thời gian mong muốn',
                              value: formatServiceDateTime(booking.scheduledAt),
                            ),
                            _DetailRow(
                              icon: Icons.numbers_rounded,
                              label: 'Số lượng',
                              value:
                                  '${booking.quantity} ${service?.unitLabel ?? ''}'
                                      .trim(),
                            ),
                            _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Đơn giá',
                              value: formatServiceMoney(booking.unitPrice),
                            ),
                            _DetailRow(
                              icon: Icons.account_balance_wallet_outlined,
                              label:
                                  booking.status ==
                                      ServiceBookingStatus.completed
                                  ? 'Giá trị dịch vụ'
                                  : 'Tổng dự kiến',
                              value: formatServiceMoney(booking.totalAmount),
                              emphasized: true,
                            ),
                            if (booking.status ==
                                ServiceBookingStatus.completed) ...[
                              const SizedBox(height: 12),
                              if (booking.invoiceId != null &&
                                  invoiceController != null)
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context)
                                      .push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => InvoiceDetailPage(
                                            invoiceController:
                                                invoiceController!,
                                            apartmentMembershipController:
                                                apartmentMembershipController,
                                            user: user,
                                            invoiceId: booking.invoiceId!,
                                          ),
                                        ),
                                      ),
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: Text(
                                    'Xem hóa đơn ${booking.invoiceCode ?? ''}',
                                  ),
                                )
                              else
                                Text(
                                  booking.unitPrice == 0
                                      ? 'Dịch vụ miễn phí, không cần thanh toán.'
                                      : 'Khoản dịch vụ đang chờ kế toán đưa vào hóa đơn tháng.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                            _DetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Người đăng ký',
                              value: booking.residentName,
                            ),
                            _DetailRow(
                              icon: Icons.engineering_outlined,
                              label: 'Người phụ trách',
                              value: booking.assignedTo ?? 'Chưa phân công',
                            ),
                            if (booking.note.trim().isNotEmpty)
                              _NoteBox(
                                title: 'Ghi chú của bạn',
                                message: booking.note,
                                icon: Icons.notes_rounded,
                              ),
                            if ((booking.managementNote ?? '')
                                .trim()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _NoteBox(
                                  title: 'Phản hồi từ ban quản lý',
                                  message: booking.managementNote!,
                                  icon: Icons.support_agent_rounded,
                                  highlighted: true,
                                ),
                              ),
                            if (booking.status.canCancelByResident) ...[
                              const SizedBox(height: 18),
                              AppButton(
                                label: 'Hủy đăng ký',
                                icon: Icons.close_rounded,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _cancel(context),
                              ),
                            ],
                            if (booking.status ==
                                ServiceBookingStatus.waitingResident) ...[
                              const SizedBox(height: 18),
                              _ResidentResultActions(
                                loading: controller.isLoading,
                                onConfirm: () => _confirmResult(context),
                                onReopen: () => _reopenResult(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _BookingProgress(status: booking.status),
                      ),
                    ),
                    if (booking.history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _ServiceHistory(history: booking.history),
                        ),
                      ),
                    ],
                    if (service != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đơn vị cung cấp',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 14),
                              _DetailRow(
                                icon: Icons.storefront_outlined,
                                label: 'Đơn vị',
                                value: service.providerName,
                              ),
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                label: 'Liên hệ',
                                value: service.contactPhone,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hủy đăng ký dịch vụ?',
      message:
          'Đăng ký đang chờ xác nhận sẽ được chuyển sang trạng thái đã hủy.',
      confirmLabel: 'Hủy đăng ký',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final success = await controller.cancelBooking(bookingId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã hủy đăng ký dịch vụ.'
              : controller.errorMessage ?? 'Không thể hủy đăng ký.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmResult(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xác nhận dịch vụ hoàn tất?',
      message:
          'Sau khi xác nhận, yêu cầu sẽ được đóng và ghi nhận là hoàn thành.',
      confirmLabel: 'Đã hoàn tất',
    );
    if (!confirmed || !context.mounted) return;
    await _submitResult(context, confirmed: true);
  }

  Future<void> _reopenResult(BuildContext context) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yêu cầu xử lý lại'),
        content: TextField(
          controller: noteController,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Nội dung chưa hoàn tất',
            hintText: 'Mô tả rõ phần cần nhân viên xử lý lại…',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              final value = noteController.text.trim();
              if (value.length >= 5) Navigator.pop(dialogContext, value);
            },
            child: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !context.mounted) return;
    await _submitResult(context, confirmed: false, note: note);
  }

  Future<void> _submitResult(
    BuildContext context, {
    required bool confirmed,
    String note = '',
  }) async {
    final success = await controller.respondToResult(
      bookingId: bookingId,
      confirmed: confirmed,
      note: note,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? confirmed
                    ? 'Đã xác nhận dịch vụ hoàn tất.'
                    : 'Đã gửi yêu cầu xử lý lại.'
              : controller.errorMessage ?? 'Không thể gửi phản hồi.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ResidentResultActions extends StatelessWidget {
  const _ResidentResultActions({
    required this.loading,
    required this.onConfirm,
    required this.onReopen,
  });

  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nhân viên đã gửi kết quả',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text('Vui lòng kiểm tra thực tế trước khi xác nhận hoàn tất.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: loading ? null : onReopen,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Cần xử lý lại'),
              ),
              FilledButton.icon(
                onPressed: loading ? null : onConfirm,
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Xác nhận hoàn tất'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: emphasized ? AppColors.primary : null,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.title,
    required this.message,
    required this.icon,
    this.highlighted = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.infoContainer : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: highlighted ? AppColors.info : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingProgress extends StatelessWidget {
  const _BookingProgress({required this.status});

  final ServiceBookingStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == ServiceBookingStatus.cancelled) {
      return const Row(
        children: [
          Icon(Icons.block_rounded, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đăng ký đã được hủy và sẽ không tiếp tục xử lý.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    const steps = [
      ServiceBookingStatus.pending,
      ServiceBookingStatus.confirmed,
      ServiceBookingStatus.inProgress,
      ServiceBookingStatus.waitingResident,
      ServiceBookingStatus.completed,
    ];
    final activeIndex = steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ thực hiện',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < steps.length; index++)
          _ProgressStep(
            status: steps[index],
            complete: index <= activeIndex,
            isLast: index == steps.length - 1,
          ),
      ],
    );
  }
}

class _ServiceHistory extends StatelessWidget {
  const _ServiceHistory({required this.history});

  final List<ServiceBookingUpdate> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử xử lý',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < history.length; index++)
          _HistoryEntry(
            update: history[index],
            isLast: index == history.length - 1,
          ),
      ],
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.update, required this.isLast});

  final ServiceBookingUpdate update;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${update.actorName} · ${formatServiceDateTime(update.createdAt)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (update.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(update.note),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.status,
    required this.complete,
    required this.isLast,
  });

  final ServiceBookingStatus status;
  final bool complete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: complete
                        ? AppColors.primaryLight
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    complete ? Icons.check_rounded : Icons.circle_outlined,
                    size: 16,
                    color: complete
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: complete
                          ? AppColors.primaryLight
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 3),
              child: Text(
                status.label,
                style: TextStyle(
                  color: complete
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                  fontWeight: complete ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
