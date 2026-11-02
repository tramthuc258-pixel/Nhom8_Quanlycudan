import 'package:flutter/material.dart';

import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

import 'housing_presentation_helpers.dart';

class HousingApplicationCard extends StatelessWidget {
  const HousingApplicationCard({
    required this.application,
    required this.listing,
    required this.onView,
    this.showApplicant = false,
    this.compact = false,
    this.onReject,
    this.onRecordContract,
    super.key,
  });

  final HousingApplication application;
  final HousingListing? listing;
  final VoidCallback onView;
  final bool showApplicant;
  final bool compact;
  final VoidCallback? onReject;
  final VoidCallback? onRecordContract;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.code,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing == null
                              ? application.apartmentId
                              : '${listing!.apartmentCode} · ${listing!.buildingName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  HousingApplicationStatusBadge(status: application.status),
                ],
              ),
              const SizedBox(height: 12),
              HousingTransactionBadge(type: application.transactionType),
              const SizedBox(height: 13),
              if (showApplicant)
                _CompactRow(
                  icon: Icons.person_outline_rounded,
                  text: application.applicantFullName,
                ),
              _CompactRow(
                icon: Icons.phone_outlined,
                text: application.applicantPhone,
              ),
              _CompactRow(
                icon: Icons.event_available_outlined,
                text:
                    'Bắt đầu ${formatHousingDate(application.preferredStartDate)}',
              ),
              if (application.transactionType == HousingTransactionType.rent &&
                  application.preferredEndDate != null)
                _CompactRow(
                  icon: Icons.event_busy_outlined,
                  text:
                      'Kết thúc ${formatHousingDate(application.preferredEndDate!)}',
                ),
              if (compact) const SizedBox(height: 12) else const Spacer(),
              Text(
                'Gửi lúc ${formatHousingDateTime(application.submittedAt)}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (application.canBeReviewed &&
                  onRecordContract != null &&
                  onReject != null)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Từ chối',
                        icon: Icons.close_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: onReject,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Ghi hợp đồng',
                        icon: Icons.handshake_outlined,
                        onPressed: onRecordContract,
                      ),
                    ),
                  ],
                )
              else
                AppButton(
                  label: 'Xem chi tiết',
                  icon: Icons.visibility_outlined,
                  expand: true,
                  variant: AppButtonVariant.outlined,
                  onPressed: onView,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colors.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

enum HousingApplicationDetailAction { recordContract, reject }

Future<HousingApplicationDetailAction?> showHousingApplicationDetailDialog(
  BuildContext context, {
  required HousingApplication application,
  required HousingListing? listing,
  bool allowReview = false,
}) {
  return showDialog<HousingApplicationDetailAction>(
    context: context,
    builder: (_) => _HousingApplicationDetailDialog(
      application: application,
      listing: listing,
      allowReview: allowReview,
    ),
  );
}

class _HousingApplicationDetailDialog extends StatelessWidget {
  const _HousingApplicationDetailDialog({
    required this.application,
    required this.listing,
    required this.allowReview,
  });

  final HousingApplication application;
  final HousingListing? listing;
  final bool allowReview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.code,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chi tiết hồ sơ ${application.transactionType == HousingTransactionType.rent ? 'thuê' : 'mua'}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  HousingApplicationStatusBadge(status: application.status),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 30),
              _DetailRow(
                icon: Icons.apartment_outlined,
                label: 'Căn hộ',
                value: listing == null
                    ? application.apartmentId
                    : '${listing!.apartmentCode} · ${listing!.buildingName}',
              ),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Người đăng ký',
                value: application.applicantFullName,
              ),
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: application.applicantEmail,
              ),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Điện thoại',
                value: application.applicantPhone,
              ),
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Hình thức',
                value: application.transactionType.label,
              ),
              _DetailRow(
                icon: Icons.event_available_outlined,
                label: 'Ngày bắt đầu',
                value: formatHousingDate(application.preferredStartDate),
              ),
              if (application.preferredEndDate != null)
                _DetailRow(
                  icon: Icons.event_busy_outlined,
                  label: 'Ngày kết thúc',
                  value: formatHousingDate(application.preferredEndDate!),
                ),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Ngày nộp',
                value: formatHousingDateTime(application.submittedAt),
              ),
              if (application.note.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _NoteBox(
                  title: 'Ghi chú của người đăng ký',
                  value: application.note,
                ),
              ],
              if (application.reviewedAt != null) ...[
                const SizedBox(height: 14),
                _NoteBox(
                  title: 'Kết quả xét duyệt',
                  value: [
                    if ((application.reviewNote ?? '').trim().isNotEmpty)
                      application.reviewNote!.trim(),
                    'Xử lý bởi ${application.reviewedBy ?? 'Ban quản lý'} lúc ${formatHousingDateTime(application.reviewedAt!)}',
                  ].join('\n'),
                  highlighted: true,
                ),
              ],
              if (application.contractNumber != null) ...[
                const SizedBox(height: 14),
                _NoteBox(
                  title: 'Thông tin hợp đồng',
                  value: [
                    'Mã hợp đồng: ${application.contractNumber}',
                    if (application.contractSignedAt != null)
                      'Ngày ký: ${formatHousingDate(application.contractSignedAt!)}',
                    if (application.effectiveDate != null)
                      'Ngày hiệu lực: ${formatHousingDate(application.effectiveDate!)}',
                  ].join('\n'),
                  highlighted: true,
                ),
              ],
              const SizedBox(height: 22),
              if (allowReview && application.canBeReviewed)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Từ chối hồ sơ',
                        icon: Icons.close_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.pop(
                          context,
                          HousingApplicationDetailAction.reject,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Ghi nhận hợp đồng',
                        icon: Icons.handshake_outlined,
                        onPressed: () => Navigator.pop(
                          context,
                          HousingApplicationDetailAction.recordContract,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Đóng',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 5),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

Future<String?> showHousingRejectionDialog(
  BuildContext context, {
  required HousingApplication application,
}) {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.cancel_outlined,
        color: Theme.of(dialogContext).colorScheme.error,
      ),
      title: const Text('Từ chối hồ sơ?'),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hãy cho ${application.applicantFullName} biết lý do hồ sơ chưa được chấp nhận.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().length < 5
                    ? 'Vui lòng nhập ít nhất 5 ký tự.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Quay lại'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(dialogContext, controller.text.trim());
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Xác nhận từ chối'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class HousingContractDraft {
  const HousingContractDraft({
    required this.contractNumber,
    required this.signedAt,
    required this.effectiveDate,
    required this.note,
  });

  final String contractNumber;
  final DateTime signedAt;
  final DateTime effectiveDate;
  final String note;
}

Future<HousingContractDraft?> showHousingContractDialog(
  BuildContext context, {
  required HousingApplication application,
}) {
  return showDialog<HousingContractDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _HousingContractDialog(application: application),
  );
}

class _HousingContractDialog extends StatefulWidget {
  const _HousingContractDialog({required this.application});

  final HousingApplication application;

  @override
  State<_HousingContractDialog> createState() => _HousingContractDialogState();
}

class _HousingContractDialogState extends State<_HousingContractDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contractNumberController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _signedAt;
  late DateTime _effectiveDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _signedAt = DateTime(now.year, now.month, now.day);
    final preferred = widget.application.preferredStartDate;
    _effectiveDate = preferred.isBefore(_signedAt) ? _signedAt : preferred;
  }

  @override
  void dispose() {
    _contractNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.handshake_outlined),
      title: const Text('Ghi nhận hợp đồng'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chỉ ghi nhận sau khi ban quản lý đã kiểm tra hợp đồng ký bên ngoài ứng dụng với ${widget.application.applicantFullName}.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contractNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã hợp đồng *',
                    hintText: 'Ví dụ: HD-2026-001',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().length < 4
                      ? 'Mã hợp đồng cần ít nhất 4 ký tự'
                      : null,
                ),
                const SizedBox(height: 14),
                _ContractDateField(
                  label: 'Ngày ký hợp đồng',
                  value: _signedAt,
                  onTap: () => _pickDate(isEffectiveDate: false),
                ),
                const SizedBox(height: 14),
                _ContractDateField(
                  label: 'Ngày có hiệu lực',
                  value: _effectiveDate,
                  onTap: () => _pickDate(isEffectiveDate: true),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú kiểm tra',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Ghi nhận hợp đồng'),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isEffectiveDate}) async {
    final initial = isEffectiveDate ? _effectiveDate : _signedAt;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isEffectiveDate) {
        _effectiveDate = selected;
      } else {
        _signedAt = selected;
        if (_effectiveDate.isBefore(_signedAt)) _effectiveDate = _signedAt;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_effectiveDate.isBefore(_signedAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày hiệu lực không được trước ngày ký hợp đồng.'),
        ),
      );
      return;
    }
    final endDate = widget.application.preferredEndDate;
    if (endDate != null && !endDate.isAfter(_effectiveDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc thuê phải sau ngày hiệu lực.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      HousingContractDraft(
        contractNumber: _contractNumberController.text.trim(),
        signedAt: _signedAt,
        effectiveDate: _effectiveDate,
        note: _noteController.text.trim(),
      ),
    );
  }
}

class _ContractDateField extends StatelessWidget {
  const _ContractDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(formatHousingDate(value)),
      ),
    );
  }
}
