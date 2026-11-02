import 'package:flutter/material.dart';

import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/invoices/widgets/management/invoice_editor_dialog.dart';
import 'package:homie/features/invoices/widgets/management/invoice_management_widgets.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/core/widgets/confirm_dialog.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';

class InvoiceManagementPage extends StatefulWidget {
  const InvoiceManagementPage({
    required this.invoiceController,
    required this.apartmentMembershipController,
    required this.canOperate,
    super.key,
  });

  final InvoiceController invoiceController;
  final ApartmentMembershipController apartmentMembershipController;
  final bool canOperate;

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage> {
  final _searchController = TextEditingController();
  final Set<String> _busyInvoiceIds = <String>{};
  late final Listenable _controllers;

  InvoiceStatus? _statusFilter;
  String? _monthFilter;
  bool _pendingReceiptsOnly = false;

  @override
  void initState() {
    super.initState();
    _controllers = Listenable.merge([
      widget.invoiceController,
      widget.apartmentMembershipController,
    ]);
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadInitialData() async {
    final futures = <Future<void>>[];
    if (widget.invoiceController.invoices.isEmpty &&
        !widget.invoiceController.isLoading) {
      futures.add(widget.invoiceController.load());
    }
    if (widget.invoiceController.feeTypes.isEmpty) {
      futures.add(widget.invoiceController.loadFeeTypes());
    }
    if ((widget.apartmentMembershipController.apartments.isEmpty ||
            widget.apartmentMembershipController.residents.isEmpty) &&
        !widget.apartmentMembershipController.isLoading) {
      futures.add(widget.apartmentMembershipController.load());
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  Future<void> _reload() async {
    await Future.wait([
      widget.invoiceController.load(),
      widget.apartmentMembershipController.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn và công nợ'),
        actions: [
          if (compact && widget.canOperate)
            IconButton(
              tooltip: 'Tạo hóa đơn',
              onPressed: _isBusy ? null : _createInvoice,
              icon: const Icon(Icons.post_add_rounded),
            ),
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _isBusy ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _controllers,
          builder: (context, _) {
            if (_isInitialLoading) {
              return const LoadingView(message: 'Đang tải danh sách hóa đơn…');
            }
            if (widget.invoiceController.errorMessage != null &&
                widget.invoiceController.invoices.isEmpty) {
              return ErrorView(
                message: widget.invoiceController.errorMessage,
                onRetry: _reload,
              );
            }

            final invoices = _filteredInvoices();
            return RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _PageHeader(
                      showAction: !compact && widget.canOperate,
                      onCreate: _createInvoice,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: InvoiceManagementOverview(
                      invoices: widget.invoiceController.invoices,
                    ),
                  ),
                  if (widget.invoiceController.errorMessage != null)
                    SliverToBoxAdapter(
                      child: _InlineMessage(
                        message: widget.invoiceController.errorMessage!,
                        isError: true,
                      ),
                    ),
                  if (widget.apartmentMembershipController.errorMessage != null)
                    SliverToBoxAdapter(
                      child: _InlineMessage(
                        message:
                            widget.apartmentMembershipController.errorMessage!,
                        isError: true,
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildFilters()),
                  if (widget.canOperate)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilterChip(
                            label: Text(
                              'Biên lai chờ đối soát '
                              '(${widget.invoiceController.invoices.where((invoice) => invoice.hasPendingBankTransfer).length})',
                            ),
                            selected: _pendingReceiptsOnly,
                            onSelected: (selected) => setState(() {
                              _pendingReceiptsOnly = selected;
                            }),
                          ),
                        ),
                      ),
                    ),
                  if (invoices.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        title: widget.invoiceController.invoices.isEmpty
                            ? 'Chưa có hóa đơn'
                            : 'Không tìm thấy hóa đơn',
                        message: widget.invoiceController.invoices.isEmpty
                            ? widget.canOperate
                                  ? 'Tạo hóa đơn đầu tiên cho một căn hộ.'
                                  : 'Chưa có hóa đơn nào được kế toán phát hành.'
                            : 'Hãy đổi từ khóa hoặc bộ lọc để xem kết quả khác.',
                        icon: Icons.receipt_long_outlined,
                        actionLabel: widget.invoiceController.invoices.isEmpty
                            ? widget.canOperate
                                  ? 'Tạo hóa đơn'
                                  : 'Tải lại'
                            : 'Xóa bộ lọc',
                        onAction: widget.invoiceController.invoices.isEmpty
                            ? widget.canOperate
                                  ? _createInvoice
                                  : _reload
                            : _clearFilters,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final columns = width >= 1120
                              ? 3
                              : width >= 720
                              ? 2
                              : 1;
                          Widget invoiceCard(
                            int index, {
                            bool compact = false,
                          }) {
                            final invoice = invoices[index];
                            return InvoiceManagementCard(
                              invoice: invoice,
                              apartment: _apartmentFor(invoice),
                              payer: _payerFor(invoice),
                              busy: _busyInvoiceIds.contains(invoice.id),
                              compact: compact,
                              canOperate: widget.canOperate,
                              onView: () => _showDetail(invoice),
                              onPublish: () => _publish(invoice),
                              onRecordPayment: () => _recordPayment(invoice),
                              onRejectPayment: () => _rejectPayment(invoice),
                              onCancel: () => _cancel(invoice),
                            );
                          }

                          return columns == 1
                              ? SliverList.builder(
                                  itemCount: invoices.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: invoiceCard(index, compact: true),
                                  ),
                                )
                              : SliverGrid.builder(
                                  itemCount: invoices.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        mainAxisExtent: 350,
                                      ),
                                  itemBuilder: (context, index) =>
                                      invoiceCard(index),
                                );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool get _isBusy =>
      widget.invoiceController.isLoading ||
      widget.apartmentMembershipController.isLoading;

  bool get _isInitialLoading =>
      (widget.invoiceController.isLoading &&
          widget.invoiceController.invoices.isEmpty) ||
      (widget.apartmentMembershipController.isLoading &&
          widget.apartmentMembershipController.apartments.isEmpty);

  Widget _buildFilters() {
    final months = _monthOptions();
    if (_monthFilter != null && !months.contains(_monthFilter)) {
      _monthFilter = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Tìm hóa đơn',
                  hintText: 'Mã hóa đơn, căn hộ hoặc người nộp',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa từ khóa',
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              );
              final status = DropdownButtonFormField<InvoiceStatus?>(
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem<InvoiceStatus?>(
                    value: null,
                    child: Text('Tất cả trạng thái'),
                  ),
                  for (final value in InvoiceStatus.values)
                    DropdownMenuItem<InvoiceStatus?>(
                      value: value,
                      child: Text(invoiceStatusLabel(value)),
                    ),
                ],
                onChanged: (value) => setState(() => _statusFilter = value),
              );
              final month = DropdownButtonFormField<String?>(
                initialValue: _monthFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kỳ hóa đơn',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tất cả các tháng'),
                  ),
                  for (final value in months)
                    DropdownMenuItem<String?>(
                      value: value,
                      child: Text(_displayMonthKey(value)),
                    ),
                ],
                onChanged: (value) => setState(() => _monthFilter = value),
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 12),
                    status,
                    const SizedBox(height: 12),
                    month,
                  ],
                );
              }
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: status),
                        const SizedBox(width: 12),
                        Expanded(child: month),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: status),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: month),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Invoice> _filteredInvoices() {
    final query = _searchController.text.trim().toLowerCase();
    final result = widget.invoiceController.invoices.where((invoice) {
      if (_pendingReceiptsOnly && !invoice.hasPendingBankTransfer) return false;
      if (_statusFilter != null && invoice.effectiveStatus != _statusFilter) {
        return false;
      }
      if (_monthFilter != null &&
          _monthKey(invoice.billingMonth) != _monthFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final apartment = _apartmentFor(invoice);
      final payer = _payerFor(invoice);
      final searchable = [
        invoice.code,
        apartment?.code ?? '',
        apartment?.buildingName ?? '',
        payer?.fullName ?? '',
        invoiceStatusLabel(invoice.effectiveStatus),
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();

    result.sort((first, second) {
      final month = second.billingMonth.compareTo(first.billingMonth);
      if (month != 0) return month;
      return second.issuedAt.compareTo(first.issuedAt);
    });
    return result;
  }

  List<String> _monthOptions() {
    final values =
        widget.invoiceController.invoices
            .map((invoice) => _monthKey(invoice.billingMonth))
            .toSet()
            .toList()
          ..sort((first, second) => second.compareTo(first));
    return values;
  }

  Apartment? _apartmentFor(Invoice invoice) {
    return widget.apartmentMembershipController.apartmentById(
      invoice.apartmentId,
    );
  }

  Resident? _payerFor(Invoice invoice) {
    return widget.apartmentMembershipController.residentById(
      invoice.payerResidentId,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = null;
      _monthFilter = null;
      _pendingReceiptsOnly = false;
    });
  }

  Future<void> _createInvoice() async {
    if (_isBusy) return;
    if (!await widget.invoiceController.loadUnbilledServices()) {
      if (mounted) {
        _showResult(
          false,
          widget.invoiceController.errorMessage ??
              'Không thể tải đơn dịch vụ chưa lập hóa đơn.',
        );
      }
      return;
    }
    if (!mounted) return;
    final data = await showInvoiceEditorDialog(
      context,
      apartments: widget.apartmentMembershipController.apartments,
      memberships: widget.apartmentMembershipController.memberships,
      residents: widget.apartmentMembershipController.residents,
      feeTypes: widget.invoiceController.feeTypes,
      unbilledServices: widget.invoiceController.unbilledServices,
    );
    if (data == null || !mounted) return;

    final success = await widget.invoiceController.createInvoice(
      apartmentId: data.apartmentId,
      payerResidentId: data.payerResidentId,
      billingMonth: data.billingMonth,
      dueDate: data.dueDate,
      items: data.items,
      publish: data.publish,
    );
    if (!mounted) return;
    _showResult(
      success,
      success
          ? data.publish
                ? 'Đã tạo và phát hành hóa đơn.'
                : 'Đã lưu hóa đơn dưới dạng bản nháp.'
          : widget.invoiceController.errorMessage ?? 'Không thể tạo hóa đơn.',
    );
  }

  Future<void> _showDetail(Invoice invoice) {
    return showInvoiceManagementDetailDialog(
      context,
      invoice: invoice,
      apartment: _apartmentFor(invoice),
      payer: _payerFor(invoice),
      canOperate: widget.canOperate,
      onPublish: () => _publish(invoice),
      onRecordPayment: () => _recordPayment(invoice),
      onRejectPayment: () => _rejectPayment(invoice),
      onCancel: () => _cancel(invoice),
    );
  }

  Future<void> _publish(Invoice invoice) async {
    if (_busyInvoiceIds.contains(invoice.id)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Phát hành hóa đơn?',
      message:
          'Hóa đơn ${invoice.code} sẽ được gửi đến người thanh toán '
          'và không còn là bản nháp.',
      confirmLabel: 'Phát hành',
    );
    if (!confirmed || !mounted) return;
    await _runInvoiceAction(
      invoice,
      action: () => widget.invoiceController.publishInvoice(invoice.id),
      successMessage: 'Đã phát hành hóa đơn ${invoice.code}.',
      fallbackError: 'Không thể phát hành hóa đơn.',
    );
  }

  Future<void> _recordPayment(Invoice invoice) async {
    if (_busyInvoiceIds.contains(invoice.id)) return;
    if (!invoice.hasPendingBankTransfer) {
      _showResult(false, 'Cư dân chưa gửi giao dịch cần xác nhận.');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xác nhận giao dịch?',
      message:
          'Biên lai có mã hồ sơ ${invoice.transactionCode ?? 'không xác định'} '
          'cho hóa đơn ${invoice.code}, số tiền '
          '${formatVnd(invoice.totalAmount)}. Chỉ xác nhận sau khi đã đối soát.',
      confirmLabel: 'Đã đối soát',
    );
    if (!confirmed || !mounted) return;
    await _runInvoiceAction(
      invoice,
      action: () => widget.invoiceController.recordPayment(invoice.id),
      successMessage: 'Đã ghi nhận thanh toán hóa đơn ${invoice.code}.',
      fallbackError: 'Không thể ghi nhận thanh toán.',
    );
  }

  Future<void> _rejectPayment(Invoice invoice) async {
    if (_busyInvoiceIds.contains(invoice.id) ||
        !invoice.hasPendingBankTransfer) {
      return;
    }
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối giao dịch'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do',
            hintText: 'Ví dụ: Không tìm thấy giao dịch trong sao kê',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.length >= 3) Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    await _runInvoiceAction(
      invoice,
      action: () =>
          widget.invoiceController.rejectPayment(invoice.id, note: reason),
      successMessage: 'Đã từ chối giao dịch và thông báo cho cư dân.',
      fallbackError: 'Không thể từ chối giao dịch.',
    );
  }

  Future<void> _cancel(Invoice invoice) async {
    if (_busyInvoiceIds.contains(invoice.id)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hủy hóa đơn?',
      message:
          'Hóa đơn ${invoice.code} sẽ chuyển sang trạng thái đã hủy. '
          'Hành động này không thể hoàn tác.',
      confirmLabel: 'Hủy hóa đơn',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await _runInvoiceAction(
      invoice,
      action: () => widget.invoiceController.cancelInvoice(invoice.id),
      successMessage: 'Đã hủy hóa đơn ${invoice.code}.',
      fallbackError: 'Không thể hủy hóa đơn.',
    );
  }

  Future<void> _runInvoiceAction(
    Invoice invoice, {
    required Future<bool> Function() action,
    required String successMessage,
    required String fallbackError,
  }) async {
    setState(() => _busyInvoiceIds.add(invoice.id));
    final success = await action();
    if (!mounted) return;
    setState(() => _busyInvoiceIds.remove(invoice.id));
    _showResult(
      success,
      success
          ? successMessage
          : widget.invoiceController.errorMessage ?? fallbackError,
    );
  }

  void _showResult(bool success, String message) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: colors.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.showAction, required this.onCreate});

  final bool showAction;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý thu phí',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Theo dõi hóa đơn, công nợ và các giao dịch của cư dân.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (showAction) ...[
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.post_add_rounded),
              label: const Text('Tạo hóa đơn'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.info_outline,
                color: foreground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _monthKey(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}';
}

String _displayMonthKey(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return value;
  return 'Tháng ${parts[1]}/${parts[0]}';
}
