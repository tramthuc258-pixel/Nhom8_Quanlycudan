import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/core/widgets/adaptive_modal.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/features/resident_services/models/resident_service.dart';

import 'resident_service_widgets.dart';

class ServiceBookingDraft {
  const ServiceBookingDraft({
    required this.quantity,
    required this.scheduledAt,
    required this.note,
  });

  final int quantity;
  final DateTime scheduledAt;
  final String note;
}

Future<ServiceBookingDraft?> showServiceBookingDialog(
  BuildContext context, {
  required ResidentService service,
}) {
  return showAdaptiveModal<ServiceBookingDraft>(
    context,
    maxWidth: 600,
    builder: (_) => _ServiceBookingDialog(service: service),
  );
}

class _ServiceBookingDialog extends StatefulWidget {
  const _ServiceBookingDialog({required this.service});

  final ResidentService service;

  @override
  State<_ServiceBookingDialog> createState() => _ServiceBookingDialogState();
}

class _ServiceBookingDialogState extends State<_ServiceBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  late DateTime _scheduledAt;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _noteController = TextEditingController();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _scheduledAt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return AdaptiveModalScaffold(
      title: 'Đăng ký dịch vụ',
      subtitle: service.name,
      icon: serviceCategoryIcon(service.category),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatServiceMoney(service.unitPrice)} / ${service.unitLabel}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${service.providerName} · ${service.contactPhone}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Số lượng (${service.unitLabel})',
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
              validator: (value) {
                final quantity = int.tryParse(value?.trim() ?? '');
                if (quantity == null || quantity < 1) {
                  return 'Số lượng phải từ 1 trở lên.';
                }
                if (quantity > 99) return 'Số lượng tối đa là 99.';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(
              'Thời gian mong muốn',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final date = OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(_dateLabel(_scheduledAt)),
                );
                final time = OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(_timeLabel(_scheduledAt)),
                );
                if (constraints.maxWidth < 390) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [date, const SizedBox(height: 8), time],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: date),
                    const SizedBox(width: 10),
                    Expanded(child: time),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
                hintText: 'Ví dụ: vui lòng gọi trước khi đến…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Tạm tính',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  formatServiceMoney(service.unitPrice * _quantity),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Để sau',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'Xác nhận',
          icon: Icons.check_rounded,
          onPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(now) ? now : _scheduledAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Chọn ngày sử dụng dịch vụ',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      helpText: 'Chọn giờ sử dụng dịch vụ',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian sử dụng phải ở tương lai.')),
      );
      return;
    }
    Navigator.pop(
      context,
      ServiceBookingDraft(
        quantity: _quantity,
        scheduledAt: _scheduledAt,
        note: _noteController.text.trim(),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year}';
}

String _timeLabel(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}';
}
