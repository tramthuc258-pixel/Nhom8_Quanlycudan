import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/household_member.dart';
import 'package:homie/features/residents/widgets/resident/apartment_overview_card.dart';
import 'package:homie/features/residents/widgets/resident/household_member_section.dart';
import 'package:homie/features/residents/widgets/resident/household_member_editor_dialog.dart';
import 'package:homie/features/residents/widgets/resident/household_profile_section.dart';
import 'package:homie/core/widgets/confirm_dialog.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

/// Thông tin căn hộ riêng tư dành cho tài khoản cư dân.
class HouseholdPage extends StatefulWidget {
  const HouseholdPage({
    required this.controller,
    required this.user,
    super.key,
  });

  final ApartmentMembershipController controller;
  final User user;

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  bool _waitingForFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant HouseholdPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.user.id != widget.user.id) {
      _waitingForFirstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    await widget.controller.load();
    if (!mounted) return;
    setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Căn hộ của tôi',
      subtitle: 'Thông tin nơi ở và dữ liệu riêng tư',
      icon: Icons.home_work_outlined,
      accentColor: AppColors.secondary,
      accentSoftColor: AppColors.secondaryLight,
      actions: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return IconButton(
              tooltip: 'Tải lại dữ liệu',
              onPressed: widget.controller.isLoading
                  ? null
                  : widget.controller.load,
              icon: const Icon(Icons.refresh_rounded),
            );
          },
        ),
      ],
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;

    if (_waitingForFirstLoad || controller.isLoading) {
      return const LoadingView(message: 'Đang tải thông tin căn hộ…');
    }

    final errorMessage = controller.errorMessage;
    if (errorMessage != null) {
      return ErrorView(
        title: 'Không thể tải thông tin căn hộ',
        message: errorMessage,
        onRetry: _load,
      );
    }

    final currentMembership = controller.activeMembershipForResident(
      widget.user.id,
    );
    if (currentMembership == null) {
      return EmptyView(
        icon: Icons.home_work_outlined,
        title: 'Chưa có căn hộ đang cư trú',
        message:
            'Tài khoản ${widget.user.fullName} chưa được ban quản lý gắn với căn hộ nào đang hiệu lực.',
        actionLabel: 'Tải lại',
        onAction: _load,
      );
    }

    final apartment = controller.apartmentById(currentMembership.apartmentId);
    if (apartment == null) {
      return ErrorView(
        title: 'Không tìm thấy căn hộ',
        message: 'Quan hệ cư trú của bạn chưa được gắn với một căn hộ hợp lệ. Vui lòng liên hệ ban quản lý.',
        onRetry: _load,
      );
    }

    final memberships = controller.membershipsForApartment(apartment.id);
    final historicalMemberships = memberships
        .where((membership) => !membership.isActive)
        .toList(growable: false);

    final currentEntry = _entriesFor(<ApartmentMembership>[currentMembership]);
    final counterpartEntries = _entriesFor(
      memberships
          .where(
            (membership) =>
                membership.isActive &&
                membership.residentId != widget.user.id &&
                membership.type != currentMembership.type,
          )
          .toList(growable: false),
    );
    final history = _entriesFor(historicalMemberships);
    final householdMembers = controller.householdMembersForApartment(
      apartment.id,
    );
    final hasVerifiedOwner = memberships.any(
      (membership) =>
          membership.isActive && membership.type == MembershipType.owner,
    );
    final hasActiveTenant = memberships.any(
      (membership) =>
          membership.isActive && membership.type == MembershipType.tenant,
    );
    final canManageHousehold =
        currentMembership.type == MembershipType.tenant || !hasActiveTenant;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin nơi ở',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Thông tin liên hệ giữa chủ sở hữu và người thuê được hiển thị để thuận tiện phối hợp khi cần.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ResidentApartmentOverviewCard(
                  apartment: apartment,
                  membership: currentMembership,
                ),
                const SizedBox(height: 16),
                _HouseholdSummary(
                  membershipType: currentMembership.type,
                  counterpartVerified:
                      currentMembership.type == MembershipType.owner
                      ? hasActiveTenant
                      : hasVerifiedOwner,
                  memberCount: householdMembers.length,
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final myRelationshipSection = HouseholdMemberSection(
                      title: 'Quan hệ cư trú của bạn',
                      subtitle: currentMembership.type == MembershipType.owner
                          ? 'Bạn là chủ sở hữu đã được ban quản lý xác minh'
                          : 'Bạn là người thuê đại diện đã được ban quản lý xác minh',
                      icon: currentMembership.type == MembershipType.owner
                          ? Icons.key_rounded
                          : Icons.home_work_outlined,
                      entries: currentEntry,
                    );
                    final counterpartSection = HouseholdMemberSection(
                      title: currentMembership.type == MembershipType.owner
                          ? 'Người thuê căn hộ'
                          : 'Chủ sở hữu căn hộ',
                      subtitle: currentMembership.type == MembershipType.owner
                          ? 'Người thuê đại diện đang được xác minh với căn hộ'
                          : 'Chủ sở hữu hợp pháp đang được xác minh với căn hộ',
                      icon: currentMembership.type == MembershipType.owner
                          ? Icons.home_work_outlined
                          : Icons.key_rounded,
                      entries: counterpartEntries,
                      emptyMessage:
                          currentMembership.type == MembershipType.owner
                          ? 'Chưa có người thuê đại diện đang hiệu lực.'
                          : 'Chưa ghi nhận chủ sở hữu đang hiệu lực.',
                    );

                    if (constraints.maxWidth < 760) {
                      return Column(
                        children: [
                          myRelationshipSection,
                          const SizedBox(height: 16),
                          counterpartSection,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: myRelationshipSection),
                        const SizedBox(width: 16),
                        Expanded(child: counterpartSection),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                HouseholdProfileSection(
                  members: householdMembers,
                  title: 'Thành viên do bạn khai báo',
                  subtitle: canManageHousehold
                      ? 'Danh sách riêng của tài khoản bạn, không chia sẻ với tài khoản còn lại'
                      : 'Căn hộ đang cho thuê; thành viên sinh sống do người thuê quản lý',
                  emptyMessage: 'Bạn chưa khai báo thành viên nào.',
                  onAdd: canManageHousehold
                      ? () => _showAddHouseholdMember(apartment.id)
                      : null,
                  onEnd: canManageHousehold ? _confirmEndHouseholdMember : null,
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _SectionHeading(
                    title: 'Lịch sử cư trú',
                    subtitle:
                        '${history.length} quan hệ đã kết thúc được lưu để đối chiếu',
                  ),
                  const SizedBox(height: 12),
                  HouseholdMemberSection(
                    title: 'Quan hệ trước đây',
                    subtitle: 'Thông tin chỉ để tra cứu, không còn hiệu lực',
                    icon: Icons.history_rounded,
                    entries: history,
                    showPeriod: true,
                  ),
                ],
                const SizedBox(height: 18),
                const _VerificationNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddHouseholdMember(String apartmentId) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HouseholdMemberEditorDialog(
        controller: widget.controller,
        apartmentId: apartmentId,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm thành viên vào hộ.')));
  }

  Future<void> _confirmEndHouseholdMember(HouseholdMember member) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Kết thúc cư trú?',
      message:
          '${member.fullName} sẽ được chuyển vào lịch sử thành viên của căn hộ.',
      confirmLabel: 'Kết thúc',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await widget.controller.endHouseholdMember(member.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã kết thúc cư trú của ${member.fullName}.'
              : widget.controller.errorMessage ?? 'Không thể cập nhật.',
        ),
      ),
    );
  }

  List<HouseholdMemberEntry> _entriesFor(
    List<ApartmentMembership> memberships, {
    MembershipType? type,
  }) {
    final entries = <HouseholdMemberEntry>[];
    for (final membership in memberships) {
      if (type != null && membership.type != type) continue;
      final resident = widget.controller.residentById(membership.residentId);
      if (resident == null) continue;
      entries.add(
        HouseholdMemberEntry(
          resident: resident,
          membership: membership,
          isCurrentUser: resident.id == widget.user.id,
        ),
      );
    }
    return List<HouseholdMemberEntry>.unmodifiable(entries);
  }
}

class _HouseholdSummary extends StatelessWidget {
  const _HouseholdSummary({
    required this.membershipType,
    required this.counterpartVerified,
    required this.memberCount,
  });

  final MembershipType membershipType;
  final bool counterpartVerified;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryChip(
          icon: Icons.key_rounded,
          label: membershipType == MembershipType.owner
              ? 'Vai trò: Chủ sở hữu'
              : 'Vai trò: Người thuê',
          foreground: AppColors.warning,
          background: AppColors.warningContainer,
        ),
        _SummaryChip(
          icon: counterpartVerified
              ? Icons.verified_user_outlined
              : Icons.shield_outlined,
          label: counterpartVerified
              ? 'Quan hệ còn lại đã xác minh'
              : 'Chưa có quan hệ còn lại',
          foreground: counterpartVerified ? AppColors.success : AppColors.info,
          background: counterpartVerified
              ? AppColors.successContainer
              : AppColors.infoContainer,
        ),
        _SummaryChip(
          icon: Icons.people_outline_rounded,
          label: '$memberCount thành viên của bạn',
          foreground: AppColors.success,
          background: AppColors.successContainer,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: AppColors.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin cư trú do ban quản lý xác nhận. Nếu có sai lệch, vui lòng liên hệ ban quản lý để được cập nhật.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
