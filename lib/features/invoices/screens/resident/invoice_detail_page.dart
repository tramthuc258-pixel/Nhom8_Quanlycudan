import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/models/payment_configuration.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/invoices/widgets/resident/resident_invoice_widgets.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/adaptive_modal.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/core/storage/file_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({
    required this.invoiceController,
    required this.apartmentMembershipController,
    required this.user,
    required this.invoiceId,
    this.fileUploadService,
    super.key,
  });

  final InvoiceController invoiceController;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  final String invoiceId;
  final FileUploadService? fileUploadService;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage>
    with WidgetsBindingObserver {
  bool _waitingForFirstLoad = true;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isPaying) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant InvoiceDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoiceId != widget.invoiceId ||
        oldWidget.invoiceController != widget.invoiceController ||
        oldWidget.apartmentMembershipController !=
            widget.apartmentMembershipController ||
        oldWidget.user.id != widget.user.id) {
      _waitingForFirstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    await Future.wait<void>([
      widget.apartmentMembershipController.load(),
      widget.invoiceController.load(),
      widget.invoiceController.loadPaymentConfiguration(),
    ]);
    if (!mounted) return;
    setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Chi tiết hóa đơn',
      subtitle: 'Khoản phí và thông tin thanh toán',
      icon: Icons.request_quote_outlined,
      accentColor: AppColors.billing,
      accentSoftColor: AppColors.billingSoft,
      actions: [
        ListenableBuilder(
          listenable: widget.invoiceController,
          builder: (context, _) => IconButton(
            tooltip: 'Tải lại hóa đơn',
            onPressed: widget.invoiceController.isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.invoiceController,
          widget.apartmentMembershipController,
        ]),
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final invoiceController = widget.invoiceController;
    final apartmentMembershipController = widget.apartmentMembershipController;
    final invoice = invoiceController.invoiceById(widget.invoiceId);
    final isInitiallyLoading =
        _waitingForFirstLoad ||
        (invoiceController.isLoading && invoice == null) ||
        (apartmentMembershipController.isLoading &&
            apartmentMembershipController.apartments.isEmpty);

    if (isInitiallyLoading) {
      return const LoadingView(message: 'Đang tải chi tiết hóa đơn…');
    }

    if (invoice == null) {
      if (invoiceController.errorMessage != null) {
        return ErrorView(
          title: 'Không thể tải hóa đơn',
          message: invoiceController.errorMessage,
          onRetry: _load,
        );
      }
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: 'Không tìm thấy hóa đơn',
        message: 'Hóa đơn có thể đã bị xóa hoặc không còn tồn tại.',
        actionLabel: 'Tải lại',
        onAction: _load,
      );
    }

    final membership = apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    final apartment = membership == null
        ? null
        : apartmentMembershipController.apartmentById(membership.apartmentId);
    final canAccess =
        apartment != null &&
        invoice.apartmentId == apartment.id &&
        invoice.payerResidentId == widget.user.id &&
        invoice.effectiveStatus != InvoiceStatus.draft;

    if (!canAccess) {
      return const ErrorView(
        title: 'Không có quyền xem hóa đơn',
        message: 'Hóa đơn này không thuộc căn hộ bạn đang cư trú hoặc chưa được phát hành.',
      );
    }

    final payer = apartmentMembershipController.residentById(
      invoice.payerResidentId,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (invoiceController.errorMessage != null) ...[
                  _InlineWarning(message: invoiceController.errorMessage!),
                  const SizedBox(height: 14),
                ],
                _InvoiceHeader(invoice: invoice, apartment: apartment),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      children: [
                        _InvoiceItemsCard(invoice: invoice),
                        const SizedBox(height: 16),
                        _InvoiceTimelineCard(invoice: invoice),
                      ],
                    );
                    final payment = Column(
                      children: [
                        _PaymentCard(
                          invoice: invoice,
                          payerName: payer?.fullName ?? 'Chưa xác định',
                          bankTransferEnabled:
                              invoiceController
                                  .paymentConfiguration
                                  ?.bankTransfer
                                  .enabled ==
                              true,
                          vnpayEnabled:
                              invoiceController
                                  .paymentConfiguration
                                  ?.vnpayEnabled ==
                              true,
                          isPaying: _isPaying,
                          onPay:
                              invoice.isOutstanding &&
                                  (!invoice.hasPendingPayment ||
                                      invoice.hasPendingVnpayPayment) &&
                                  !_isPaying
                              ? () => _pay(invoice, apartment)
                              : null,
                        ),
                        if (invoice.effectiveStatus == InvoiceStatus.paid) ...[
                          const SizedBox(height: 16),
                          _ReceiptCard(
                            invoice: invoice,
                            apartment: apartment,
                            payerName: payer?.fullName ?? 'Chưa xác định',
                          ),
                        ],
                      ],
                    );

                    if (constraints.maxWidth < 780) {
                      return Column(
                        children: [
                          details,
                          const SizedBox(height: 16),
                          payment,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: details),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: payment),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pay(Invoice invoice, Apartment apartment) async {
    if (_isPaying ||
        !invoice.isOutstanding ||
        (invoice.hasPendingPayment && !invoice.hasPendingVnpayPayment)) {
      return;
    }
    if (invoice.hasPendingVnpayPayment) {
      await _payWithVnpay(invoice);
      return;
    }
    final paymentConfiguration = widget.invoiceController.paymentConfiguration;
    final bankEnabled = paymentConfiguration?.bankTransfer.enabled == true;
    final vnpayEnabled = paymentConfiguration?.vnpayEnabled == true;
    final choice = await showModalBottomSheet<_PaymentChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Chọn phương thức thanh toán',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Hóa đơn ${invoice.code} · ${formatInvoiceMoney(invoice.totalAmount)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _PaymentChoiceTile(
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF0A63B7),
                title: 'Thanh toán trực tuyến qua VNPAY',
                subtitle: vnpayEnabled
                    ? 'Chọn ngân hàng hoặc quét mã trên cổng bảo mật.'
                    : 'Đang chờ VNPAY kích hoạt tài khoản merchant.',
                onTap: vnpayEnabled
                    ? () => Navigator.pop(context, _PaymentChoice.vnpay)
                    : null,
              ),
              const SizedBox(height: 10),
              _PaymentChoiceTile(
                icon: Icons.account_balance_rounded,
                color: AppColors.secondary,
                title: 'Chuyển khoản thủ công',
                subtitle: bankEnabled
                    ? 'Xem tài khoản nhận tiền và gửi biên lai để đối soát.'
                    : 'Ban quản lý chưa cấu hình tài khoản nhận tiền.',
                onTap: bankEnabled
                    ? () => Navigator.pop(context, _PaymentChoice.transfer)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == _PaymentChoice.vnpay) {
      await _payWithVnpay(invoice);
      return;
    }
    await _submitManualTransfer(invoice, apartment);
  }

  Future<void> _payWithVnpay(Invoice invoice) async {
    setState(() => _isPaying = true);
    final paymentUrl = await widget.invoiceController.createVnpayPayment(
      invoice.id,
    );
    if (!mounted) return;
    if (paymentUrl == null) {
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.invoiceController.errorMessage ??
                'Chưa thể khởi tạo thanh toán VNPAY.',
          ),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      Uri.parse(paymentUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    setState(() => _isPaying = false);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở cổng thanh toán VNPAY.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Hoàn tất thanh toán trên VNPAY. Homie sẽ mở lại hóa đơn khi có kết quả.',
        ),
      ),
    );
  }

  Future<void> _submitManualTransfer(
    Invoice invoice,
    Apartment apartment,
  ) async {
    if (_isPaying || invoice.hasPendingPayment) return;
    final bank = widget.invoiceController.paymentConfiguration?.bankTransfer;
    if (bank == null || !bank.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ban quản lý chưa cấu hình tài khoản nhận chuyển khoản.',
          ),
        ),
      );
      return;
    }
    final transferContent = bank.contentFor(
      invoiceCode: invoice.code,
      apartmentCode: apartment.code,
    );
    UploadedHomieFile? uploadedProof;
    bool isUploading = false;
    String? uploadError;
    final proofUrl = await showAdaptiveModal<String>(
      context,
      maxWidth: 520,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AdaptiveModalScaffold(
          title: 'Xác nhận chuyển khoản',
          subtitle: 'Tải biên lai để kế toán đối soát',
          icon: Icons.account_balance_rounded,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chuyển đúng số tiền và nội dung bên dưới, sau đó tải biên lai để kế toán đối soát.',
              ),
              const SizedBox(height: 16),
              _BankTransferDetails(
                bank: bank,
                amount: invoice.totalAmount,
                content: transferContent,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.fileUploadService == null || isUploading
                    ? null
                    : () async {
                        setDialogState(() {
                          isUploading = true;
                          uploadError = null;
                        });
                        try {
                          final file = await widget.fileUploadService!
                              .pickAndUpload(category: 'payment-proof');
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            uploadedProof = file ?? uploadedProof;
                            isUploading = false;
                          });
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            uploadError = _uploadMessage(error);
                            isUploading = false;
                          });
                        }
                      },
                icon: isUploading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  isUploading
                      ? 'Đang tải biên lai…'
                      : uploadedProof == null
                      ? 'Đính kèm ảnh/PDF biên lai'
                      : 'Chọn lại biên lai',
                ),
              ),
              if (uploadedProof != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        uploadedProof!.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
              if (uploadError != null) ...[
                const SizedBox(height: 8),
                Text(
                  uploadError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Biên lai là bắt buộc. Hỗ trợ JPG, PNG, WebP hoặc PDF tối đa 10 MB.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            AppButton(
              label: 'Hủy',
              variant: AppButtonVariant.text,
              onPressed: isUploading
                  ? null
                  : () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Gửi biên lai',
              icon: Icons.send_rounded,
              onPressed: isUploading || uploadedProof == null
                  ? null
                  : () => Navigator.pop(dialogContext, uploadedProof!.url),
            ),
          ],
        ),
      ),
    );
    if (proofUrl == null || !mounted) return;

    setState(() => _isPaying = true);
    final success = await widget.invoiceController.submitPayment(
      invoice.id,
      proofUrl: proofUrl,
    );
    if (!mounted) return;
    setState(() => _isPaying = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.invoiceController.errorMessage ??
                'Chưa thể gửi giao dịch. Vui lòng thử lại.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi biên lai. Vui lòng chờ kế toán xác nhận.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _uploadMessage(Object error) {
    final message = error.toString();
    return message
        .replaceFirst('Bad state: ', '')
        .replaceFirst('ApiException: ', '');
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.invoice, required this.apartment});

  final Invoice invoice;
  final Apartment apartment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResidentInvoiceStatusBadge(
                  status: invoice.effectiveStatus,
                  isPendingConfirmation: invoice.hasPendingBankTransfer,
                  isPendingVnpay: invoice.hasPendingVnpayPayment,
                ),
                const SizedBox(height: 13),
                Text(
                  formatInvoiceMonth(invoice.billingMonth),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${invoice.code} · Căn ${apartment.code} · ${apartment.buildingName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
            final amount = Column(
              crossAxisAlignment: constraints.maxWidth < 650
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatInvoiceMoney(invoice.totalAmount),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: invoice.isOutstanding
                        ? AppColors.warning
                        : AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [information, const Divider(height: 32), amount],
              );
            }
            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 24),
                amount,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceItemsCard extends StatelessWidget {
  const _InvoiceItemsCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết khoản phí',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${invoice.items.length} khoản phí trong kỳ thanh toán',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < invoice.items.length; index++) ...[
              _InvoiceItemRow(item: invoice.items[index]),
              if (index < invoice.items.length - 1) const Divider(height: 24),
            ],
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng cộng',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  formatInvoiceMoney(invoice.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceItemRow extends StatelessWidget {
  const _InvoiceItemRow({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final feeDescription = item.feeTypeDescription?.trim();
    final showManagementDetails =
        item.feeTypeCode == 'MANAGEMENT_FEE' &&
        feeDescription != null &&
        feeDescription.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.payments_outlined,
                size: 19,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatInvoiceQuantity(item.quantity)} × ${formatInvoiceMoney(item.unitPrice)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatInvoiceMoney(item.amount),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (showManagementDetails) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phí quản lý gồm những gì?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  feeDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (item.calculationDescription case final calculation?) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Cách tính: $calculation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.invoice,
    required this.payerName,
    required this.bankTransferEnabled,
    required this.vnpayEnabled,
    required this.isPaying,
    required this.onPay,
  });

  final Invoice invoice;
  final String payerName;
  final bool bankTransferEnabled;
  final bool vnpayEnabled;
  final bool isPaying;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final status = invoice.effectiveStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh toán',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Người chịu trách nhiệm',
              value: payerName,
            ),
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Hạn thanh toán',
              value: formatInvoiceDate(invoice.dueDate),
            ),
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.info_outline_rounded,
              label: 'Trạng thái',
              value: invoice.hasPendingBankTransfer
                  ? 'Chờ kế toán xác nhận'
                  : invoice.hasPendingVnpayPayment
                  ? 'Đang xử lý VNPay'
                  : status.label,
            ),
            const SizedBox(height: 20),
            if (invoice.isOutstanding) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color:
                      status == InvoiceStatus.overdue &&
                          !invoice.hasPendingPayment
                      ? AppColors.errorContainer
                      : AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  invoice.hasPendingPayment
                      ? invoice.hasPendingVnpayPayment
                            ? 'Phiên VNPAY đang chờ hoàn tất. Bạn có thể tiếp tục hoặc tạo lại phiên thanh toán.'
                            : 'Biên lai ${invoice.transactionCode ?? ''} đã được gửi và đang chờ kế toán xác nhận.'
                      : status == InvoiceStatus.overdue
                      ? 'Hóa đơn đã quá hạn. Vui lòng thanh toán sớm để tránh phát sinh nhắc nhở.'
                      : vnpayEnabled && bankTransferEnabled
                      ? 'Chọn thanh toán trực tuyến VNPAY hoặc chuyển khoản ngân hàng.'
                      : bankTransferEnabled
                      ? 'Chuyển khoản ngân hàng và tải biên lai để kế toán đối soát.'
                      : 'Phương thức thanh toán đang được ban quản lý cấu hình.',
                  style: TextStyle(
                    color:
                        status == InvoiceStatus.overdue &&
                            !invoice.hasPendingPayment
                        ? AppColors.error
                        : AppColors.warning,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: invoice.hasPendingPayment
                    ? invoice.hasPendingVnpayPayment
                          ? 'Tiếp tục thanh toán VNPAY'
                          : 'Đang chờ xác nhận'
                    : 'Thanh toán hóa đơn',
                icon: invoice.hasPendingPayment
                    ? invoice.hasPendingVnpayPayment
                          ? Icons.open_in_new_rounded
                          : Icons.hourglass_top_rounded
                    : Icons.payments_rounded,
                onPressed: onPay,
                isLoading: isPaying,
                expand: true,
              ),
            ] else
              _PaymentStateMessage(status: status),
          ],
        ),
      ),
    );
  }
}

enum _PaymentChoice { vnpay, transfer }

class _PaymentChoiceTile extends StatelessWidget {
  const _PaymentChoiceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: onTap == null
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : color.withValues(alpha: .07),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: onTap == null ? Theme.of(context).disabledColor : color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              onTap == null
                  ? Icons.lock_clock_outlined
                  : Icons.chevron_right_rounded,
              color: onTap == null ? Theme.of(context).disabledColor : null,
            ),
          ],
        ),
      ),
    ),
  );
}

class _BankTransferDetails extends StatelessWidget {
  const _BankTransferDetails({
    required this.bank,
    required this.amount,
    required this.content,
  });

  final BankTransferConfiguration bank;
  final double amount;
  final String content;

  @override
  Widget build(BuildContext context) {
    final qrImageUrl = bank.qrImageUrlFor(amount: amount, content: content);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.billingSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.billing.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.billing),
              SizedBox(width: 9),
              Text(
                'Thông tin nhận chuyển khoản',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _TransferField(label: 'Ngân hàng', value: bank.bankName),
          if (bank.branch != null)
            _TransferField(label: 'Chi nhánh', value: bank.branch!),
          _TransferField(
            label: 'Số tài khoản',
            value: bank.accountNumber,
            copyable: true,
          ),
          _TransferField(label: 'Chủ tài khoản', value: bank.accountName),
          _TransferField(
            label: 'Số tiền',
            value: formatInvoiceMoney(amount),
            copyable: true,
          ),
          _TransferField(
            label: 'Nội dung chuyển khoản',
            value: content,
            copyable: true,
            emphasized: true,
          ),
          if (qrImageUrl != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrImageUrl,
                      width: 220,
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quét QR để tự điền số tiền và nội dung chuyển khoản.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferField extends StatelessWidget {
  const _TransferField({
    required this.label,
    required this.value,
    this.copyable = false,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              color: emphasized ? AppColors.billing : AppColors.textPrimary,
            ),
          ),
        ),
        if (copyable)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Sao chép $label',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép $label.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
      ],
    ),
  );
}

class _PaymentStateMessage extends StatelessWidget {
  const _PaymentStateMessage({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, foreground, background, text) = switch (status) {
      InvoiceStatus.paid => (
        Icons.verified_rounded,
        AppColors.success,
        AppColors.successContainer,
        'Hóa đơn đã được thanh toán. Biên nhận được hiển thị bên dưới.',
      ),
      InvoiceStatus.cancelled => (
        Icons.block_rounded,
        AppColors.textSecondary,
        AppColors.surfaceMuted,
        'Hóa đơn đã bị hủy và không thể thanh toán.',
      ),
      _ => (
        Icons.info_outline_rounded,
        AppColors.textSecondary,
        AppColors.surfaceMuted,
        'Hóa đơn không thể thanh toán ở trạng thái hiện tại.',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTimelineCard extends StatelessWidget {
  const _InvoiceTimelineCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mốc thời gian',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            _TimelineEntry(
              icon: Icons.post_add_rounded,
              title: 'Phát hành hóa đơn',
              value: formatInvoiceDate(invoice.issuedAt),
              isComplete: true,
            ),
            _TimelineEntry(
              icon: Icons.event_rounded,
              title: 'Hạn thanh toán',
              value: formatInvoiceDate(invoice.dueDate),
              isComplete: !invoice.dueDate.isAfter(DateTime.now()),
              isLast:
                  invoice.paymentSubmittedAt == null && invoice.paidAt == null,
            ),
            if (invoice.paymentSubmittedAt != null)
              _TimelineEntry(
                icon: invoice.paymentMethod == 'vnpay'
                    ? Icons.open_in_browser_rounded
                    : Icons.cloud_done_outlined,
                title: invoice.paymentMethod == 'vnpay'
                    ? 'Bắt đầu thanh toán VNPay'
                    : 'Đã gửi biên lai',
                value: _formatInvoiceDateTime(invoice.paymentSubmittedAt!),
                isComplete: true,
                isLast: invoice.paidAt == null,
              ),
            if (invoice.paidAt != null)
              _TimelineEntry(
                icon: Icons.task_alt_rounded,
                title: 'Đã thanh toán',
                value: formatInvoiceDate(invoice.paidAt!),
                isComplete: true,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }
}

String _formatInvoiceDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute · ${formatInvoiceDate(value)}';
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.icon,
    required this.title,
    required this.value,
    required this.isComplete,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isComplete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? AppColors.primary : AppColors.textDisabled;
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
                    color: isComplete
                        ? AppColors.primaryLight
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.invoice,
    required this.apartment,
    required this.payerName,
  });

  final Invoice invoice;
  final Apartment apartment;
  final String payerName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biên nhận thanh toán',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        invoice.paymentMethod == 'vnpay'
                            ? 'Giao dịch đã được VNPay xác nhận'
                            : 'Biên lai đã được kế toán đối soát',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _ReceiptRow(label: 'Hóa đơn', value: invoice.code),
            _ReceiptRow(label: 'Căn hộ', value: apartment.code),
            _ReceiptRow(label: 'Người thanh toán', value: payerName),
            _ReceiptRow(
              label: 'Thời gian',
              value: invoice.paidAt == null
                  ? '—'
                  : formatInvoiceDate(invoice.paidAt!),
            ),
            const Divider(height: 24),
            _ReceiptRow(
              label: 'Số tiền',
              value: formatInvoiceMoney(invoice.totalAmount),
              emphasized: true,
            ),
            const SizedBox(height: 10),
            Text(
              'Mã hồ sơ thanh toán',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                invoice.transactionCode ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
