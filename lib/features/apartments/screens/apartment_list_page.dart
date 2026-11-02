import 'package:flutter/material.dart';

import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/apartments/screens/apartment_detail_page.dart';
import 'package:homie/features/apartments/widgets/apartment_status_badge.dart';
import 'package:homie/features/apartments/widgets/apartment_editor_dialog.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';

class ApartmentListPage extends StatefulWidget {
  const ApartmentListPage({required this.controller, super.key});

  final ApartmentMembershipController controller;

  @override
  State<ApartmentListPage> createState() => _ApartmentListPageState();
}

class _ApartmentListPageState extends State<ApartmentListPage> {
  final _searchController = TextEditingController();
  ApartmentStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.apartments.isEmpty &&
          !widget.controller.isLoading) {
        widget.controller.load();
      }
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Quản lý căn hộ'),
        actions: [
          if (isWideScreen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                onPressed: widget.controller.isLoading
                    ? null
                    : _showCreateApartment,
                icon: const Icon(Icons.add_home_work_outlined),
                label: const Text('Thêm căn hộ'),
              ),
            ),
          if (isWideScreen) const SizedBox(width: 6),
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: widget.controller.isLoading
                ? null
                : widget.controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isWideScreen
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.controller.isLoading
                  ? null
                  : _showCreateApartment,
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('Thêm căn hộ'),
            ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading &&
                widget.controller.apartments.isEmpty) {
              return const LoadingView(message: 'Đang tải danh sách căn hộ…');
            }

            if (widget.controller.errorMessage != null &&
                widget.controller.apartments.isEmpty) {
              return ErrorView(
                message: widget.controller.errorMessage,
                onRetry: widget.controller.load,
              );
            }

            final apartments = _filteredApartments();
            return RefreshIndicator(
              onRefresh: widget.controller.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _PageOverview(
                      apartments: widget.controller.apartments,
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildFilters(context)),
                  if (apartments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        title: 'Không tìm thấy căn hộ',
                        message: 'Hãy đổi từ khóa hoặc bộ lọc trạng thái để xem kết quả khác.',
                        icon: Icons.apartment_rounded,
                        actionLabel: 'Xóa bộ lọc',
                        onAction: _clearFilters,
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
                          return SliverGrid.builder(
                            itemCount: apartments.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: 230,
                                ),
                            itemBuilder: (context, index) => _ApartmentCard(
                              apartment: apartments[index],
                              controller: widget.controller,
                              onTap: () => _openApartment(apartments[index]),
                            ),
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

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Tìm căn hộ',
                  hintText: 'Mã căn hộ, tòa hoặc tên cư dân',
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
              final filters = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  for (final status in ApartmentStatus.values)
                    ChoiceChip(
                      label: Text(status.displayName),
                      selected: _statusFilter == status,
                      onSelected: (_) => setState(() => _statusFilter = status),
                    ),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 14), filters],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: filters),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Apartment> _filteredApartments() {
    final query = _searchController.text.trim().toLowerCase();
    final results = widget.controller.apartments.where((apartment) {
      if (_statusFilter != null && apartment.status != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final residents = widget.controller
          .membershipsForApartment(apartment.id, includeEnded: false)
          .map(
            (membership) =>
                widget.controller.residentById(membership.residentId),
          )
          .whereType<Resident>()
          .map(
            (resident) =>
                '${resident.fullName} ${resident.phone} ${resident.email}'
                    .toLowerCase(),
          )
          .join(' ');
      final haystack = '${apartment.code} ${apartment.buildingName} $residents'
          .toLowerCase();
      return haystack.contains(query);
    }).toList()..sort((a, b) => a.code.compareTo(b.code));
    return results;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _statusFilter = null);
  }

  Future<void> _openApartment(Apartment apartment) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ApartmentDetailPage(
          controller: widget.controller,
          apartmentId: apartment.id,
        ),
      ),
    );
  }

  Future<void> _showCreateApartment() async {
    widget.controller.clearError();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ApartmentEditorDialog(controller: widget.controller),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã thêm căn hộ mới.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _PageOverview extends StatelessWidget {
  const _PageOverview({required this.apartments});

  final List<Apartment> apartments;

  @override
  Widget build(BuildContext context) {
    final occupied = apartments
        .where((item) => item.status == ApartmentStatus.occupied)
        .length;
    final vacant = apartments
        .where((item) => item.status == ApartmentStatus.vacant)
        .length;
    final maintenance = apartments
        .where((item) => item.status == ApartmentStatus.underMaintenance)
        .length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách căn hộ',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Theo dõi tình trạng căn hộ và người đang cư trú tại từng căn.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OverviewChip(
                    label: 'Tổng căn hộ',
                    value: apartments.length,
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF3157D5),
                  ),
                  _OverviewChip(
                    label: 'Đang sử dụng',
                    value: occupied,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF15803D),
                  ),
                  _OverviewChip(
                    label: 'Còn trống',
                    value: vacant,
                    icon: Icons.meeting_room_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  _OverviewChip(
                    label: 'Bảo trì',
                    value: maintenance,
                    icon: Icons.handyman_outlined,
                    color: const Color(0xFFB45309),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({
    required this.apartment,
    required this.controller,
    required this.onTap,
  });

  final Apartment apartment;
  final ApartmentMembershipController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final memberships = controller.membershipsForApartment(
      apartment.id,
      includeEnded: false,
    );
    final ownerMembership = memberships
        .where((item) => item.type == MembershipType.owner)
        .firstOrNull;
    final owner = ownerMembership == null
        ? null
        : controller.residentById(ownerMembership.residentId);
    final activeResidents = memberships.where((item) => item.isActive).length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7ECFF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF3157D5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Căn ${apartment.code}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${apartment.buildingName} • Tầng ${apartment.floor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ApartmentStatusBadge(status: apartment.status),
                ],
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _CardInfo(
                    icon: Icons.square_foot_rounded,
                    label: '${_formatArea(apartment.area)} m²',
                  ),
                  _CardInfo(
                    icon: Icons.bed_outlined,
                    label: '${apartment.bedrooms} phòng ngủ',
                  ),
                  _CardInfo(
                    icon: Icons.groups_2_outlined,
                    label: '$activeResidents cư dân',
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      owner == null
                          ? 'Chưa có chủ sở hữu'
                          : 'Chủ sở hữu: ${owner.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

String _formatArea(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
