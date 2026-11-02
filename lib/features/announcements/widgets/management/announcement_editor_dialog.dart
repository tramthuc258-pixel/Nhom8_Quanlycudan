import 'package:flutter/material.dart';

import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/features/staff_assignments/models/staff_scope.dart';

class AnnouncementFormData {
  const AnnouncementFormData({
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.audience,
    required this.publishedAt,
    required this.expiresAt,
    required this.isPinned,
    required this.isPublished,
    required this.buildingId,
  });

  final String title;
  final String content;
  final AnnouncementCategory category;
  final AnnouncementPriority priority;
  final AnnouncementAudience audience;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isPinned;
  final bool isPublished;
  final String? buildingId;
}

Future<AnnouncementFormData?> showAnnouncementEditorDialog(
  BuildContext context, {
  required List<BuildingScope> buildings,
  required bool allowGlobal,
}) {
  return showDialog<AnnouncementFormData>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AnnouncementEditorDialog(
      buildings: buildings,
      allowGlobal: allowGlobal,
    ),
  );
}

class _AnnouncementEditorDialog extends StatefulWidget {
  const _AnnouncementEditorDialog({
    required this.buildings,
    required this.allowGlobal,
  });

  final List<BuildingScope> buildings;
  final bool allowGlobal;

  @override
  State<_AnnouncementEditorDialog> createState() =>
      _AnnouncementEditorDialogState();
}

class _AnnouncementEditorDialogState extends State<_AnnouncementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  AnnouncementCategory _category = AnnouncementCategory.general;
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  AnnouncementAudience _audience = AnnouncementAudience.all;
  late DateTime _publishedAt;
  DateTime? _expiresAt;
  bool _isPinned = false;
  bool _isPublished = true;
  String? _buildingId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _publishedAt = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    if (!widget.allowGlobal && widget.buildings.isNotEmpty) {
      _buildingId = widget.buildings.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 620;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 0 : 32,
        vertical: isCompact ? 0 : 32,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: size.height * (isCompact ? 1 : 0.9),
        ),
        child: Column(
          children: [
            _DialogHeader(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 24,
                    20,
                    isCompact ? 16 : 24,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                        icon: Icons.edit_note_rounded,
                        label: 'Nội dung thông báo',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        autofocus: !isCompact,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'Ví dụ: Lịch bảo trì thang máy tòa A',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Vui lòng nhập tiêu đề';
                          if (text.length < 6) {
                            return 'Tiêu đề cần có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _contentController,
                        minLines: 5,
                        maxLines: 9,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung *',
                          hintText: 'Mô tả đầy đủ nội dung cư dân cần biết…',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Vui lòng nhập nội dung';
                          if (text.length < 20) {
                            return 'Nội dung cần có ít nhất 20 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _SectionLabel(
                        icon: Icons.tune_rounded,
                        label: 'Phân loại và đối tượng',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: _buildingId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Phạm vi tòa nhà *',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        items: [
                          if (widget.allowGlobal)
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Toàn hệ thống'),
                            ),
                          for (final building in widget.buildings)
                            DropdownMenuItem<String?>(
                              value: building.id,
                              child: Text(
                                '${building.code} · ${building.name}',
                              ),
                            ),
                        ],
                        validator: (value) {
                          if (!widget.allowGlobal && value == null) {
                            return 'Vui lòng chọn tòa nhà được phân công';
                          }
                          return null;
                        },
                        onChanged: (value) =>
                            setState(() => _buildingId = value),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fields = [
                            DropdownButtonFormField<AnnouncementCategory>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Danh mục',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: AnnouncementCategory.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                            ),
                            DropdownButtonFormField<AnnouncementPriority>(
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Mức độ ưu tiên',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: AnnouncementPriority.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _priority = value);
                                }
                              },
                            ),
                            DropdownButtonFormField<AnnouncementAudience>(
                              initialValue: _audience,
                              decoration: const InputDecoration(
                                labelText: 'Đối tượng nhận',
                                prefixIcon: Icon(Icons.groups_outlined),
                              ),
                              items: AnnouncementAudience.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _audience = value);
                                }
                              },
                            ),
                          ];

                          if (constraints.maxWidth < 600) {
                            return Column(
                              children: [
                                for (var i = 0; i < fields.length; i++) ...[
                                  fields[i],
                                  if (i != fields.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < fields.length; i++) ...[
                                Expanded(child: fields[i]),
                                if (i != fields.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        icon: Icons.calendar_month_outlined,
                        label: 'Thời gian hiển thị',
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final start = _DateTimeField(
                            label: 'Thời điểm phát hành',
                            value: _publishedAt,
                            required: true,
                            onTap: _pickPublishedAt,
                          );
                          final end = _DateTimeField(
                            label: 'Thời điểm hết hạn',
                            value: _expiresAt,
                            onTap: _pickExpiresAt,
                            onClear: _expiresAt == null
                                ? null
                                : () => setState(() => _expiresAt = null),
                          );

                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                start,
                                const SizedBox(height: 12),
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
                      if (_expiresAt != null &&
                          !_expiresAt!.isAfter(_publishedAt)) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Thời điểm hết hạn phải sau thời điểm phát hành.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _OptionTile(
                        icon: Icons.push_pin_outlined,
                        title: 'Ghim thông báo',
                        subtitle:
                            'Ưu tiên hiển thị thông báo này ở đầu danh sách.',
                        value: _isPinned,
                        onChanged: (value) => setState(() => _isPinned = value),
                      ),
                      const SizedBox(height: 10),
                      _OptionTile(
                        icon: Icons.campaign_outlined,
                        title: 'Phát hành thông báo',
                        subtitle: _isPublished
                            ? 'Cư dân sẽ thấy thông báo theo lịch đã chọn.'
                            : 'Lưu dưới dạng bản nháp, chưa hiển thị cho cư dân.',
                        value: _isPublished,
                        onChanged: (value) =>
                            setState(() => _isPublished = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Hủy',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: _isPublished ? 'Tạo và phát hành' : 'Lưu bản nháp',
                    icon: _isPublished
                        ? Icons.campaign_rounded
                        : Icons.save_outlined,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPublishedAt() async {
    final value = await _pickDateTime(_publishedAt);
    if (value == null || !mounted) return;
    setState(() => _publishedAt = value);
  }

  Future<void> _pickExpiresAt() async {
    final initial = _expiresAt ?? _publishedAt.add(const Duration(days: 7));
    final value = await _pickDateTime(initial);
    if (value == null || !mounted) return;
    setState(() => _expiresAt = value);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Tiếp tục',
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Chọn giờ',
      cancelText: 'Hủy',
      confirmText: 'Xong',
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_expiresAt != null && !_expiresAt!.isAfter(_publishedAt)) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      AnnouncementFormData(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _category,
        priority: _priority,
        audience: _audience,
        publishedAt: _publishedAt,
        expiresAt: _expiresAt,
        isPinned: _isPinned,
        isPublished: _isPublished,
        buildingId: _buildingId,
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 18),
      color: colors.primaryContainer.withValues(alpha: 0.55),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.add_alert_rounded, color: colors.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo thông báo mới',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Soạn nội dung và chọn nhóm người nhận',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onClear == null
              ? const Icon(Icons.expand_more_rounded)
              : IconButton(
                  tooltip: 'Bỏ thời điểm hết hạn',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        child: Text(
          value == null ? 'Không giới hạn' : _formatDateTime(value!),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: value == null ? colors.onSurfaceVariant : null),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: value
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? colors.primary.withValues(alpha: 0.35)
              : colors.outline,
        ),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: value ? colors.primary : null),
        title: Text(title),
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)} · '
      '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}
