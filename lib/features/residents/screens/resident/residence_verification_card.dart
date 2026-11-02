import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/residence_verification.dart';

class ResidenceVerificationCard extends StatelessWidget {
  const ResidenceVerificationCard({
    required this.controller,
    required this.user,
    super.key,
  });

  final ApartmentMembershipController controller;
  final User user;

  @override
  Widget build(BuildContext context) {
    final item = controller.myVerification;
    final (title, message, icon, color, softColor) = _content(item);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173B76),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 20, 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final information = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Xác minh cư dân',
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: softColor,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            if (item.reviewNote?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer.withValues(
                                    alpha: .6,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 17,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        item.reviewNote!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                  final action = item.canSubmit
                      ? FilledButton.icon(
                          onPressed: controller.isLoading
                              ? null
                              : () => _openForm(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                          label: Text(
                            item.state == ResidenceVerificationState.rejected
                                ? 'Gửi lại yêu cầu'
                                : 'Xác minh căn hộ',
                          ),
                        )
                      : TextButton.icon(
                          onPressed: controller.isLoading
                              ? null
                              : controller.load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Làm mới'),
                        );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        information,
                        const SizedBox(height: 16),
                        action,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 20),
                      action,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final information = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: softColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'Xác minh cư dân',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: softColor,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                if (item.reviewNote?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer
                                          .withValues(alpha: .6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 17,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            item.reviewNote!,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                      final action = item.canSubmit
                          ? FilledButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => _openForm(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 19,
                              ),
                              label: Text(
                                item.state ==
                                        ResidenceVerificationState.rejected
                                    ? 'Gửi lại yêu cầu'
                                    : 'Xác minh căn hộ',
                              ),
                            )
                          : TextButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : controller.load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Làm mới'),
                            );
                      if (constraints.maxWidth < 680) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            information,
                            const SizedBox(height: 16),
                            action,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: information),
                          const SizedBox(width: 20),
                          action,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
*/

  Future<void> _openForm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _VerificationDialog(controller: controller, user: user),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu xác minh đến ban quản lý.')),
    );
  }

  (String, String, IconData, Color, Color) _content(
    ResidenceVerification item,
  ) => switch (item.state) {
    ResidenceVerificationState.notSubmitted => (
      'Chưa xác minh căn hộ',
      'Liên kết tài khoản với căn hộ để sử dụng đầy đủ tiện ích.',
      Icons.person_search_rounded,
      AppColors.primary,
      AppColors.primaryLight,
    ),
    ResidenceVerificationState.pending => (
      'Đang chờ ban quản lý duyệt',
      'Hồ sơ căn ${item.apartmentCode ?? ''} đang được kiểm tra.',
      Icons.hourglass_top_rounded,
      AppColors.warning,
      AppColors.warningContainer,
    ),
    ResidenceVerificationState.approved => (
      'Đã xác minh cư dân',
      '${item.apartmentCode ?? ''}${item.buildingName?.isNotEmpty ?? false ? ' · ${item.buildingName}' : ''} đã được liên kết với tài khoản.',
      Icons.verified_user_rounded,
      AppColors.success,
      AppColors.successContainer,
    ),
    ResidenceVerificationState.rejected => (
      'Cần bổ sung thông tin',
      'Thông tin chưa khớp. Xem phản hồi và gửi lại hồ sơ.',
      Icons.report_gmailerrorred_rounded,
      AppColors.error,
      AppColors.errorContainer,
    ),
  };
}

class _VerificationDialog extends StatefulWidget {
  const _VerificationDialog({required this.controller, required this.user});
  final ApartmentMembershipController controller;
  final User user;

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late final TextEditingController _phone;
  String? _apartmentId;
  MembershipType _type = MembershipType.tenant;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
      title: Row(
        children: [
          const _DialogIcon(),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Liên kết căn hộ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thông tin để ban quản lý đối chiếu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AccountSummary(user: widget.user),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại liên hệ',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    if (digits.length < 8 || digits.length > 11) {
                      return 'Vui lòng nhập số điện thoại hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _apartmentId,
                  decoration: const InputDecoration(
                    labelText: 'Căn hộ',
                    prefixIcon: Icon(Icons.apartment_rounded),
                  ),
                  items: widget.controller.verificationApartments
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.code} · ${item.buildingName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _apartmentId = value),
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn căn hộ.' : null,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bạn là',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<MembershipType>(
                    segments: const [
                      ButtonSegment(
                        value: MembershipType.owner,
                        icon: Icon(Icons.key_rounded),
                        label: Text('Chủ hộ'),
                      ),
                      ButtonSegment(
                        value: MembershipType.tenant,
                        icon: Icon(Icons.real_estate_agent_outlined),
                        label: Text('Người thuê'),
                      ),
                    ],
                    selected: {_type},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _type = value.first),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDate,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Bắt đầu cư trú',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _date(_startDate),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (không bắt buộc)',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Đang gửi…' : 'Gửi xác minh'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) setState(() => _startDate = value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await widget.controller.submitResidenceVerification(
      apartmentId: _apartmentId!,
      type: _type,
      startDate: _startDate,
      contactPhone: _phone.text,
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Không thể gửi yêu cầu.',
          ),
        ),
      );
    }
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.home_work_rounded, color: AppColors.primary),
    );
  }
}
