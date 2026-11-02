import 'package:flutter/material.dart';

import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/apartments/screens/apartment_detail_page.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/status_badge.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/residents/screens/management/residence_verification_page.dart';

class ResidentListPage extends StatefulWidget {
  const ResidentListPage({required this.controller, super.key});

  final ApartmentMembershipController controller;

  @override
  State<ResidentListPage> createState() => _ResidentListPageState();
}

class _ResidentListPageState extends State<ResidentListPage> {
  final _searchController = TextEditingController();
  MembershipType? _typeFilter;
  bool _onlyWithoutApartment = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.residents.isEmpty && !widget.controller.isLoading) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Quản lý cư dân'),
        actions: [
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
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading &&
                widget.controller.residents.isEmpty) {
              return const LoadingView(message: 'Đang tải danh sách cư dân…');
            }
            if (widget.controller.errorMessage != null &&
                widget.controller.residents.isEmpty) {
              return ErrorView(
                message: widget.controller.errorMessage,
                onRetry: widget.controller.load,
              );
            }

            final residents = _filteredResidents();
            return RefreshIndicator(
              onRefresh: widget.controller.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ResidentOverview(controller: widget.controller),
                  ),
                  SliverToBoxAdapter(
                    child: _VerificationShortcut(
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => ResidenceVerificationPage(
                            controller: widget.controller,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildFilters()),
                  if (residents.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        title: 'Không tìm thấy cư dân',
                        message: 'Hãy đổi từ khóa hoặc bộ lọc vai trò để xem kết quả khác.',
                        icon: Icons.people_outline_rounded,
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
                            itemCount: residents.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: 214,
                                ),
                            itemBuilder: (context, index) => _ResidentCard(
                              resident: residents[index],
                              controller: widget.controller,
                              onOpenApartment: _openApartment,
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

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Tìm cư dân',
                  hintText: 'Tên, số điện thoại, email hoặc mã căn hộ',
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
                    label: const Text('Tất cả'),
                    selected: _typeFilter == null && !_onlyWithoutApartment,
                    onSelected: (_) => setState(() {
                      _typeFilter = null;
                      _onlyWithoutApartment = false;
                    }),
                  ),
                  for (final type in const [
                    MembershipType.owner,
                    MembershipType.tenant,
                  ])
                    ChoiceChip(
                      label: Text(type.displayName),
                      selected: _typeFilter == type && !_onlyWithoutApartment,
                      onSelected: (_) => setState(() {
                        _typeFilter = type;
                        _onlyWithoutApartment = false;
                      }),
                    ),
                  ChoiceChip(
                    label: const Text('Chưa có căn hộ'),
                    selected: _onlyWithoutApartment,
                    onSelected: (_) => setState(() {
                      _typeFilter = null;
                      _onlyWithoutApartment = true;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Resident> _filteredResidents() {
    final query = _searchController.text.trim().toLowerCase();
    final residents = widget.controller.residents.where((resident) {
      final membership = widget.controller.activeMembershipForResident(
        resident.id,
      );
      if (_onlyWithoutApartment && membership != null) return false;
      if (_typeFilter != null && membership?.type != _typeFilter) return false;

      final apartment = membership == null
          ? null
          : widget.controller.apartmentById(membership.apartmentId);
      final haystack =
          '${resident.fullName} ${resident.phone} ${resident.email} ${apartment?.code ?? ''} ${apartment?.buildingName ?? ''}'
              .toLowerCase();
      return query.isEmpty || haystack.contains(query);
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
    return residents;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _typeFilter = null;
      _onlyWithoutApartment = false;
    });
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
}

class _VerificationShortcut extends StatelessWidget {
  const _VerificationShortcut({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF1FF), Color(0xFFE6F7F5)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFCFE0F8)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ chờ xác minh',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Duyệt chủ hộ và người thuê mới',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResidentOverview extends StatelessWidget {
  const _ResidentOverview({required this.controller});

  final ApartmentMembershipController controller;

  @override
  Widget build(BuildContext context) {
    final activeMemberships = controller.memberships
        .where((item) => item.isActive)
        .toList();
    final owners = activeMemberships
        .where((item) => item.type == MembershipType.owner)
        .length;
    final tenants = activeMemberships
        .where((item) => item.type == MembershipType.tenant)
        .length;
    final members = controller.householdMembers
        .where((item) => item.isActive)
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
                'Cư dân và quan hệ cư trú',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Quản lý tài khoản đại diện và hồ sơ thành viên của từng căn hộ.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CountChip(
                    label: 'Tổng hồ sơ',
                    value: controller.residents.length,
                    color: const Color(0xFF3157D5),
                    icon: Icons.groups_2_outlined,
                  ),
                  _CountChip(
                    label: 'Chủ sở hữu',
                    value: owners,
                    color: const Color(0xFF2563EB),
                    icon: Icons.verified_user_outlined,
                  ),
                  _CountChip(
                    label: 'Người thuê',
                    value: tenants,
                    color: const Color(0xFFB45309),
                    icon: Icons.key_outlined,
                  ),
                  _CountChip(
                    label: 'Thành viên không tài khoản',
                    value: members,
                    color: const Color(0xFF15803D),
                    icon: Icons.family_restroom_rounded,
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

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

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

class _ResidentCard extends StatelessWidget {
  const _ResidentCard({
    required this.resident,
    required this.controller,
    required this.onOpenApartment,
  });

  final Resident resident;
  final ApartmentMembershipController controller;
  final ValueChanged<Apartment> onOpenApartment;

  @override
  Widget build(BuildContext context) {
    final membership = controller.activeMembershipForResident(resident.id);
    final apartment = membership == null
        ? null
        : controller.apartmentById(membership.apartmentId);
    final roleColor = _roleColor(membership?.type);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: apartment == null ? null : () => onOpenApartment(apartment),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: roleColor.withValues(alpha: 0.12),
                    foregroundColor: roleColor,
                    child: Text(
                      _initials(resident.fullName),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resident.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 5),
                        StatusBadge(
                          label:
                              membership?.type.displayName ?? 'Chưa liên kết',
                          tone: _roleTone(membership?.type),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ContactLine(icon: Icons.phone_outlined, text: resident.phone),
              const SizedBox(height: 7),
              _ContactLine(
                icon: Icons.mail_outline_rounded,
                text: resident.email,
              ),
              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    apartment == null
                        ? Icons.home_work_outlined
                        : Icons.apartment_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      apartment == null
                          ? 'Chưa có căn hộ đang hiệu lực'
                          : 'Căn ${apartment.code} • ${apartment.buildingName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (apartment != null)
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

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

StatusBadgeTone _roleTone(MembershipType? type) => switch (type) {
  MembershipType.owner => StatusBadgeTone.info,
  MembershipType.tenant => StatusBadgeTone.warning,
  null => StatusBadgeTone.neutral,
};

Color _roleColor(MembershipType? type) => switch (type) {
  MembershipType.owner => const Color(0xFF2563EB),
  MembershipType.tenant => const Color(0xFFB45309),
  null => const Color(0xFF64748B),
};

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return 'CD';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
