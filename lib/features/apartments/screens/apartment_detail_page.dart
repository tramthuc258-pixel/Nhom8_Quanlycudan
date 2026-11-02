import 'package:flutter/material.dart';

import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/apartments/widgets/apartment_status_badge.dart';
import 'package:homie/features/apartments/widgets/apartment_editor_dialog.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/features/residents/models/household_member.dart';
import 'package:homie/features/residents/widgets/membership_summary_card.dart';
import 'package:homie/features/residents/widgets/resident/household_member_editor_dialog.dart';
import 'package:homie/features/residents/widgets/resident/household_profile_section.dart';
import 'package:homie/core/widgets/confirm_dialog.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';

class ApartmentDetailPage extends StatefulWidget {
  const ApartmentDetailPage({
    required this.controller,
    required this.apartmentId,
    super.key,
  });

  final ApartmentMembershipController controller;
  final String apartmentId;

  @override
  State<ApartmentDetailPage> createState() => _ApartmentDetailPageState();
}

class _ApartmentDetailPageState extends State<ApartmentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.apartments.isEmpty &&
          !widget.controller.isLoading) {
        widget.controller.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final apartment = widget.controller.apartmentById(widget.apartmentId);
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            title: Text(
              apartment == null
                  ? 'Chi tiết căn hộ'
                  : 'Căn hộ ${apartment.code}',
            ),
            actions: [
              if (apartment != null)
                IconButton(
                  tooltip: 'Chỉnh sửa căn hộ',
                  onPressed: widget.controller.isLoading
                      ? null
                      : () => _showEditApartment(apartment),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (apartment != null)
                IconButton(
                  tooltip: 'Xóa căn hộ',
                  onPressed: widget.controller.isLoading
                      ? null
                      : () => _confirmDeleteApartment(apartment),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              if (apartment != null && MediaQuery.sizeOf(context).width >= 600)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AppButton(
                    label: 'Thêm cư dân',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: () => _showAddMembership(apartment),
                  ),
                ),
            ],
          ),
          floatingActionButton:
              apartment != null && MediaQuery.sizeOf(context).width < 600
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddMembership(apartment),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Thêm cư dân'),
                )
              : null,
          body: _buildBody(apartment),
        );
      },
    );
  }

  Widget _buildBody(Apartment? apartment) {
    if (widget.controller.isLoading && apartment == null) {
      return const LoadingView(message: 'Đang tải thông tin căn hộ…');
    }
    if (apartment == null) {
      return ErrorView(
        title: 'Không tìm thấy căn hộ',
        message:
            widget.controller.errorMessage ??
            'Căn hộ có thể đã bị xóa hoặc dữ liệu chưa được đồng bộ.',
        onRetry: widget.controller.load,
      );
    }

    final allMemberships = widget.controller.membershipsForApartment(
      apartment.id,
    );
    final activeMemberships =
        allMemberships.where((membership) => membership.isActive).toList()
          ..sort(_compareMemberships);
    final history =
        allMemberships.where((membership) => !membership.isActive).toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final householdMembers = widget.controller.householdMembersForApartment(
      apartment.id,
    );

    return RefreshIndicator(
      onRefresh: widget.controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ApartmentHero(
                    apartment: apartment,
                    activeResidentCount: activeMemberships.length,
                  ),
                  if (widget.controller.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(message: widget.controller.errorMessage!),
                  ],
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Tài khoản đại diện',
                    subtitle:
                        '${activeMemberships.length}/2 tài khoản đang liên kết',
                  ),
                  const SizedBox(height: 12),
                  if (activeMemberships.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: EmptyView(
                        title: 'Chưa có tài khoản đại diện',
                        message: 'Liên kết một chủ sở hữu hoặc một người thuê đại diện.',
                        icon: Icons.group_add_outlined,
                        actionLabel: 'Thêm cư dân',
                        onAction: () => _showAddMembership(apartment),
                      ),
                    )
                  else
                    _MembershipGrid(
                      memberships: activeMemberships,
                      controller: widget.controller,
                      onEnd: _confirmEndMembership,
                    ),
                  const SizedBox(height: 26),
                  HouseholdProfileSection(
                    members: householdMembers,
                    onAdd: () => _showAddHouseholdMember(apartment),
                    onEnd: _confirmEndHouseholdMember,
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(
                    title: 'Lịch sử tài khoản đại diện',
                    subtitle: 'Các chủ sở hữu và người thuê đã kết thúc',
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    const Card(
                      margin: EdgeInsets.zero,
                      child: EmptyView(
                        title: 'Chưa có lịch sử',
                        message: 'Quan hệ đã kết thúc sẽ được lưu tại đây để dễ tra cứu.',
                        icon: Icons.history_rounded,
                      ),
                    )
                  else
                    _MembershipGrid(
                      memberships: history,
                      controller: widget.controller,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMembership(Apartment apartment) async {
    final activeMemberships = widget.controller
        .membershipsForApartment(apartment.id, includeEnded: false)
        .where((membership) => membership.isActive)
        .toList();
    final hasActiveOwner = activeMemberships.any(
      (membership) => membership.type == MembershipType.owner,
    );
    final hasActiveTenant = activeMemberships.any(
      (membership) => membership.type == MembershipType.tenant,
    );
    if (hasActiveOwner && hasActiveTenant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Căn hộ đã có đủ một chủ sở hữu và một người thuê đại diện.',
          ),
        ),
      );
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddMembershipDialog(
        controller: widget.controller,
        apartment: apartment,
        allowOwner: !hasActiveOwner,
        allowTenant: !hasActiveTenant,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã thêm cư dân vào căn ${apartment.code}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showAddHouseholdMember(Apartment apartment) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HouseholdMemberEditorDialog(
        controller: widget.controller,
        apartmentId: apartment.id,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm thành viên vào căn ${apartment.code}.')),
    );
  }

  Future<void> _confirmEndHouseholdMember(HouseholdMember member) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Kết thúc cư trú?',
      message: '${member.fullName} sẽ được chuyển vào lịch sử thành viên.',
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

  Future<void> _showEditApartment(Apartment apartment) async {
    widget.controller.clearError();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApartmentEditorDialog(
        controller: widget.controller,
        apartment: apartment,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin căn hộ.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmDeleteApartment(Apartment apartment) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xóa căn hộ ${apartment.code}?',
      message: 'Căn hộ chỉ có thể bị xóa khi chưa có cư dân hoặc lịch sử cư trú. Thao tác này không thể hoàn tác.',
      confirmLabel: 'Xóa căn hộ',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final success = await widget.controller.deleteApartment(apartment.id);
    if (!mounted) return;
    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Đã xóa căn hộ ${apartment.code}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Không thể xóa căn hộ.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  Future<void> _confirmEndMembership(
    ApartmentMembership membership,
    Resident resident,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Kết thúc quan hệ cư trú?',
      message:
          '${resident.fullName} sẽ không còn quyền truy cập căn hộ theo vai trò ${membership.type.displayName.toLowerCase()}. Lịch sử vẫn được lưu lại.',
      confirmLabel: 'Kết thúc',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final success = await widget.controller.endMembership(membership.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã kết thúc quan hệ cư trú của ${resident.fullName}.'
                : widget.controller.errorMessage ??
                      'Không thể cập nhật dữ liệu.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        ),
      );
  }
}

class _ApartmentHero extends StatelessWidget {
  const _ApartmentHero({
    required this.apartment,
    required this.activeResidentCount,
  });

  final Apartment apartment;
  final int activeResidentCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final identity = Row(
              children: [
                Container(
                  width: compact ? 54 : 64,
                  height: compact ? 54 : 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3157D5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Căn hộ ${apartment.code}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${apartment.buildingName} • Tầng ${apartment.floor}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final facts = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ApartmentStatusBadge(status: apartment.status, compact: false),
                _FactPill(
                  icon: Icons.square_foot_rounded,
                  label: '${_formatArea(apartment.area)} m²',
                ),
                _FactPill(
                  icon: Icons.bed_outlined,
                  label: '${apartment.bedrooms} phòng ngủ',
                ),
                _FactPill(
                  icon: Icons.groups_2_outlined,
                  label: '$activeResidentCount người đang liên kết',
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [identity, const SizedBox(height: 18), facts],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 24),
                Flexible(child: facts),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MembershipGrid extends StatelessWidget {
  const _MembershipGrid({
    required this.memberships,
    required this.controller,
    this.onEnd,
  });

  final List<ApartmentMembership> memberships;
  final ApartmentMembershipController controller;
  final void Function(ApartmentMembership, Resident)? onEnd;

  @override
  Widget build(BuildContext context) {
    final entries = memberships
        .map(
          (membership) =>
              (membership, controller.residentById(membership.residentId)),
        )
        .where((entry) => entry.$2 != null)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 840 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 190,
          ),
          itemBuilder: (context, index) {
            final membership = entries[index].$1;
            final resident = entries[index].$2!;
            return MembershipSummaryCard(
              membership: membership,
              resident: resident,
              onEnd: onEnd == null ? null : () => onEnd!(membership, resident),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMembershipDialog extends StatefulWidget {
  const _AddMembershipDialog({
    required this.controller,
    required this.apartment,
    required this.allowOwner,
    required this.allowTenant,
  });

  final ApartmentMembershipController controller;
  final Apartment apartment;
  final bool allowOwner;
  final bool allowTenant;

  @override
  State<_AddMembershipDialog> createState() => _AddMembershipDialogState();
}

class _AddMembershipDialogState extends State<_AddMembershipDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  late MembershipType _type;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _type = widget.allowOwner ? MembershipType.owner : MembershipType.tenant;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm cư dân',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Căn hộ ${widget.apartment.code}',
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
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        _InlineError(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Vui lòng nhập họ và tên.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final phone = TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại *',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: _validatePhone,
                          );
                          final email = TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: _validateEmail,
                          );
                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                phone,
                                const SizedBox(height: 14),
                                email,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: phone),
                              const SizedBox(width: 12),
                              Expanded(child: email),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<MembershipType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Vai trò với căn hộ *',
                          prefixIcon: Icon(Icons.manage_accounts_outlined),
                        ),
                        items: [
                          for (final type in const [
                            MembershipType.owner,
                            MembershipType.tenant,
                          ])
                            if ((type != MembershipType.owner ||
                                    widget.allowOwner) &&
                                (type != MembershipType.tenant ||
                                    widget.allowTenant))
                              DropdownMenuItem(
                                value: type,
                                child: Text(type.displayName),
                              ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _type = value);
                        },
                      ),
                      if (!widget.allowOwner) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Căn hộ đã có chủ sở hữu đang hiệu lực.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final start = _DateField(
                            label: 'Ngày bắt đầu *',
                            value: _startDate,
                            onTap: _pickStartDate,
                          );
                          final end = _DateField(
                            label: 'Ngày kết thúc (không bắt buộc)',
                            value: _endDate,
                            onTap: _pickEndDate,
                            onClear: _endDate == null
                                ? null
                                : () => setState(() => _endDate = null),
                          );
                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                start,
                                const SizedBox(height: 14),
                                end,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: start),
                              const SizedBox(width: 12),
                              Expanded(child: end),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Hủy',
                    variant: AppButtonVariant.text,
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Lưu quan hệ',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 11) {
      return 'Số điện thoại không hợp lệ.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (value == null) return;
    setState(() {
      _startDate = value;
      if (_endDate != null && _endDate!.isBefore(value)) _endDate = null;
    });
  }

  Future<void> _pickEndDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (value != null) setState(() => _endDate = value);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final success = await widget.controller.addMembership(
      apartmentId: widget.apartment.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      type: _type,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _errorMessage =
          widget.controller.errorMessage ?? 'Không thể thêm cư dân lúc này.';
    });
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: onClear == null
              ? const Icon(Icons.arrow_drop_down_rounded)
              : IconButton(
                  tooltip: 'Xóa ngày',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        child: Text(value == null ? 'Chưa chọn' : _formatDate(value!)),
      ),
    );
  }
}

int _compareMemberships(ApartmentMembership first, ApartmentMembership second) {
  final roleComparison = first.type.index.compareTo(second.type.index);
  if (roleComparison != 0) return roleComparison;
  return first.startDate.compareTo(second.startDate);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatArea(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
