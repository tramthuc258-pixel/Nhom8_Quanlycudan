import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/invoices/models/invoice_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/controllers/invoice_controller.dart';
import 'package:homie/features/invoices/screens/resident/invoice_detail_page.dart';
import 'package:homie/features/invoices/widgets/resident/resident_invoice_widgets.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/core/storage/file_upload_service.dart';

class ResidentInvoiceListPage extends StatefulWidget {
  const ResidentInvoiceListPage({
    required this.invoiceController,
    required this.apartmentMembershipController,
    required this.user,
    this.fileUploadService,
    super.key,
  });

  final InvoiceController invoiceController;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  final FileUploadService? fileUploadService;

  @override
  State<ResidentInvoiceListPage> createState() =>
      _ResidentInvoiceListPageState();
}

class _ResidentInvoiceListPageState extends State<ResidentInvoiceListPage> {
  bool _waitingForFirstLoad = true;
  InvoiceStatus? _statusFilter;
  int? _monthFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant ResidentInvoiceListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoiceController != widget.invoiceController ||
        oldWidget.apartmentMembershipController !=
            widget.apartmentMembershipController ||
        oldWidget.user.id != widget.user.id) {
      _waitingForFirstLoad = true;
      _statusFilter = null;
      _monthFilter = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    await Future.wait<void>([
      widget.apartmentMembershipController.load(),
      widget.invoiceController.load(),
    ]);
    if (!mounted) return;
    setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Hóa đơn căn hộ',
      subtitle: 'Khoản phí, công nợ và lịch sử thanh toán',
      icon: Icons.receipt_long_outlined,
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
    final isInitiallyLoading =
        _waitingForFirstLoad ||
        (apartmentMembershipController.isLoading &&
            apartmentMembershipController.apartments.isEmpty) ||
        (invoiceController.isLoading && invoiceController.invoices.isEmpty);

    if (isInitiallyLoading) {
      return const LoadingView(message: 'Đang tải hóa đơn…');
    }

    if (apartmentMembershipController.errorMessage != null &&
        apartmentMembershipController.apartments.isEmpty) {
      return ErrorView(
        title: 'Không thể xác định căn hộ',
        message: apartmentMembershipController.errorMessage,
        onRetry: _load,
      );
    }

    final membership = apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    if (membership == null) {
      return EmptyView(
        icon: Icons.home_work_outlined,
        title: 'Chưa có căn hộ đang cư trú',
        message:
            'Tài khoản ${widget.user.fullName} chưa được gắn với căn hộ nào đang hiệu lực.',
        actionLabel: 'Tải lại',
        onAction: _load,
      );
    }

    final apartment = apartmentMembershipController.apartmentById(
      membership.apartmentId,
    );
    if (apartment == null) {
      return ErrorView(
        title: 'Không tìm thấy căn hộ',
        message: 'Thông tin cư trú chưa được gắn với căn hộ hợp lệ.',
        onRetry: _load,
      );
    }

    final allInvoices = _residentVisibleInvoices(
      invoiceController
          .invoicesForApartment(apartment.id)
          .where((invoice) => invoice.payerResidentId == widget.user.id)
          .toList(growable: false),
    );

    if (invoiceController.errorMessage != null && allInvoices.isEmpty) {
      return ErrorView(
        title: 'Không thể tải hóa đơn',
        message: invoiceController.errorMessage,
        onRetry: _load,
      );
    }

    final filteredInvoices = _filteredInvoices(allInvoices);
    final outstandingCount = allInvoices
        .where((invoice) => invoice.isOutstanding)
        .length;
    final paidCount = allInvoices
        .where((invoice) => invoice.effectiveStatus == InvoiceStatus.paid)
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _DebtOverview(
              apartment: apartment,
              totalDebt: invoiceController.totalDebtForApartment(apartment.id),
              outstandingCount: outstandingCount,
              paidCount: paidCount,
            ),
          ),
          if (invoiceController.errorMessage != null)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _RefreshWarning(
                      message: invoiceController.errorMessage!,
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _InvoiceFilters(
              invoices: allInvoices,
              status: _statusFilter,
              monthKey: _monthFilter,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onMonthChanged: (value) => setState(() => _monthFilter = value),
              onClear: _hasActiveFilter ? _clearFilters : null,
            ),
          ),
          if (filteredInvoices.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: allInvoices.isEmpty
                    ? Icons.receipt_long_outlined
                    : Icons.filter_alt_off_outlined,
                title: allInvoices.isEmpty
                    ? 'Chưa có hóa đơn'
                    : 'Không có hóa đơn phù hợp',
                message: allInvoices.isEmpty
                    ? 'Hóa đơn sau khi ban quản lý phát hành sẽ xuất hiện tại đây.'
                    : 'Hãy thay đổi trạng thái hoặc kỳ thanh toán.',
                actionLabel: allInvoices.isEmpty ? 'Tải lại' : 'Xóa bộ lọc',
                onAction: allInvoices.isEmpty ? _load : _clearFilters,
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final horizontalPadding = width > 1212
                    ? (width - 1180) / 2
                    : 16.0;
                final columns = width >= 820 ? 2 : 1;
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    36,
                  ),
                  sliver: SliverGrid.builder(
                    itemCount: filteredInvoices.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 292,
                    ),
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      final payer = apartmentMembershipController.residentById(
                        invoice.payerResidentId,
                      );
                      return ResidentInvoiceCard(
                        invoice: invoice,
                        apartment: apartment,
                        payerName: payer?.fullName ?? 'Chưa xác định',
                        onTap: () => _openDetail(invoice.id),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Invoice> _residentVisibleInvoices(List<Invoice> source) {
    final result = source
        .where((invoice) => invoice.effectiveStatus != InvoiceStatus.draft)
        .toList();
    result.sort((first, second) {
      final month = second.billingMonth.compareTo(first.billingMonth);
      if (month != 0) return month;
      return second.issuedAt.compareTo(first.issuedAt);
    });
    return List<Invoice>.unmodifiable(result);
  }

  List<Invoice> _filteredInvoices(List<Invoice> source) {
    return source
        .where((invoice) {
          if (_statusFilter != null &&
              invoice.effectiveStatus != _statusFilter) {
            return false;
          }
          if (_monthFilter != null &&
              _monthKey(invoice.billingMonth) != _monthFilter) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  bool get _hasActiveFilter => _statusFilter != null || _monthFilter != null;

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _monthFilter = null;
    });
  }

  Future<void> _openDetail(String invoiceId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoiceController: widget.invoiceController,
          apartmentMembershipController: widget.apartmentMembershipController,
          user: widget.user,
          invoiceId: invoiceId,
          fileUploadService: widget.fileUploadService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _DebtOverview extends StatelessWidget {
  const _DebtOverview({
    required this.apartment,
    required this.totalDebt,
    required this.outstandingCount,
    required this.paidCount,
  });

  final Apartment apartment;
  final double totalDebt;
  final int outstandingCount;
  final int paidCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final balance = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Căn ${apartment.code} · ${apartment.buildingName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'Tổng công nợ hiện tại',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatInvoiceMoney(totalDebt),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        totalDebt == 0
                            ? 'Căn hộ không có khoản phí cần thanh toán.'
                            : 'Bao gồm các hóa đơn chưa thanh toán và quá hạn.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                  final metrics = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DebtMetric(
                        value: '$outstandingCount',
                        label: 'Cần thanh toán',
                        icon: Icons.schedule_rounded,
                      ),
                      _DebtMetric(
                        value: '$paidCount',
                        label: 'Đã thanh toán',
                        icon: Icons.task_alt_rounded,
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 720) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [balance, const SizedBox(height: 20), metrics],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: balance),
                      const SizedBox(width: 24),
                      metrics,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtMetric extends StatelessWidget {
  const _DebtMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceFilters extends StatelessWidget {
  const _InvoiceFilters({
    required this.invoices,
    required this.status,
    required this.monthKey,
    required this.onStatusChanged,
    required this.onMonthChanged,
    required this.onClear,
  });

  final List<Invoice> invoices;
  final InvoiceStatus? status;
  final int? monthKey;
  final ValueChanged<InvoiceStatus?> onStatusChanged;
  final ValueChanged<int?> onMonthChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final monthDates = <int, DateTime>{};
    for (final invoice in invoices) {
      monthDates[_monthKey(invoice.billingMonth)] = invoice.billingMonth;
    }
    final months = monthDates.entries.toList()
      ..sort((first, second) => second.key.compareTo(first.key));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lọc hóa đơn',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (onClear != null)
                        TextButton.icon(
                          onPressed: onClear,
                          icon: const Icon(
                            Icons.filter_alt_off_rounded,
                            size: 18,
                          ),
                          label: const Text('Xóa bộ lọc'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: status == null,
                        onSelected: (_) => onStatusChanged(null),
                      ),
                      for (final option in const [
                        InvoiceStatus.unpaid,
                        InvoiceStatus.overdue,
                        InvoiceStatus.paid,
                        InvoiceStatus.cancelled,
                      ])
                        ChoiceChip(
                          label: Text(option.label),
                          selected: status == option,
                          onSelected: (_) => onStatusChanged(option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    initialValue: monthKey,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kỳ thanh toán',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả các tháng'),
                      ),
                      for (final entry in months)
                        DropdownMenuItem<int?>(
                          value: entry.key,
                          child: Text(formatInvoiceMonth(entry.value)),
                        ),
                    ],
                    onChanged: onMonthChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning({required this.message});

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
              '$message Dữ liệu gần nhất vẫn được hiển thị.',
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

int _monthKey(DateTime date) => date.year * 100 + date.month;
