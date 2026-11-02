import 'package:flutter/material.dart';

import 'package:homie/features/reports/models/management_report.dart';

import '../controllers/report_controller.dart';

class ManagementReportPage extends StatefulWidget {
  const ManagementReportPage({required this.controller, super.key});

  final ReportController controller;

  @override
  State<ManagementReportPage> createState() => _ManagementReportPageState();
}

class _ManagementReportPageState extends State<ManagementReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Báo cáo và thống kê'),
            Text(
              'Tổng hợp tình hình vận hành chung cư',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: widget.controller.isLoading
                ? null
                : widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    final report = controller.report;
    if (controller.isLoading && report == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(controller.errorMessage ?? 'Chưa có dữ liệu báo cáo.'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: controller.load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportHeader(controller: controller),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _WarningBanner(message: controller.errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  _SummaryGrid(report: report),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final revenue = _RevenueCard(report: report);
                      final apartment = _ApartmentCard(report: report);
                      if (constraints.maxWidth < 820) {
                        return Column(
                          children: [
                            revenue,
                            const SizedBox(height: 16),
                            apartment,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: revenue),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: apartment),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _OperationsGrid(report: report),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.controller});
  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan vận hành',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Dữ liệu được tổng hợp từ các nghiệp vụ hiện có trong ứng dụng.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF707991)),
            ),
          ],
        );
        final filter = DropdownButton<ReportPeriod>(
          value: controller.period,
          items: [
            for (final item in ReportPeriod.values)
              DropdownMenuItem(value: item, child: Text(item.label)),
          ],
          onChanged: (value) {
            if (value != null) controller.setPeriod(value);
          },
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              Row(children: [const Text('Kỳ báo cáo: '), filter]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            const Text('Kỳ báo cáo: '),
            filter,
          ],
        );
      },
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});
  final ManagementReport report;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryData(
        'Tổng căn hộ',
        '${report.totalApartments}',
        '${report.occupiedApartments} đang sử dụng',
        Icons.apartment_rounded,
        const Color(0xFF3157D5),
        const Color(0xFFE7ECFF),
      ),
      _SummaryData(
        'Cư dân hiệu lực',
        '${report.activeResidents}',
        'Theo quan hệ cư trú',
        Icons.groups_2_outlined,
        const Color(0xFF25845B),
        const Color(0xFFE4F7EF),
      ),
      _SummaryData(
        'Đã thu',
        _money(report.collectedRevenue),
        'Tỷ lệ ${(report.invoiceCollectionRate * 100).toStringAsFixed(0)}%',
        Icons.account_balance_wallet_outlined,
        const Color(0xFF7855C7),
        const Color(0xFFF0E9FF),
      ),
      _SummaryData(
        'Công nợ',
        _money(report.outstandingDebt),
        '${report.openMaintenanceRequests} yêu cầu đang mở',
        Icons.warning_amber_rounded,
        const Color(0xFFD76B2D),
        const Color(0xFFFFF0E5),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 145,
          ),
          itemBuilder: (_, index) => _SummaryCard(data: items[index]),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});
  final _SummaryData data;
  @override
  Widget build(BuildContext context) => _ReportCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: data.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const Spacer(),
            Text(
              data.label,
              style: const TextStyle(color: Color(0xFF707991), fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17213B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.note,
          style: const TextStyle(color: Color(0xFF7A849D), fontSize: 11),
        ),
      ],
    ),
  );
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.report});
  final ManagementReport report;
  @override
  Widget build(BuildContext context) => _ReportCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardTitle(
          title: 'Doanh thu hóa đơn',
          subtitle: 'Số tiền đã thu trong 6 tháng gần nhất',
        ),
        const SizedBox(height: 22),
        SizedBox(height: 210, child: _RevenueBars(data: report.monthlyRevenue)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 22,
          runSpacing: 10,
          children: [
            _MetricText(
              label: 'Tổng phát hành',
              value: _money(report.totalInvoiceValue),
            ),
            _MetricText(
              label: 'Đã thu',
              value: _money(report.collectedRevenue),
            ),
            _MetricText(label: 'Còn nợ', value: _money(report.outstandingDebt)),
          ],
        ),
      ],
    ),
  );
}

class _RevenueBars extends StatelessWidget {
  const _RevenueBars({required this.data});
  final List<ReportBarDatum> data;
  @override
  Widget build(BuildContext context) {
    final maximum = data.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in data)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.value == 0 ? '0' : _compactMoney(item.value),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF707991),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: maximum == 0 ? 4 : 145 * item.value / maximum,
                    decoration: BoxDecoration(
                      color: item.value == 0
                          ? const Color(0xFFE7EBF5)
                          : const Color(0xFF3157D5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({required this.report});
  final ManagementReport report;
  @override
  Widget build(BuildContext context) {
    final total = report.totalApartments == 0 ? 1 : report.totalApartments;
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Tình trạng căn hộ',
            subtitle: 'Phân bổ theo trạng thái hiện tại',
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox.square(
              dimension: 145,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: report.occupiedApartments / total,
                      strokeWidth: 15,
                      backgroundColor: const Color(0xFFE7EBF5),
                      color: const Color(0xFF3157D5),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(report.occupiedApartments / total * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'đang sử dụng',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF707991),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _StatusRow(
            label: 'Đang sử dụng',
            value: report.occupiedApartments,
            color: const Color(0xFF3157D5),
          ),
          _StatusRow(
            label: 'Đang trống',
            value: report.vacantApartments,
            color: const Color(0xFFB7C0D5),
          ),
          _StatusRow(
            label: 'Đang bảo trì',
            value: report.maintenanceApartments,
            color: const Color(0xFFD76B2D),
          ),
        ],
      ),
    );
  }
}

class _OperationsGrid extends StatelessWidget {
  const _OperationsGrid({required this.report});
  final ManagementReport report;
  @override
  Widget build(BuildContext context) {
    final cards = [
      _OperationData(
        'Bảo trì',
        Icons.build_circle_outlined,
        '${report.maintenanceRequests} yêu cầu',
        [
          ('Đang mở', report.openMaintenanceRequests),
          ('Hoàn thành', report.completedMaintenanceRequests),
          ('Xử lý TB', _hours(report.averageMaintenanceHours)),
          ('Yêu cầu làm lại', report.reopenedMaintenanceRequests),
        ],
      ),
      _OperationData(
        'Dịch vụ',
        Icons.room_service_outlined,
        '${report.serviceBookings} lượt đặt',
        [
          ('Hoàn thành', report.completedServiceBookings),
          (
            'Tỷ lệ hoàn tất',
            '${(report.serviceCompletionRate * 100).toStringAsFixed(0)}%',
          ),
          ('Doanh thu', _compactMoney(report.serviceRevenue)),
        ],
      ),
      _OperationData(
        'Tiện ích',
        Icons.event_available_outlined,
        '${report.amenityBookings} lượt đặt',
        [
          ('Chờ duyệt', report.pendingAmenityBookings),
          ('Đã duyệt', report.approvedAmenityBookings),
          ('Hoàn tất', report.completedAmenityBookings),
          ('Không đến', report.noShowAmenityBookings),
        ],
      ),
      _OperationData(
        'Thuê / mua',
        Icons.real_estate_agent_outlined,
        '${report.pendingHousingApplications + report.approvedHousingApplications} hồ sơ',
        [
          ('Chờ duyệt', report.pendingHousingApplications),
          ('Đã hoàn tất', report.approvedHousingApplications),
        ],
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 245,
          ),
          itemBuilder: (_, index) => _OperationCard(data: cards[index]),
        );
      },
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.data});
  final _OperationData data;
  @override
  Widget build(BuildContext context) => _ReportCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE7ECFF),
          foregroundColor: const Color(0xFF3157D5),
          child: Icon(data.icon),
        ),
        const SizedBox(height: 13),
        Text(
          data.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          data.total,
          style: const TextStyle(color: Color(0xFF707991), fontSize: 12),
        ),
        const Spacer(),
        for (final item in data.details)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF707991),
                    ),
                  ),
                ),
                Text(
                  '${item.$2}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE8EBF2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0917213B),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF707991)),
      ),
    ],
  );
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF707991)),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF707991)),
          ),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0E5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD76B2D)),
        const SizedBox(width: 9),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _SummaryData {
  const _SummaryData(
    this.label,
    this.value,
    this.note,
    this.icon,
    this.color,
    this.background,
  );
  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final Color background;
}

class _OperationData {
  const _OperationData(this.title, this.icon, this.total, this.details);
  final String title;
  final IconData icon;
  final String total;
  final List<(String, Object)> details;
}

String _money(double value) => '${_formatNumber(value.round())} ₫';
String _hours(double value) => value == 0
    ? 'Chưa có'
    : value < 24
    ? '${value.toStringAsFixed(1)} giờ'
    : '${(value / 24).toStringAsFixed(1)} ngày';
String _compactMoney(double value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)} tỷ';
  }
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} tr';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)} nghìn';
  return value.toStringAsFixed(0);
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    if (index > 0 && (text.length - index) % 3 == 0) buffer.write('.');
    buffer.write(text[index]);
  }
  return buffer.toString();
}
