import 'package:flutter/material.dart';

import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/core/widgets/status_badge.dart';

class InvoiceManagementOverview extends StatelessWidget {
  const InvoiceManagementOverview({required this.invoices, super.key});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    final debt = invoices
        .where((invoice) => invoice.effectiveStatus.isOutstanding)
        .fold<double>(0, (sum, invoice) => sum + invoice.totalAmount);
    final collected = invoices
        .where((invoice) => invoice.effectiveStatus == InvoiceStatus.paid)
        .fold<double>(0, (sum, invoice) => sum + invoice.totalAmount);
    final overdue = invoices
        .where(
          (invoice) =>
              invoice.effectiveStatus == InvoiceStatus.overdue &&
              !invoice.hasPendingBankTransfer,
        )
        .length;

    final items = <_OverviewItem>[
      _OverviewItem(
        label: 'Tổng hóa đơn',
        value: '${invoices.length}',
        icon: Icons.receipt_long_outlined,
        tone: _OverviewTone.primary,
      ),
      _OverviewItem(
        label: 'Công nợ hiện tại',
        value: formatVnd(debt),
        icon: Icons.account_balance_wallet_outlined,
        tone: _OverviewTone.warning,
      ),
      _OverviewItem(
        label: 'Đã thu',
        value: formatVnd(collected),
        icon: Icons.payments_outlined,
        tone: _OverviewTone.success,
      ),
      _OverviewItem(
        label: 'Quá hạn',
        value: '$overdue hóa đơn',
        icon: Icons.event_busy_outlined,
        tone: _OverviewTone.danger,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960 ? 4 : 2;
          final ratio = constraints.maxWidth < 370
              ? 1.15
              : constraints.maxWidth < 700
              ? 1.38
              : 1.8;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: ratio,
            ),
            itemBuilder: (context, index) => _OverviewCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class InvoiceManagementCard extends StatelessWidget {
  const InvoiceManagementCard({
    required this.invoice,
    required this.apartment,
    required this.payer,
    required this.onView,
    required this.onPublish,
    required this.onRecordPayment,
    required this.onRejectPayment,
    required this.onCancel,
    required this.canOperate,
    this.busy = false,
    this.compact = false,
    super.key,
  });

  final Invoice invoice;
  final Apartment? apartment;
  final Resident? payer;
  final VoidCallback onView;
  final VoidCallback onPublish;
  final VoidCallback onRecordPayment;
  final VoidCallback onRejectPayment;
  final VoidCallback onCancel;
  final bool canOperate;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = invoice.effectiveStatus;

    return Card(
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: invoiceStatusColor(
                        status,
                        colors,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: invoiceStatusColor(status, colors),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          apartment == null
                              ? 'Căn hộ không xác định'
                              : '${apartment!.code} · ${apartment!.buildingName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_InvoiceAction>(
                    tooltip: 'Thao tác hóa đơn',
                    enabled: !busy,
                    onSelected: (action) {
                      switch (action) {
                        case _InvoiceAction.view:
                          onView();
                        case _InvoiceAction.publish:
                          onPublish();
                        case _InvoiceAction.payment:
                          onRecordPayment();
                        case _InvoiceAction.rejectPayment:
                          onRejectPayment();
                        case _InvoiceAction.cancel:
                          onCancel();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _InvoiceAction.view,
                        child: _MenuLabel(
                          icon: Icons.visibility_outlined,
                          label: 'Xem chi tiết',
                        ),
                      ),
                      if (canOperate && status == InvoiceStatus.draft)
                        const PopupMenuItem(
                          value: _InvoiceAction.publish,
                          child: _MenuLabel(
                            icon: Icons.send_outlined,
                            label: 'Phát hành',
                          ),
                        ),
                      if (canOperate &&
                          status.isOutstanding &&
                          invoice.hasPendingBankTransfer)
                        const PopupMenuItem(
                          value: _InvoiceAction.payment,
                          child: _MenuLabel(
                            icon: Icons.price_check_rounded,
                            label: 'Xác nhận thanh toán',
                          ),
                        ),
                      if (canOperate &&
                          status.isOutstanding &&
                          invoice.hasPendingBankTransfer)
                        const PopupMenuItem(
                          value: _InvoiceAction.rejectPayment,
                          child: _MenuLabel(
                            icon: Icons.block_rounded,
                            label: 'Từ chối giao dịch',
                            destructive: true,
                          ),
                        ),
                      if (canOperate &&
                          (status == InvoiceStatus.draft ||
                              status.isOutstanding))
                        const PopupMenuDivider(),
                      if (canOperate &&
                          (status == InvoiceStatus.draft ||
                              status.isOutstanding))
                        const PopupMenuItem(
                          value: _InvoiceAction.cancel,
                          child: _MenuLabel(
                            icon: Icons.cancel_outlined,
                            label: 'Hủy hóa đơn',
                            destructive: true,
                          ),
                        ),
                    ],
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InvoiceStatusBadge(
                    status: status,
                    isPendingConfirmation: invoice.hasPendingBankTransfer,
                  ),
                  StatusBadge(
                    label: 'Kỳ ${formatMonth(invoice.billingMonth)}',
                    tone: StatusBadgeTone.info,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                formatVnd(invoice.totalAmount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${invoice.items.length} khoản phí',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (compact) const SizedBox(height: 12) else const Spacer(),
              const Divider(height: 24),
              _InfoLine(
                icon: Icons.person_outline_rounded,
                text: payer?.fullName ?? 'Chưa xác định người thanh toán',
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.event_outlined,
                text: 'Hạn ${formatDate(invoice.dueDate)}',
                color: status == InvoiceStatus.overdue ? colors.error : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Chi tiết'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge({
    required this.status,
    this.isPendingConfirmation = false,
    super.key,
  });

  final InvoiceStatus status;
  final bool isPendingConfirmation;

  @override
  Widget build(BuildContext context) {
    if (isPendingConfirmation) {
      return const StatusBadge(
        label: 'Chờ xác nhận',
        tone: StatusBadgeTone.warning,
        icon: Icons.hourglass_top_rounded,
      );
    }
    return StatusBadge(
      label: invoiceStatusLabel(status),
      tone: switch (status) {
        InvoiceStatus.draft => StatusBadgeTone.neutral,
        InvoiceStatus.unpaid => StatusBadgeTone.warning,
        InvoiceStatus.paid => StatusBadgeTone.success,
        InvoiceStatus.cancelled => StatusBadgeTone.neutral,
        InvoiceStatus.overdue => StatusBadgeTone.danger,
      },
    );
  }
}

Future<void> showInvoiceManagementDetailDialog(
  BuildContext context, {
  required Invoice invoice,
  required Apartment? apartment,
  required Resident? payer,
  required bool canOperate,
  required VoidCallback onPublish,
  required VoidCallback onRecordPayment,
  required VoidCallback onRejectPayment,
  required VoidCallback onCancel,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _InvoiceDetailDialog(
      invoice: invoice,
      apartment: apartment,
      payer: payer,
      canOperate: canOperate,
      onPublish: onPublish,
      onRecordPayment: onRecordPayment,
      onRejectPayment: onRejectPayment,
      onCancel: onCancel,
    ),
  );
}

class _InvoiceDetailDialog extends StatelessWidget {
  const _InvoiceDetailDialog({
    required this.invoice,
    required this.apartment,
    required this.payer,
    required this.canOperate,
    required this.onPublish,
    required this.onRecordPayment,
    required this.onRejectPayment,
    required this.onCancel,
  });

  final Invoice invoice;
  final Apartment? apartment;
  final Resident? payer;
  final bool canOperate;
  final VoidCallback onPublish;
  final VoidCallback onRecordPayment;
  final VoidCallback onRejectPayment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = Theme.of(context).colorScheme;
    final status = invoice.effectiveStatus;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 18),
              color: colors.primaryContainer.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.code,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Hóa đơn kỳ ${formatMonth(invoice.billingMonth)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InvoiceStatusBadge(
                          status: status,
                          isPendingConfirmation: invoice.hasPendingBankTransfer,
                        ),
                        StatusBadge(
                          label: apartment?.code ?? 'Không rõ căn hộ',
                          tone: StatusBadgeTone.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DetailSummary(
                      invoice: invoice,
                      apartment: apartment,
                      payer: payer,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Chi tiết các khoản phí',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < invoice.items.length;
                            index++
                          ) ...[
                            _InvoiceItemRow(item: invoice.items[index]),
                            if (index != invoice.items.length - 1)
                              const Divider(),
                          ],
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tổng thanh toán',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Text(
                                  formatVnd(invoice.totalAmount),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (invoice.paidAt != null ||
                        invoice.transactionCode != null) ...[
                      const SizedBox(height: 22),
                      _PaymentReceipt(invoice: invoice),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  if (canOperate && status == InvoiceStatus.draft)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPublish();
                      },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Phát hành'),
                    ),
                  if (canOperate &&
                      status.isOutstanding &&
                      invoice.hasPendingBankTransfer)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRecordPayment();
                      },
                      icon: const Icon(Icons.price_check_rounded),
                      label: const Text('Xác nhận giao dịch'),
                    ),
                  if (canOperate &&
                      status.isOutstanding &&
                      invoice.hasPendingBankTransfer) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRejectPayment();
                      },
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Từ chối'),
                    ),
                  ],
                  if (canOperate &&
                      (status == InvoiceStatus.draft ||
                          status.isOutstanding)) ...[
                    IconButton(
                      tooltip: 'Hủy hóa đơn',
                      color: colors.error,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel();
                      },
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSummary extends StatelessWidget {
  const _DetailSummary({
    required this.invoice,
    required this.apartment,
    required this.payer,
  });

  final Invoice invoice;
  final Apartment? apartment;
  final Resident? payer;

  @override
  Widget build(BuildContext context) {
    final values = <({IconData icon, String label, String value})>[
      (
        icon: Icons.apartment_rounded,
        label: 'Căn hộ',
        value: apartment == null
            ? 'Không xác định'
            : '${apartment!.code} · ${apartment!.buildingName}',
      ),
      (
        icon: Icons.person_outline_rounded,
        label: 'Người thanh toán',
        value: payer?.fullName ?? 'Không xác định',
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: 'Kỳ hóa đơn',
        value: formatMonth(invoice.billingMonth),
      ),
      (
        icon: Icons.event_available_outlined,
        label: 'Ngày phát hành',
        value: invoice.publishedAt == null
            ? 'Chưa phát hành'
            : formatDateTime(invoice.publishedAt!),
      ),
      (
        icon: Icons.event_busy_outlined,
        label: 'Hạn thanh toán',
        value: formatDate(invoice.dueDate),
      ),
      (
        icon: Icons.edit_note_rounded,
        label: 'Người tạo',
        value: invoice.createdByName ?? 'Không xác định',
      ),
      (
        icon: Icons.verified_user_outlined,
        label: 'Người phát hành',
        value: invoice.publishedByName ?? 'Chưa phát hành',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in values)
              SizedBox(
                width: width,
                child: _SummaryTile(
                  icon: item.icon,
                  label: item.label,
                  value: item.value,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InvoiceItemRow extends StatelessWidget {
  const _InvoiceItemRow({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatQuantity(item.quantity)} × ${formatVnd(item.unitPrice)}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 3),
                Text(
                  item.calculationDescription ??
                      (item.source == 'catalog'
                          ? 'Theo danh mục phí ${item.feeTypeCode ?? ''}'.trim()
                          : 'Khoản phí nhập thủ công'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatVnd(item.amount),
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PaymentReceipt extends StatelessWidget {
  const _PaymentReceipt({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              invoice.hasPendingBankTransfer
                  ? Icons.hourglass_top_rounded
                  : Icons.verified_rounded,
              color: colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.hasPendingBankTransfer
                        ? 'Chờ kế toán đối soát'
                        : invoice.hasPendingVnpayPayment
                        ? 'Đang chờ VNPAY phản hồi'
                        : 'Đã ghi nhận thanh toán',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (invoice.paymentSubmittedAt != null &&
                      invoice.hasPendingBankTransfer) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Cư dân gửi lúc: '
                      '${formatDateTime(invoice.paymentSubmittedAt!)}',
                    ),
                  ],
                  if (invoice.paidAt != null) ...[
                    const SizedBox(height: 5),
                    Text('Thời gian: ${formatDateTime(invoice.paidAt!)}'),
                  ],
                  if (invoice.transactionCode != null) ...[
                    const SizedBox(height: 3),
                    SelectableText('Mã hồ sơ: ${invoice.transactionCode}'),
                  ],
                  if (invoice.paymentProofUrl != null &&
                      invoice.paymentProofUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PaymentProofPreview(url: invoice.paymentProofUrl!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProofPreview extends StatelessWidget {
  const _PaymentProofPreview({required this.url});

  final String url;

  bool get _isPdf =>
      Uri.tryParse(url)?.path.toLowerCase().endsWith('.pdf') ?? false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isPdf) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  'Biên lai PDF đã đính kèm',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.primary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh biên lai',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              insetPadding: const EdgeInsets.all(18),
              child: Stack(
                children: [
                  InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 420,
                        height: 240,
                        child: Center(
                          child: Text('Không thể tải ảnh biên lai.'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                color: colors.surfaceContainerLowest,
                alignment: Alignment.center,
                child: const Text('Không thể tải ảnh biên lai.'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nhấn vào ảnh để phóng to trước khi xác nhận.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});

  final _OverviewItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (item.tone) {
      _OverviewTone.primary => colors.primary,
      _OverviewTone.success => const Color(0xFF15803D),
      _OverviewTone.warning => const Color(0xFFB45309),
      _OverviewTone.danger => colors.error,
    };
    final value = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        item.value,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
    final label = Text(
      item.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: colors.onSurfaceVariant),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 220;
            final icon = Container(
              width: compact ? 36 : 44,
              height: compact ? 36 : 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: color),
            );
            if (compact) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: value),
                  const SizedBox(height: 3),
                  label,
                ],
              );
            }
            return Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [value, const SizedBox(height: 3), label],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 17, color: effectiveColor),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: effectiveColor),
          ),
        ),
      ],
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

enum _InvoiceAction { view, publish, payment, rejectPayment, cancel }

enum _OverviewTone { primary, success, warning, danger }

class _OverviewItem {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final _OverviewTone tone;
}

String invoiceStatusLabel(InvoiceStatus status) => switch (status) {
  InvoiceStatus.draft => 'Bản nháp',
  InvoiceStatus.unpaid => 'Chưa thanh toán',
  InvoiceStatus.paid => 'Đã thanh toán',
  InvoiceStatus.cancelled => 'Đã hủy',
  InvoiceStatus.overdue => 'Quá hạn',
};

Color invoiceStatusColor(InvoiceStatus status, ColorScheme colors) {
  return switch (status) {
    InvoiceStatus.draft => colors.onSurfaceVariant,
    InvoiceStatus.unpaid => const Color(0xFFB45309),
    InvoiceStatus.paid => const Color(0xFF15803D),
    InvoiceStatus.cancelled => colors.onSurfaceVariant,
    InvoiceStatus.overdue => colors.error,
  };
}

String formatVnd(double amount) {
  final rounded = amount.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}${buffer.toString()} đ';
}

String formatQuantity(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
}

String formatDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}

String formatMonth(DateTime value) {
  return '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)} · ${formatDate(value)}';
}
