import 'package:flutter/material.dart';

import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/app_text_field.dart';
import 'package:homie/core/widgets/adaptive_modal.dart';
import 'package:homie/core/storage/file_upload_service.dart';

class MaintenanceRequestDraft {
  const MaintenanceRequestDraft({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.priority,
    required this.imageUrls,
  });

  final String title;
  final String description;
  final String location;
  final MaintenanceCategory category;
  final MaintenancePriority priority;
  final List<String> imageUrls;
}

Future<MaintenanceRequestDraft?> showMaintenanceRequestDialog(
  BuildContext context, {
  FileUploadService? fileUploadService,
}) {
  return showAdaptiveModal<MaintenanceRequestDraft>(
    context,
    maxWidth: 620,
    builder: (_) =>
        _MaintenanceRequestDialog(fileUploadService: fileUploadService),
  );
}

class _MaintenanceRequestDialog extends StatefulWidget {
  const _MaintenanceRequestDialog({this.fileUploadService});

  final FileUploadService? fileUploadService;

  @override
  State<_MaintenanceRequestDialog> createState() =>
      _MaintenanceRequestDialogState();
}

class _MaintenanceRequestDialogState extends State<_MaintenanceRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  MaintenanceCategory _category = MaintenanceCategory.plumbing;
  MaintenancePriority _priority = MaintenancePriority.normal;
  final List<UploadedHomieFile> _attachments = <UploadedHomieFile>[];
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveModalScaffold(
      title: 'Tạo yêu cầu sửa chữa',
      subtitle: 'Mô tả rõ sự cố để được hỗ trợ nhanh hơn',
      icon: Icons.home_repair_service_rounded,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _titleController,
              label: 'Tiêu đề',
              hint: 'Ví dụ: Vòi nước bếp bị rò rỉ',
              prefixIcon: Icons.title_rounded,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Nhập ít nhất 5 ký tự'
                  : null,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final category = DropdownButtonFormField<MaintenanceCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Loại sự cố',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final category in MaintenanceCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                );
                final priority = DropdownButtonFormField<MaintenancePriority>(
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mức ưu tiên',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: [
                    for (final priority in MaintenancePriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                );
                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [category, const SizedBox(height: 12), priority],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: 12),
                    Expanded(child: priority),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _locationController,
              label: 'Vị trí xảy ra sự cố',
              hint: 'Ví dụ: Bếp, phòng ngủ, hành lang tầng 12',
              prefixIcon: Icons.place_outlined,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Vui lòng nhập vị trí'
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descriptionController,
              label: 'Mô tả chi tiết',
              hint: 'Mô tả dấu hiệu, thời điểm và mức độ ảnh hưởng…',
              prefixIcon: Icons.notes_rounded,
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 6,
              maxLength: 500,
              validator: (value) => (value?.trim().length ?? 0) < 15
                  ? 'Mô tả cần ít nhất 15 ký tự'
                  : null,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ảnh hiện trường',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Không bắt buộc · tối đa 5 tệp JPG, PNG, WebP hoặc PDF.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (var index = 0; index < _attachments.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _attachments[index].fileName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Bỏ tệp',
                              visualDensity: VisualDensity.compact,
                              onPressed: _isUploading
                                  ? null
                                  : () => setState(
                                      () => _attachments.removeAt(index),
                                    ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (_uploadError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _uploadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed:
                        widget.fileUploadService == null ||
                            _isUploading ||
                            _attachments.length >= 5
                        ? null
                        : _uploadAttachment,
                    icon: _isUploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _isUploading ? 'Đang tải tệp…' : 'Thêm ảnh hoặc PDF',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Hủy',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Gửi yêu cầu',
          icon: Icons.send_rounded,
          onPressed: _isUploading ? null : _submit,
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      MaintenanceRequestDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _category,
        priority: _priority,
        imageUrls: List<String>.unmodifiable(
          _attachments.map((attachment) => attachment.url),
        ),
      ),
    );
  }

  Future<void> _uploadAttachment() async {
    final service = widget.fileUploadService;
    if (service == null || _isUploading || _attachments.length >= 5) return;
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    try {
      final file = await service.pickAndUpload(category: 'maintenance');
      if (!mounted) return;
      setState(() {
        if (file != null) _attachments.add(file);
        _isUploading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploadError = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('ApiException: ', '');
        _isUploading = false;
      });
    }
  }
}
