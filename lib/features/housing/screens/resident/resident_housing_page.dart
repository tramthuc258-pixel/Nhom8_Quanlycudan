import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/housing/widgets/housing_application_form_dialog.dart';
import 'package:homie/features/housing/widgets/housing_application_widgets.dart';
import 'package:homie/features/housing/widgets/housing_listing_widgets.dart';
import 'package:homie/features/housing/widgets/housing_listing_editor_dialog.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/core/storage/file_upload_service.dart';

class ResidentHousingPage extends StatefulWidget {
  const ResidentHousingPage({
    required this.controller,
    required this.user,
    this.fileUploadService,
    super.key,
  });

  final HousingController controller;
  final User user;
  final FileUploadService? fileUploadService;

  @override
  State<ResidentHousingPage> createState() => _ResidentHousingPageState();
}

class _ResidentHousingPageState extends State<ResidentHousingPage> {
  final _searchController = TextEditingController();
  bool _waitingForFirstLoad = true;
  bool _onlyAvailable = true;
  String? _submittingListingId;
  _ResidentHousingSection _section = _ResidentHousingSection.listings;
  HousingTransactionType? _transactionType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant ResidentHousingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.user.id != widget.user.id) {
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
    final colors = Theme.of(context).colorScheme;
    final membership = widget.controller.apartmentMembershipController
        .activeMembershipForResident(widget.user.id);
    final isOwner = membership?.type == MembershipType.owner;
    return ResidentPageScaffold(
      title: isOwner ? 'Quản lý và giao dịch căn hộ' : 'Thuê và mua căn hộ',
      subtitle: isOwner
          ? 'Quản lý bài đăng tài sản và theo dõi thị trường'
          : 'Khám phá căn hộ và theo dõi hồ sơ của bạn',
      icon: Icons.real_estate_agent_outlined,
      accentColor: AppColors.billing,
      accentSoftColor: AppColors.billingSoft,
      actions: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final canCreate = widget.controller
                .apartmentsEligibleForListing(widget.user)
                .isNotEmpty;
            return IconButton(
              tooltip: canCreate
                  ? 'Đăng căn hộ của tôi'
                  : 'Không có căn hộ đủ điều kiện đăng',
              onPressed: canCreate && !widget.controller.isLoading
                  ? _showCreateListing
                  : null,
              icon: const Icon(Icons.post_add_rounded),
            );
          },
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: widget.controller.isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (_waitingForFirstLoad ||
              (widget.controller.isLoading &&
                  widget.controller.allListings.isEmpty)) {
            return const LoadingView(message: 'Đang tải danh sách căn hộ…');
          }
          if (widget.controller.errorMessage != null &&
              widget.controller.allListings.isEmpty) {
            return ErrorView(
              title: 'Không thể tải căn hộ',
              message: widget.controller.errorMessage,
              onRetry: _load,
            );
          }
          return _buildContent(colors, isOwner: isOwner);
        },
      ),
    );
  }

  Widget _buildContent(ColorScheme colors, {required bool isOwner}) {
    final myApplications = widget.controller
        .applicationsForApplicant(widget.user.id)
        .toList(growable: false);
    final myListings = widget.controller.listingsSubmittedBy(widget.user.id);
    final listings = _filteredListings();
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(myApplications)),
          SliverToBoxAdapter(
            child: _SectionSelector(
              section: _section,
              applicationCount: myApplications.length,
              listingCount: myListings.length,
              canManageListings: isOwner,
              onChanged: (value) => setState(() => _section = value),
            ),
          ),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: _InlineError(message: widget.controller.errorMessage!),
            ),
          if (_section == _ResidentHousingSection.listings) ...[
            SliverToBoxAdapter(child: _buildListingFilters()),
            if (listings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.apartment_outlined,
                  title: widget.controller.publicListings.isEmpty
                      ? 'Chưa có căn hộ được đăng'
                      : 'Không tìm thấy căn phù hợp',
                  message: widget.controller.publicListings.isEmpty
                      ? 'Danh sách thuê và mua sẽ xuất hiện tại đây.'
                      : 'Hãy đổi từ khóa hoặc bộ lọc để xem thêm lựa chọn.',
                  actionLabel: widget.controller.publicListings.isEmpty
                      ? 'Tải lại'
                      : 'Xóa bộ lọc',
                  onAction: widget.controller.publicListings.isEmpty
                      ? _load
                      : _clearFilters,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1120
                        ? 3
                        : constraints.crossAxisExtent >= 720
                        ? 2
                        : 1;
                    return SliverGrid.builder(
                      itemCount: listings.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 550,
                      ),
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        final canApply =
                            listing.isAvailable && _submittingListingId == null;
                        return HousingListingCard(
                          listing: listing,
                          onView: () => _showListing(listing),
                          onApply: canApply
                              ? () => _submitApplication(listing)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
          ] else if (_section == _ResidentHousingSection.applications) ...[
            SliverToBoxAdapter(child: _buildApplicationIntro(myApplications)),
            if (myApplications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.description_outlined,
                  title: 'Bạn chưa nộp hồ sơ nào',
                  message: 'Chọn một căn hộ đang nhận đăng ký để bắt đầu hồ sơ thuê hoặc mua.',
                  actionLabel: 'Xem căn hộ',
                  onAction: () => setState(
                    () => _section = _ResidentHousingSection.listings,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1000
                        ? 3
                        : constraints.crossAxisExtent >= 650
                        ? 2
                        : 1;
                    return SliverGrid.builder(
                      itemCount: myApplications.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 330,
                      ),
                      itemBuilder: (context, index) {
                        final application = myApplications[index];
                        return HousingApplicationCard(
                          application: application,
                          listing: widget.controller.listingById(
                            application.listingId,
                          ),
                          onView: () => _showApplication(application),
                        );
                      },
                    );
                  },
                ),
              ),
          ] else ...[
            ..._myListingSlivers(myListings),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(List<HousingApplication> applications) {
    final listings = widget.controller.publicListings;
    final availableRent = listings
        .where(
          (item) =>
              item.isAvailable &&
              item.transactionType == HousingTransactionType.rent,
        )
        .length;
    final availablePurchase = listings
        .where(
          (item) =>
              item.isAvailable &&
              item.transactionType == HousingTransactionType.purchase,
        )
        .length;
    final pending = applications
        .where((item) => item.status == HousingApplicationStatus.pending)
        .length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào ${widget.user.fullName}',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                'Khám phá căn hộ đang cho thuê hoặc mở bán trong khu dân cư.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatChip(
                    icon: Icons.key_outlined,
                    label: 'Căn cho thuê',
                    value: availableRent,
                  ),
                  _StatChip(
                    icon: Icons.home_work_outlined,
                    label: 'Căn mở bán',
                    value: availablePurchase,
                  ),
                  _StatChip(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Hồ sơ chờ duyệt',
                    value: pending,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingFilters() {
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
                      labelText: 'Tìm căn hộ',
                      hintText: 'Mã căn, tòa nhà hoặc nội dung tin đăng',
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
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả hình thức'),
                        selected: _transactionType == null,
                        onSelected: (_) =>
                            setState(() => _transactionType = null),
                      ),
                      for (final type in HousingTransactionType.values)
                        ChoiceChip(
                          avatar: Icon(
                            type == HousingTransactionType.rent
                                ? Icons.key_outlined
                                : Icons.home_work_outlined,
                            size: 17,
                          ),
                          label: Text(type.shortLabel),
                          selected: _transactionType == type,
                          onSelected: (_) =>
                              setState(() => _transactionType = type),
                        ),
                      FilterChip(
                        label: const Text('Chỉ căn đang nhận hồ sơ'),
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 17,
                        ),
                        selected: _onlyAvailable,
                        onSelected: (value) =>
                            setState(() => _onlyAvailable = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationIntro(List<HousingApplication> applications) {
    final completed = applications
        .where((item) => item.status == HousingApplicationStatus.completed)
        .length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    completed > 0
                        ? Icons.verified_outlined
                        : Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      completed > 0
                          ? 'Bạn có $completed giao dịch đã được ghi nhận hợp đồng và cập nhật quan hệ với căn hộ.'
                          : 'Ban quản lý sẽ phản hồi sau khi kiểm tra hồ sơ hoặc hợp đồng được ký bên ngoài ứng dụng.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<HousingListing> _filteredListings() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.publicListings
        .where((listing) {
          if (_onlyAvailable && !listing.isAvailable) return false;
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

  List<Widget> _myListingSlivers(List<HousingListing> listings) {
    if (listings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.real_estate_agent_outlined,
            title: 'Bạn chưa gửi bài đăng nào',
            message: 'Chỉ chủ sở hữu mới có thể gửi bài cho thuê hoặc mở bán. Bài sẽ được ban quản lý duyệt trước khi công khai.',
            actionLabel:
                widget.controller
                    .apartmentsEligibleForListing(widget.user)
                    .isNotEmpty
                ? 'Đăng căn hộ của tôi'
                : null,
            onAction:
                widget.controller
                    .apartmentsEligibleForListing(widget.user)
                    .isNotEmpty
                ? _showCreateListing
                : null,
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Text(
                'Theo dõi trạng thái bài do bạn gửi. Bài chỉ xuất hiện với người khác sau khi được ban quản lý duyệt.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.crossAxisExtent >= 1120
                ? 3
                : constraints.crossAxisExtent >= 720
                ? 2
                : 1;
            return SliverGrid.builder(
              itemCount: listings.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 540,
              ),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return HousingListingCard(
                  listing: listing,
                  onView: () =>
                      showHousingListingDetailSheet(context, listing: listing),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _transactionType = null;
      _onlyAvailable = false;
    });
  }

  Future<void> _showListing(HousingListing listing) async {
    final apply = await showHousingListingDetailSheet(
      context,
      listing: listing,
      canApply: listing.isAvailable && _submittingListingId == null,
    );
    if (apply == true && mounted) await _submitApplication(listing);
  }

  Future<void> _showCreateListing() async {
    widget.controller.clearError();
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HousingListingEditorDialog(
        controller: widget.controller,
        actor: widget.user,
        apartments: widget.controller.apartmentsEligibleForListing(widget.user),
        fileUploadService: widget.fileUploadService,
      ),
    );
    if (!mounted || created != true) return;
    setState(() => _section = _ResidentHousingSection.myListings);
    _showResult(true, 'Đã gửi bài đăng đến ban quản lý xét duyệt.');
  }

  Future<void> _submitApplication(HousingListing listing) async {
    if (_submittingListingId != null) return;
    final draft = await showHousingApplicationFormDialog(
      context,
      listing: listing,
    );
    if (draft == null || !mounted) return;
    setState(() => _submittingListingId = listing.id);
    final success = await widget.controller.submitApplication(
      listingId: listing.id,
      applicant: widget.user,
      phone: draft.phone,
      preferredStartDate: draft.preferredStartDate,
      preferredEndDate: draft.preferredEndDate,
      note: draft.note,
    );
    if (!mounted) return;
    setState(() {
      _submittingListingId = null;
      if (success) _section = _ResidentHousingSection.applications;
    });
    _showResult(
      success,
      success
          ? 'Đã gửi hồ sơ ${listing.transactionType == HousingTransactionType.rent ? 'thuê' : 'mua'} căn ${listing.apartmentCode}.'
          : widget.controller.errorMessage ?? 'Không thể gửi hồ sơ.',
    );
  }

  Future<void> _showApplication(HousingApplication application) async {
    await showHousingApplicationDetailDialog(
      context,
      application: application,
      listing: widget.controller.listingById(application.listingId),
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

enum _ResidentHousingSection { listings, applications, myListings }

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({
    required this.section,
    required this.applicationCount,
    required this.listingCount,
    required this.canManageListings,
    required this.onChanged,
  });

  final _ResidentHousingSection section;
  final int applicationCount;
  final int listingCount;
  final bool canManageListings;
  final ValueChanged<_ResidentHousingSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_ResidentHousingSection>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                  value: _ResidentHousingSection.listings,
                  icon: Icon(Icons.apartment_rounded),
                  label: Text('Danh sách căn hộ'),
                ),
                ButtonSegment(
                  value: _ResidentHousingSection.applications,
                  icon: const Icon(Icons.description_outlined),
                  label: Text('Hồ sơ của tôi ($applicationCount)'),
                ),
                if (canManageListings)
                  ButtonSegment(
                    value: _ResidentHousingSection.myListings,
                    icon: const Icon(Icons.real_estate_agent_outlined),
                    label: Text('Tin của tôi ($listingCount)'),
                  ),
              ],
              selected: {section},
              onSelectionChanged: (value) => onChanged(value.first),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: colors.primary),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
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
