import 'package:flutter/material.dart';

import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';

class HouseholdMemberEditorDialog extends StatefulWidget {
  const HouseholdMemberEditorDialog({
    required this.controller,
    required this.apartmentId,
    super.key,
  });

  final ApartmentMembershipController controller;
  final String apartmentId;

  @override
  State<HouseholdMemberEditorDialog> createState() =>
      _HouseholdMemberEditorDialogState();
}

class _HouseholdMemberEditorDialogState
    extends State<HouseholdMemberEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime _startDate = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thêm thành viên trong hộ',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Thành viên được lưu như hồ sơ cư trú và không có tài khoản đăng nhập riêng.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Vui lòng nhập họ và tên.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _relationshipController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Quan hệ với người đại diện *',
                    hintText: 'Ví dụ: vợ, chồng, con, cha, mẹ',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Vui lòng nhập quan hệ.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại (không bắt buộc)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                _DateInput(
                  label: 'Ngày sinh (không bắt buộc)',
                  value: _dateOfBirth,
                  onTap: _pickBirthDate,
                ),
                const SizedBox(height: 14),
                _DateInput(
                  label: 'Ngày bắt đầu cư trú *',
                  value: _startDate,
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Hủy',
                      variant: AppButtonVariant.text,
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Lưu thành viên',
                      icon: Icons.save_outlined,
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (value != null) setState(() => _dateOfBirth = value);
  }

  Future<void> _pickStartDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (value != null) setState(() => _startDate = value);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final success = await widget.controller.addHouseholdMember(
      apartmentId: widget.apartmentId,
      fullName: _nameController.text,
      dateOfBirth: _dateOfBirth,
      phone: _phoneController.text,
      relationship: _relationshipController.text,
      startDate: _startDate,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = widget.controller.errorMessage ?? 'Không thể lưu thành viên.';
    });
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Chưa chọn' : _formatDate(value!)),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
