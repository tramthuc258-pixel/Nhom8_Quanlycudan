import 'package:flutter/material.dart';

import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';

class ApartmentEditorDialog extends StatefulWidget {
  const ApartmentEditorDialog({
    required this.controller,
    this.apartment,
    super.key,
  });

  final ApartmentMembershipController controller;
  final Apartment? apartment;

  @override
  State<ApartmentEditorDialog> createState() => _ApartmentEditorDialogState();
}

class _ApartmentEditorDialogState extends State<ApartmentEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _buildingController;
  late final TextEditingController _floorController;
  late final TextEditingController _areaController;
  late final TextEditingController _bedroomsController;
  late ApartmentStatus _status;
  bool _isSaving = false;

  bool get _isEditing => widget.apartment != null;

  @override
  void initState() {
    super.initState();
    final apartment = widget.apartment;
    _codeController = TextEditingController(text: apartment?.code ?? '');
    _buildingController = TextEditingController(
      text: apartment?.buildingName ?? '',
    );
    _floorController = TextEditingController(
      text: apartment?.floor.toString() ?? '',
    );
    _areaController = TextEditingController(
      text: apartment == null ? '' : _formatNumber(apartment.area),
    );
    _bedroomsController = TextEditingController(
      text: apartment?.bedrooms.toString() ?? '',
    );
    _status = apartment?.status ?? ApartmentStatus.vacant;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Chỉnh sửa căn hộ' : 'Thêm căn hộ'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey<String>('apartment-code-field'),
                  controller: _codeController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã căn hộ *',
                    hintText: 'Ví dụ: A-1205',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _buildingController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên tòa nhà *',
                    hintText: 'Ví dụ: Tòa A',
                    prefixIcon: Icon(Icons.domain_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final floorField = TextFormField(
                      controller: _floorController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tầng *',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      validator: (value) =>
                          _positiveIntValidator(value, fieldName: 'Tầng'),
                    );
                    final bedroomsField = TextFormField(
                      controller: _bedroomsController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số phòng ngủ *',
                        prefixIcon: Icon(Icons.bed_outlined),
                      ),
                      validator: (value) => _positiveIntValidator(
                        value,
                        fieldName: 'Số phòng ngủ',
                      ),
                    );
                    if (constraints.maxWidth < 430) {
                      return Column(
                        children: [
                          floorField,
                          const SizedBox(height: 14),
                          bedroomsField,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: floorField),
                        const SizedBox(width: 14),
                        Expanded(child: bedroomsField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _areaController,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Diện tích (m²) *',
                    prefixIcon: Icon(Icons.square_foot_rounded),
                  ),
                  validator: (value) {
                    final area = _parseDouble(value);
                    if (area == null || area <= 0) {
                      return 'Diện tích phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<ApartmentStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    prefixIcon: Icon(Icons.info_outline_rounded),
                  ),
                  items: [
                    for (final status in ApartmentStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) _status = value;
                        },
                ),
                if (widget.controller.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    widget.controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('save-apartment-button'),
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isEditing ? Icons.save_outlined : Icons.add_rounded),
          label: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm căn hộ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final apartment = widget.apartment;
    final parameters = (
      code: _codeController.text,
      buildingName: _buildingController.text,
      floor: int.parse(_floorController.text.trim()),
      area: _parseDouble(_areaController.text)!,
      bedrooms: int.parse(_bedroomsController.text.trim()),
      status: _status,
    );
    final success = apartment == null
        ? await widget.controller.createApartment(
            code: parameters.code,
            buildingName: parameters.buildingName,
            floor: parameters.floor,
            area: parameters.area,
            bedrooms: parameters.bedrooms,
            status: parameters.status,
          )
        : await widget.controller.updateApartment(
            apartmentId: apartment.id,
            code: parameters.code,
            buildingName: parameters.buildingName,
            floor: parameters.floor,
            area: parameters.area,
            bedrooms: parameters.bedrooms,
            status: parameters.status,
          );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _isSaving = false);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Không được để trống';
    }
    return null;
  }

  String? _positiveIntValidator(String? value, {required String fieldName}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) {
      return '$fieldName phải lớn hơn hoặc bằng 1';
    }
    return null;
  }

  double? _parseDouble(String? value) {
    return double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}
