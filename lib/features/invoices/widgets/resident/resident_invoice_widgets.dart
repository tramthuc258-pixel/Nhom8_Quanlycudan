import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/core/widgets/status_badge.dart';

String formatInvoiceMoney(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}${buffer.toString()} đ';
}

String formatInvoiceDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String formatInvoiceMonth(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return 'Tháng $month/${value.year}';
}

String formatInvoiceQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class ResidentInvoiceStatusBadge extends StatelessWidget {
  const ResidentInvoiceStatusBadge({
    required this.status,
    this.isPendingConfirmation = false,
    this.isPendingVnpay = false,
    super.key,
  });

  final InvoiceStatus status;
  final bool isPendingConfirmation;
  final bool isPendingVnpay;

  @override
  Widget build(BuildContext context) {
    if (isPendingConfirmation) {
      return const StatusBadge(
        label: 'Chờ xác nhận',
        tone: StatusBadgeTone.warning,
        icon: Icons.hourglass_top_rounded,
        compact: true,
      );
    }
    if (isPendingVnpay) {
      return const StatusBadge(
        label: 'Đang xử lý VNPay',
        tone: StatusBadgeTone.info,
        icon: Icons.hourglass_top_rounded,
        compact: true,
      );
    }
    final (tone, icon) = switch (status) {
      InvoiceStatus.draft => (StatusBadgeTone.neutral, Icons.edit_note_rounded),
      InvoiceStatus.unpaid => (StatusBadgeTone.warning, Icons.schedule_rounded),
      InvoiceStatus.overdue => (
        StatusBadgeTone.danger,
        Icons.warning_amber_rounded,
      ),
      InvoiceStatus.paid => (
        StatusBadgeTone.success,
        Icons.check_circle_outline_rounded,
      ),
      InvoiceStatus.cancelled => (StatusBadgeTone.neutral, Icons.block_rounded),
    };

    return StatusBadge(
      label: status.label,
      tone: tone,
      icon: icon,
      compact: true,
    );
  }
}

class ResidentInvoiceCard extends StatelessWidget {
  const ResidentInvoiceCard({
    required this.invoice,
    required this.apartment,
    required this.payerName,
    required this.onTap,
    super.key,
  });

  final Invoice invoice;
  final Apartment apartment;
  final String payerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = invoice.effectiveStatus;
    final isOutstanding = invoice.isOutstanding;
    final displayStatus = invoice.hasPendingBankTransfer
        ? 'Chờ kế toán xác nhận'
        : invoice.hasPendingVnpayPayment
        ? 'Đang xử lý VNPay'
        : status.label;

    return Semantics(
      button: true,
      label:
          'Hóa đơn ${invoice.code}, $displayStatus, ${formatInvoiceMoney(invoice.totalAmount)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isOutstanding
                            ? AppColors.warningContainer
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isOutstanding
                            ? Icons.receipt_long_rounded
                            : Icons.receipt_rounded,
                        color: isOutstanding
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatInvoiceMonth(invoice.billingMonth),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${invoice.code} · Căn ${apartment.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ResidentInvoiceStatusBadge(
                      status: status,
                      isPendingConfirmation: invoice.hasPendingBankTransfer,
                      isPendingVnpay: invoice.hasPendingVnpayPayment,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  formatInvoiceMoney(invoice.totalAmount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isOutstanding
                        ? AppColors.warning
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _InvoiceCardInfo(
                  icon: Icons.event_outlined,
                  label: status == InvoiceStatus.paid
                      ? 'Thanh toán: ${formatInvoiceDate(invoice.paidAt!)}'
                      : 'Hạn: ${formatInvoiceDate(invoice.dueDate)}',
                ),
                const SizedBox(height: 7),
                _InvoiceCardInfo(
                  icon: Icons.person_outline_rounded,
                  label: 'Người thanh toán: $payerName',
                ),
                const Spacer(),
                const Divider(height: 22),
                Row(
                  children: [
                    Text(
                      '${invoice.items.length} khoản phí',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Xem chi tiết',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
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
}

class _InvoiceCardInfo extends StatelessWidget {
  const _InvoiceCardInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
