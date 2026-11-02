import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/app_text_field.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

import 'housing_presentation_helpers.dart';

class HousingApplicationDraft {
  const HousingApplicationDraft({
    required this.phone,
    required this.preferredStartDate,
    required this.preferredEndDate,
    required this.note,
  });

  final String phone;
  final DateTime preferredStartDate;
  final DateTime? preferredEndDate;
  final String note;
}

Future<HousingApplicationDraft?> showHousingApplicationFormDialog(
  BuildContext context, {
  required HousingListing listing,
}) {
  return showDialog<HousingApplicationDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _HousingApplicationFormDialog(listing: listing),
  );
}

class _HousingApplicationFormDialog extends StatefulWidget {
  const _HousingApplicationFormDialog({required this.listing});

  final HousingListing listing;

  @override
  State<_HousingApplicationFormDialog> createState() =>
      _HousingApplicationFormDialogState();
}

class _HousingApplicationFormDialogState
    extends State<_HousingApplicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _noteController;
  late DateTime _startDate;
  DateTime? _endDate;

  bool get _isRent =>
      widget.listing.transactionType == HousingTransactionType.rent;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _noteController = TextEditingController();
    final now = DateUtils.dateOnly(DateTime.now());
    final available = DateUtils.dateOnly(widget.listing.availableFrom);
    _startDate = available.isAfter(now) ? available : now;
    if (_isRent) {
      _endDate = DateTime(
        _startDate.year + 1,
        _startDate.month,
        _startDate.day,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isRent ? Icons.key_rounded : Icons.home_work_rounded,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRent
                                ? 'Đăng ký thuê căn hộ'
                                : 'Đăng ký mua căn hộ',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.listing.apartmentCode} · ${widget.listing.buildingName}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments_outlined, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${formatHousingMoney(widget.listing.price)}${widget.listing.transactionType.priceUnit}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại liên hệ',
                  hint: 'Ví dụ: 0901234567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ .-]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    if (digits.length < 9 || digits.length > 11) {
                      return 'Số điện thoại phải có từ 9 đến 11 chữ số.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Thời gian mong muốn',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final start = _DateButton(
                      label: 'Ngày bắt đầu',
                      value: _startDate,
                      icon: Icons.event_available_outlined,
                      onPressed: _pickStartDate,
                    );
                    final end = _DateButton(
                      label: 'Ngày kết thúc thuê',
                      value: _endDate,
                      icon: Icons.event_busy_outlined,
                      onPressed: _pickEndDate,
                    );
                    if (!_isRent) return start;
                    if (constraints.maxWidth < 480) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [start, const SizedBox(height: 10), end],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: start),
                        const SizedBox(width: 10),
                        Expanded(child: end),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _noteController,
                  label: 'Ghi chú (không bắt buộc)',
                  hint: _isRent
                      ? 'Ví dụ: số người ở, thời hạn thuê mong muốn…'
                      : 'Thông tin bổ sung dành cho ban quản lý…',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Hồ sơ sẽ được gửi đến ban quản lý để xác minh. Việc nộp hồ sơ chưa tạo quan hệ cư trú hoặc sở hữu.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Để sau',
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppButton(
                        label: 'Gửi hồ sơ',
                        icon: Icons.send_outlined,
                        onPressed: _submit,
                      ),
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

  Future<void> _pickStartDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final available = DateUtils.dateOnly(widget.listing.availableFrom);
    final firstDate = available.isAfter(now) ? available : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(firstDate) ? firstDate : _startDate,
      firstDate: firstDate,
      lastDate: DateTime(firstDate.year + 5, 12, 31),
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked;
      if (_isRent && (_endDate == null || !_endDate!.isAfter(picked))) {
        _endDate = DateTime(picked.year + 1, picked.month, picked.day);
      }
    });
  }

  Future<void> _pickEndDate() async {
    final firstDate = _startDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate != null && _endDate!.isAfter(_startDate)
          ? _endDate!
          : firstDate,
      firstDate: firstDate,
      lastDate: DateTime(_startDate.year + 5, 12, 31),
      helpText: 'Chọn ngày kết thúc thuê',
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isRent && (_endDate == null || !_endDate!.isAfter(_startDate))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc thuê phải sau ngày bắt đầu.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      HousingApplicationDraft(
        phone: _phoneController.text.trim(),
        preferredStartDate: _startDate,
        preferredEndDate: _isRent ? _endDate : null,
        note: _noteController.text.trim(),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value == null ? 'Chưa chọn' : formatHousingDate(value!),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
