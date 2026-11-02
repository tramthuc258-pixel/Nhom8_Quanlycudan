import 'package:flutter/material.dart';

import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/housing/widgets/housing_application_widgets.dart';
import 'package:homie/features/housing/widgets/housing_listing_widgets.dart';
import 'package:homie/features/housing/widgets/housing_listing_editor_dialog.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/storage/file_upload_service.dart';

import 'housing_inquiry_management_page.dart';

class HousingManagementPage extends StatefulWidget {
  const HousingManagementPage({
    required this.controller,
    required this.reviewer,
    this.fileUploadService,
    super.key,
  });

  final HousingController controller;
  final User reviewer;
  final FileUploadService? fileUploadService;

  @override
  State<HousingManagementPage> createState() => _HousingManagementPageState();
}

class _HousingManagementPageState extends State<HousingManagementPage> {
  final _searchController = TextEditingController();
  final _busyApplicationIds = <String>{};
  bool _waitingForFirstLoad = true;
  _ManagementHousingSection _section = _ManagementHousingSection.applications;
  HousingApplicationStatus? _statusFilter;
  HousingTransactionType? _transactionType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant HousingManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.reviewer.id != widget.reviewer.id) {
      _waitingForFirstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    await widget.controller.load();
    if (mounted) setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          MediaQuery.sizeOf(context).width < 600
              ? 'Thuê / mua'
              : 'Quản lý thuê và mua căn hộ',
        ),
        actions: [
          IconButton(
            tooltip: 'Yêu cầu từ khách',
            onPressed: _openGuestInquiries,
            icon: const Icon(Icons.contact_phone_outlined),
          ),
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => IconButton(
              tooltip: 'Tạo bài đăng',
              onPressed: widget.controller.isLoading
                  ? null
                  : _showCreateListing,
              icon: const Icon(Icons.post_add_rounded),
            ),
          ),
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => IconButton(
              tooltip: 'Tải lại dữ liệu',
              onPressed: widget.controller.isLoading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (_waitingForFirstLoad ||
                (widget.controller.isLoading &&
                    widget.controller.allListings.isEmpty &&
                    widget.controller.applications.isEmpty)) {
              return const LoadingView(message: 'Đang tải hồ sơ thuê và mua…');
            }
            if (widget.controller.errorMessage != null &&
                widget.controller.allListings.isEmpty &&
                widget.controller.applications.isEmpty) {
              return ErrorView(
                title: 'Không thể tải dữ liệu',
                message: widget.controller.errorMessage,
                onRetry: _load,
              );
            }
            return _buildContent();
          },
        ),
      ),
    );
  }

  Future<void> _openGuestInquiries() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            HousingInquiryManagementPage(controller: widget.controller),
      ),
    );
  }

  Widget _buildContent() {
    final applications = _filteredApplications();
    final listings = _filteredListings();
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildOverview()),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: _InlineError(message: widget.controller.errorMessage!),
            ),
          SliverToBoxAdapter(child: _buildFilters()),
          if (_section == _ManagementHousingSection.applications)
            ..._applicationSlivers(applications)
          else
            ..._listingSlivers(listings),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiếp nhận hồ sơ căn hộ',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Xét duyệt đăng ký thuê, mua và theo dõi trạng thái các tin đăng.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              );
              final selector = SegmentedButton<_ManagementHousingSection>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _ManagementHousingSection.applications,
                    icon: Icon(Icons.assignment_outlined),
                    label: Text('Hồ sơ'),
                  ),
                  ButtonSegment(
                    value: _ManagementHousingSection.listings,
                    icon: Icon(Icons.apartment_outlined),
                    label: Text('Tin đăng'),
                  ),
                ],
                selected: {_section},
                onSelectionChanged: (value) => _changeSection(value.first),
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [intro, const SizedBox(height: 16), selector],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: intro),
                  const SizedBox(width: 20),
                  selector,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final applications = widget.controller.applications;
    final pending = applications.where((item) => item.status.isPending).length;
    final completed = applications
        .where((item) => item.status == HousingApplicationStatus.completed)
        .length;
    final rejected = applications
        .where((item) => item.status == HousingApplicationStatus.rejected)
        .length;
    final available = widget.controller.allListings
        .where((item) => item.isAvailable)
        .length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 30) / 4
                  : constraints.maxWidth >= 320
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OverviewCard(
                    width: width,
                    icon: Icons.hourglass_top_rounded,
                    label: 'Chờ xét duyệt',
                    value: pending,
                    tone: _OverviewTone.warning,
                  ),
                  _OverviewCard(
                    width: width,
                    icon: Icons.verified_outlined,
                    label: 'Đã hoàn tất',
                    value: completed,
                    tone: _OverviewTone.success,
                  ),
                  _OverviewCard(
                    width: width,
                    icon: Icons.cancel_outlined,
                    label: 'Đã từ chối',
                    value: rejected,
                    tone: _OverviewTone.danger,
                  ),
                  _OverviewCard(
                    width: width,
                    icon: Icons.apartment_rounded,
                    label: 'Tin còn hiệu lực',
                    value: available,
                    tone: _OverviewTone.info,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText:
                          _section == _ManagementHousingSection.applications
                          ? 'Tìm hồ sơ'
                          : 'Tìm tin đăng',
                      hintText:
                          _section == _ManagementHousingSection.applications
                          ? 'Mã hồ sơ, căn hộ, họ tên, email hoặc điện thoại'
                          : 'Mã căn, tòa nhà hoặc tiêu đề',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa từ khóa',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: Text(compact ? 'Tất cả' : 'Tất cả hình thức'),
                        selected: _transactionType == null,
                        onSelected: (_) =>
                            setState(() => _transactionType = null),
                      ),
                      for (final type in HousingTransactionType.values)
                        ChoiceChip(
                          label: Text(type.shortLabel),
                          selected: _transactionType == type,
                          onSelected: (_) =>
                              setState(() => _transactionType = type),
                        ),
                    ],
                  ),
                  if (_section == _ManagementHousingSection.applications) ...[
                    const SizedBox(height: 10),
                    if (compact)
                      DropdownButtonFormField<HousingApplicationStatus?>(
                        key: ValueKey(_statusFilter),
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          prefixIcon: Icon(Icons.filter_list_rounded),
                        ),
                        items: [
                          const DropdownMenuItem<HousingApplicationStatus?>(
                            value: null,
                            child: Text('Mọi trạng thái'),
                          ),
                          for (final status in HousingApplicationStatus.values)
                            DropdownMenuItem<HousingApplicationStatus?>(
                              value: status,
                              child: Text(status.label),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('Mọi trạng thái'),
                            selected: _statusFilter == null,
                            onSelected: (_) =>
                                setState(() => _statusFilter = null),
                          ),
                          for (final status in HousingApplicationStatus.values)
                            ChoiceChip(
                              label: Text(status.label),
                              selected: _statusFilter == status,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = status),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _applicationSlivers(List<HousingApplication> applications) {
    if (applications.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.assignment_outlined,
            title: widget.controller.applications.isEmpty
                ? 'Chưa có hồ sơ đăng ký'
                : 'Không tìm thấy hồ sơ phù hợp',
            message: widget.controller.applications.isEmpty
                ? 'Hồ sơ thuê hoặc mua từ người dùng sẽ xuất hiện tại đây.'
                : 'Hãy đổi từ khóa, hình thức hoặc trạng thái.',
            actionLabel: widget.controller.applications.isEmpty
                ? 'Tải lại'
                : 'Xóa bộ lọc',
            onAction: widget.controller.applications.isEmpty
                ? _load
                : _clearFilters,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.crossAxisExtent >= 1120
                ? 3
                : constraints.crossAxisExtent >= 720
                ? 2
                : 1;
            Widget applicationCard(int index, {bool compact = false}) {
              final application = applications[index];
              final busy = _busyApplicationIds.contains(application.id);
              return HousingApplicationCard(
                application: application,
                listing: widget.controller.listingById(application.listingId),
                showApplicant: true,
                compact: compact,
                onView: () => _showApplication(application),
                onReject: application.canBeReviewed && !busy
                    ? () => _rejectApplication(application)
                    : null,
                onRecordContract: application.canBeReviewed && !busy
                    ? () => _recordContract(application)
                    : null,
              );
            }

            return columns == 1
                ? SliverList.builder(
                    itemCount: applications.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: applicationCard(index, compact: true),
                    ),
                  )
                : SliverGrid.builder(
                    itemCount: applications.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 355,
                    ),
                    itemBuilder: (context, index) => applicationCard(index),
                  );
          },
        ),
      ),
    ];
  }

  List<Widget> _listingSlivers(List<HousingListing> listings) {
    if (listings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.apartment_outlined,
            title: widget.controller.allListings.isEmpty
                ? 'Chưa có tin đăng căn hộ'
                : 'Không tìm thấy tin đăng phù hợp',
            message: widget.controller.allListings.isEmpty
                ? 'Tin cho thuê và mở bán sẽ xuất hiện tại đây.'
                : 'Hãy đổi từ khóa hoặc hình thức giao dịch.',
            actionLabel: widget.controller.allListings.isEmpty
                ? 'Tải lại'
                : 'Xóa bộ lọc',
            onAction: widget.controller.allListings.isEmpty
                ? _load
                : _clearFilters,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.crossAxisExtent >= 1120
                ? 3
                : constraints.crossAxisExtent >= 720
                ? 2
                : 1;
            Widget listingCard(int index, {bool compact = false}) {
              final listing = listings[index];
              return HousingListingCard(
                listing: listing,
                compact: compact,
                onView: () =>
                    showHousingListingDetailSheet(context, listing: listing),
                onApprove:
                    listing.status == HousingListingStatus.pendingApproval
                    ? () => _moderateListing(listing, approve: true)
                    : null,
                onReject: listing.status == HousingListingStatus.pendingApproval
                    ? () => _moderateListing(listing, approve: false)
                    : null,
              );
            }

            return columns == 1
                ? SliverList.builder(
                    itemCount: listings.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: listingCard(index, compact: true),
                    ),
                  )
                : SliverGrid.builder(
                    itemCount: listings.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 550,
                    ),
                    itemBuilder: (context, index) => listingCard(index),
                  );
          },
        ),
      ),
    ];
  }

  List<HousingApplication> _filteredApplications() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.applications
        .where((application) {
          if (_transactionType != null &&
              application.transactionType != _transactionType) {
            return false;
          }
          if (_statusFilter != null && application.status != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          final listing = widget.controller.listingById(application.listingId);
          return application.code.toLowerCase().contains(query) ||
              application.applicantFullName.toLowerCase().contains(query) ||
              application.applicantEmail.toLowerCase().contains(query) ||
              application.applicantPhone.toLowerCase().contains(query) ||
              (listing?.apartmentCode.toLowerCase().contains(query) ?? false) ||
              (listing?.buildingName.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  List<HousingListing> _filteredListings() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.allListings
        .where((listing) {
          if (_transactionType != null &&
              listing.transactionType != _transactionType) {
            return false;
          }
          if (query.isEmpty) return true;
          return listing.apartmentCode.toLowerCase().contains(query) ||
              listing.buildingName.toLowerCase().contains(query) ||
              listing.title.toLowerCase().contains(query) ||
              listing.description.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _changeSection(_ManagementHousingSection value) {
    setState(() {
      _section = value;
      _statusFilter = null;
      _searchController.clear();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _transactionType = null;
      _statusFilter = null;
    });
  }

  Future<void> _showApplication(HousingApplication application) async {
    final action = await showHousingApplicationDetailDialog(
      context,
      application: application,
      listing: widget.controller.listingById(application.listingId),
      allowReview: !_busyApplicationIds.contains(application.id),
    );
    if (!mounted || action == null) return;
    if (action == HousingApplicationDetailAction.recordContract) {
      await _recordContract(application);
    } else {
      await _rejectApplication(application);
    }
  }

  Future<void> _showCreateListing() async {
    widget.controller.clearError();
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HousingListingEditorDialog(
        controller: widget.controller,
        actor: widget.reviewer,
        apartments: widget.controller.apartmentsEligibleForListing(
          widget.reviewer,
        ),
        fileUploadService: widget.fileUploadService,
      ),
    );
    if (!mounted || created != true) return;
    setState(() => _section = _ManagementHousingSection.listings);
    _showResult(true, 'Đã đăng bài căn hộ.');
  }

  Future<void> _moderateListing(
    HousingListing listing, {
    required bool approve,
  }) async {
    String reason = '';
    if (!approve) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ListingRejectDialog(listing: listing),
      );
      if (result == null || !mounted) return;
      reason = result;
    }
    final success = approve
        ? await widget.controller.approveListing(
            listingId: listing.id,
            reviewer: widget.reviewer,
          )
        : await widget.controller.rejectListing(
            listingId: listing.id,
            reviewer: widget.reviewer,
            reason: reason,
          );
    if (!mounted) return;
    _showResult(
      success,
      success
          ? approve
                ? 'Đã duyệt bài đăng căn ${listing.apartmentCode}.'
                : 'Đã từ chối bài đăng căn ${listing.apartmentCode}.'
          : widget.controller.errorMessage ?? 'Không thể xử lý bài đăng.',
    );
  }

  Future<void> _recordContract(HousingApplication application) async {
    final contract = await showHousingContractDialog(
      context,
      application: application,
    );
    if (contract == null || !mounted) return;
    setState(() => _busyApplicationIds.add(application.id));
    final success = await widget.controller.completeApplication(
      applicationId: application.id,
      reviewer: widget.reviewer,
      contractNumber: contract.contractNumber,
      contractSignedAt: contract.signedAt,
      effectiveDate: contract.effectiveDate,
      note: contract.note,
    );
    if (!mounted) return;
    setState(() => _busyApplicationIds.remove(application.id));
    _showResult(
      success,
      success
          ? 'Đã ghi nhận hợp đồng cho hồ sơ ${application.code}.'
          : widget.controller.errorMessage ?? 'Không thể ghi nhận hợp đồng.',
    );
  }

  Future<void> _rejectApplication(HousingApplication application) async {
    if (_busyApplicationIds.contains(application.id)) return;
    final reason = await showHousingRejectionDialog(
      context,
      application: application,
    );
    if (reason == null || !mounted) return;
    setState(() => _busyApplicationIds.add(application.id));
    final success = await widget.controller.rejectApplication(
      applicationId: application.id,
      reviewer: widget.reviewer,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busyApplicationIds.remove(application.id));
    _showResult(
      success,
      success
          ? 'Đã từ chối hồ sơ ${application.code}.'
          : widget.controller.errorMessage ?? 'Không thể xử lý hồ sơ.',
    );
  }

  void _showResult(bool success, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

enum _ManagementHousingSection { applications, listings }

class _ListingRejectDialog extends StatefulWidget {
  const _ListingRejectDialog({required this.listing});

  final HousingListing listing;

  @override
  State<_ListingRejectDialog> createState() => _ListingRejectDialogState();
}

class _ListingRejectDialogState extends State<_ListingRejectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối bài đăng'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bài đăng căn ${widget.listing.apartmentCode} sẽ được trả lại cho chủ sở hữu.',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reasonController,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().length < 5
                    ? 'Vui lòng nhập ít nhất 5 ký tự'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _reasonController.text.trim());
            }
          },
          child: const Text('Từ chối bài'),
        ),
      ],
    );
  }
}

enum _OverviewTone { info, success, warning, danger }

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final double width;
  final IconData icon;
  final String label;
  final int value;
  final _OverviewTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = width < 220;
    final color = switch (tone) {
      _OverviewTone.info => colors.secondary,
      _OverviewTone.success => colors.primary,
      _OverviewTone.warning => const Color(0xFFB45309),
      _OverviewTone.danger => colors.error,
    };
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
