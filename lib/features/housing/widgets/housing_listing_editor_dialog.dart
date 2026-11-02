import 'package:flutter/material.dart';

import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/widgets/housing_presentation_helpers.dart';
import 'package:homie/core/storage/file_upload_service.dart';

class HousingListingEditorDialog extends StatefulWidget {
  const HousingListingEditorDialog({
    required this.controller,
    required this.actor,
    required this.apartments,
    this.fileUploadService,
    super.key,
  });

  final HousingController controller;
  final User actor;
  final List<Apartment> apartments;
  final FileUploadService? fileUploadService;

  @override
  State<HousingListingEditorDialog> createState() =>
      _HousingListingEditorDialogState();
}

class _HousingListingEditorDialogState
    extends State<HousingListingEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  late String? _apartmentId;
  HousingTransactionType _transactionType = HousingTransactionType.rent;
  late DateTime _availableFrom;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _uploadError;
  final List<UploadedHomieFile> _images = <UploadedHomieFile>[];

  @override
  void initState() {
    super.initState();
    _apartmentId = widget.apartments.firstOrNull?.id;
    final now = DateTime.now();
    _availableFrom = DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.actor.role.isResident;
    return AlertDialog(
      title: Text(isOwner ? 'Đăng căn hộ của tôi' : 'Tạo bài đăng căn hộ'),
      content: SizedBox(
        width: 580,
        child: widget.apartments.isEmpty
            ? const _NoEligibleApartment()
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: .5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOwner
                              ? 'Bài của chủ sở hữu sẽ được gửi đến ban quản lý xét duyệt trước khi công khai.'
                              : 'Bài của ban quản lý sẽ được công khai ngay sau khi tạo.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _apartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Căn hộ *',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        items: [
                          for (final apartment in widget.apartments)
                            DropdownMenuItem(
                              value: apartment.id,
                              child: Text(
                                '${apartment.code} · ${apartment.buildingName}',
                              ),
                            ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) => _apartmentId = value,
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<HousingTransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: HousingTransactionType.rent,
                            icon: Icon(Icons.key_outlined),
                            label: Text('Cho thuê'),
                          ),
                          ButtonSegment(
                            value: HousingTransactionType.purchase,
                            icon: Icon(Icons.home_work_outlined),
                            label: Text('Mở bán'),
                          ),
                        ],
                        selected: {_transactionType},
                        onSelectionChanged: _isSaving
                            ? null
                            : (value) => setState(() {
                                _transactionType = value.first;
                                if (_transactionType ==
                                    HousingTransactionType.purchase) {
                                  _depositController.clear();
                                }
                              }),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề bài đăng *',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) => (value ?? '').trim().length < 5
                            ? 'Tiêu đề cần ít nhất 5 ký tự'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isSaving,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả *',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => (value ?? '').trim().length < 10
                            ? 'Mô tả cần ít nhất 10 ký tự'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _priceController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              _transactionType == HousingTransactionType.rent
                              ? 'Giá thuê mỗi tháng *'
                              : 'Giá bán *',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: 'đ',
                        ),
                        validator: _moneyValidator,
                      ),
                      if (_transactionType == HousingTransactionType.rent) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _depositController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tiền đặt cọc',
                            prefixIcon: Icon(Icons.savings_outlined),
                            suffixText: 'đ',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return null;
                            return _moneyValidator(value);
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _isSaving ? null : _pickAvailableDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày có thể bàn giao',
                            prefixIcon: Icon(Icons.event_available_outlined),
                          ),
                          child: Text(formatHousingDate(_availableFrom)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hình ảnh căn hộ',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tối đa 5 ảnh JPG, PNG hoặc WebP. Ảnh đầu tiên là ảnh đại diện.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (_images.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 92,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _images.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) => Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _images[index].url,
                                          width: 112,
                                          height: 92,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 112,
                                            height: 92,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton.filled(
                                          tooltip: 'Bỏ ảnh',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _isUploading || _isSaving
                                              ? null
                                              : () => setState(
                                                  () => _images.removeAt(index),
                                                ),
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_uploadError != null) ...[
                              const SizedBox(height: 8),
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
                                      _isSaving ||
                                      _isUploading ||
                                      _images.length >= 5
                                  ? null
                                  : _uploadImage,
                              icon: _isUploading
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_photo_alternate_outlined,
                                    ),
                              label: Text(
                                _isUploading
                                    ? 'Đang tải ảnh…'
                                    : 'Thêm hình ảnh',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.controller.errorMessage != null) ...[
                        const SizedBox(height: 12),
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
          onPressed: _isSaving || _isUploading
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Đóng'),
        ),
        if (widget.apartments.isNotEmpty)
          FilledButton.icon(
            onPressed: _isSaving || _isUploading ? null : _save,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(isOwner ? 'Gửi duyệt' : 'Đăng bài'),
          ),
      ],
    );
  }

  Future<void> _pickAvailableDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _availableFrom,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null && mounted) {
      setState(() => _availableFrom = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _apartmentId == null) return;
    setState(() => _isSaving = true);
    final success = await widget.controller.createListing(
      actor: widget.actor,
      apartmentId: _apartmentId!,
      title: _titleController.text,
      description: _descriptionController.text,
      transactionType: _transactionType,
      price: _parseMoney(_priceController.text),
      deposit: _transactionType == HousingTransactionType.rent
          ? _parseMoney(_depositController.text)
          : 0,
      availableFrom: _availableFrom,
      imageUrls: _images.map((image) => image.url).toList(growable: false),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadImage() async {
    final service = widget.fileUploadService;
    if (service == null || _images.length >= 5 || _isUploading) return;
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    try {
      final image = await service.pickAndUpload(
        category: 'housing',
        imagesOnly: true,
      );
      if (!mounted) return;
      setState(() {
        if (image != null) _images.add(image);
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

  String? _moneyValidator(String? value) {
    if (_parseMoney(value ?? '') <= 0) return 'Số tiền phải lớn hơn 0';
    return null;
  }

  double _parseMoney(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }
}

class _NoEligibleApartment extends StatelessWidget {
  const _NoEligibleApartment();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 48),
          SizedBox(height: 12),
          Text(
            'Không có căn hộ đủ điều kiện đăng tin. Căn hộ có thể đang bảo trì, đã có bài đăng hoặc không thuộc quyền quản lý của tài khoản này.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
