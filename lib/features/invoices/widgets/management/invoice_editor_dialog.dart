import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/invoices/models/invoice.dart';
import 'package:homie/features/invoices/models/fee_type.dart';
import 'package:homie/features/invoices/models/unbilled_service_charge.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/core/widgets/app_button.dart';

import 'invoice_management_widgets.dart';

class InvoiceFormData {
  const InvoiceFormData({
    required this.apartmentId,
    required this.payerResidentId,
    required this.billingMonth,
    required this.dueDate,
    required this.items,
    required this.publish,
  });

  final String apartmentId;
  final String payerResidentId;
  final DateTime billingMonth;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final bool publish;
}

Future<InvoiceFormData?> showInvoiceEditorDialog(
  BuildContext context, {
  required List<Apartment> apartments,
  required List<ApartmentMembership> memberships,
  required List<Resident> residents,
  required List<FeeType> feeTypes,
  List<UnbilledServiceCharge> unbilledServices = const [],
}) {
  return showDialog<InvoiceFormData>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _InvoiceEditorDialog(
      apartments: apartments,
      memberships: memberships,
      residents: residents,
      feeTypes: feeTypes,
      unbilledServices: unbilledServices,
    ),
  );
}

class _InvoiceEditorDialog extends StatefulWidget {
  const _InvoiceEditorDialog({
    required this.apartments,
    required this.memberships,
    required this.residents,
    required this.feeTypes,
    required this.unbilledServices,
  });

  final List<Apartment> apartments;
  final List<ApartmentMembership> memberships;
  final List<Resident> residents;
  final List<FeeType> feeTypes;
  final List<UnbilledServiceCharge> unbilledServices;

  @override
  State<_InvoiceEditorDialog> createState() => _InvoiceEditorDialogState();
}

class _InvoiceEditorDialogState extends State<_InvoiceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_ItemEditor> _itemEditors = <_ItemEditor>[];
  final Set<String> _selectedServiceIds = <String>{};

  String? _apartmentId;
  late DateTime _billingMonth;
  late DateTime _dueDate;
  bool _showItemError = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _billingMonth = DateTime(now.year, now.month);
    _dueDate = DateTime(now.year, now.month + 1, 10);

    final available = _availableApartments;
    if (available.isNotEmpty) {
      _apartmentId = available.first.id;
    }
    if (widget.feeTypes.isEmpty) {
      _addItem(name: 'Khoản phí khác', quantity: '1');
    } else {
      _addFeeType(widget.feeTypes.first);
    }
  }

  @override
  void dispose() {
    for (final item in _itemEditors) {
      item.dispose();
    }
    super.dispose();
  }

  List<Apartment> get _availableApartments {
    return widget.apartments.where((apartment) {
      return _responsibleMembershipFor(apartment.id) != null;
    }).toList();
  }

  ApartmentMembership? _responsibleMembershipFor(String apartmentId) {
    final memberships =
        widget.memberships
            .where(
              (membership) =>
                  membership.apartmentId == apartmentId &&
                  membership.isActive &&
                  (membership.type == MembershipType.tenant ||
                      membership.type == MembershipType.owner),
            )
            .toList()
          ..sort((first, second) {
            if (first.type != second.type) {
              return first.type == MembershipType.tenant ? -1 : 1;
            }
            if (first.isPrimary != second.isPrimary) {
              return first.isPrimary ? -1 : 1;
            }
            return second.startDate.compareTo(first.startDate);
          });
    return memberships.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 650;
    final apartments = _availableApartments;
    final payerMembership = _apartmentId == null
        ? null
        : _responsibleMembershipFor(_apartmentId!);
    final payer = widget.residents
        .where((resident) => resident.id == payerMembership?.residentId)
        .firstOrNull;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 30,
        vertical: compact ? 12 : 28,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: size.height * (compact ? 0.96 : 0.92),
        ),
        child: Column(
          children: [
            _DialogHeader(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: apartments.isEmpty
                  ? _NoEligibleApartment(
                      onClose: () => Navigator.of(context).pop(),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 24,
                          20,
                          compact ? 16 : 24,
                          14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionTitle(
                              icon: Icons.apartment_rounded,
                              label: 'Căn hộ và người thanh toán',
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final apartmentField =
                                    DropdownButtonFormField<String>(
                                      initialValue: _apartmentId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Căn hộ *',
                                        prefixIcon: Icon(Icons.home_outlined),
                                      ),
                                      items: [
                                        for (final apartment in apartments)
                                          DropdownMenuItem(
                                            value: apartment.id,
                                            child: Text(
                                              '${apartment.code} · ${apartment.buildingName}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                      onChanged: _changeApartment,
                                      validator: (value) => value == null
                                          ? 'Vui lòng chọn căn hộ'
                                          : null,
                                    );
                                final payerField = InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Người thanh toán',
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                    helperText: payerMembership == null
                                        ? 'Căn hộ chưa có người nhận hóa đơn'
                                        : '${payerMembership.type.displayName} đang hiệu lực · tự động giao hóa đơn',
                                  ),
                                  child: Text(
                                    payer?.fullName ?? 'Chưa xác định',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                                if (constraints.maxWidth < 600) {
                                  return Column(
                                    children: [
                                      apartmentField,
                                      const SizedBox(height: 12),
                                      payerField,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: apartmentField),
                                    const SizedBox(width: 12),
                                    Expanded(child: payerField),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(
                              icon: Icons.calendar_month_outlined,
                              label: 'Kỳ hóa đơn',
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final month = _DateField(
                                  label: 'Tháng thu phí',
                                  value: formatMonth(_billingMonth),
                                  icon: Icons.date_range_outlined,
                                  onTap: _pickBillingMonth,
                                );
                                final due = _DateField(
                                  label: 'Hạn thanh toán',
                                  value: formatDate(_dueDate),
                                  icon: Icons.event_busy_outlined,
                                  onTap: _pickDueDate,
                                );
                                if (constraints.maxWidth < 520) {
                                  return Column(
                                    children: [
                                      month,
                                      const SizedBox(height: 12),
                                      due,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: month),
                                    const SizedBox(width: 12),
                                    Expanded(child: due),
                                  ],
                                );
                              },
                            ),
                            if (_dueDate.isBefore(_billingMonth)) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Hạn thanh toán không thể trước kỳ hóa đơn.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: _SectionTitle(
                                    icon: Icons.list_alt_rounded,
                                    label: 'Các khoản phí',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Thêm khoản phí'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (
                              var index = 0;
                              index < _itemEditors.length;
                              index++
                            ) ...[
                              _InvoiceItemEditor(
                                key: ValueKey(_itemEditors[index].id),
                                index: index,
                                editor: _itemEditors[index],
                                canRemove: _itemEditors.length > 1,
                                onRemove: () => _removeItem(index),
                                onChanged: _refreshTotal,
                                feeTypes: widget.feeTypes,
                                apartmentArea: _selectedApartment?.area,
                              ),
                              if (index != _itemEditors.length - 1)
                                const SizedBox(height: 12),
                            ],
                            if (_eligibleServices.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const _SectionTitle(
                                icon: Icons.room_service_outlined,
                                label:
                                    'Dịch vụ đã hoàn thành, chưa lập hóa đơn',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Chọn đơn dịch vụ để gộp vào hóa đơn tháng này. Đơn giá lấy từ lúc cư dân đặt dịch vụ.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              for (final charge in _eligibleServices)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _selectedServiceIds.contains(
                                    charge.id,
                                  ),
                                  title: Text(charge.serviceName),
                                  subtitle: Text(
                                    '${charge.code} · ${formatVnd(charge.amount)}',
                                  ),
                                  onChanged: (value) => setState(() {
                                    if (value == true) {
                                      _selectedServiceIds.add(charge.id);
                                    } else {
                                      _selectedServiceIds.remove(charge.id);
                                    }
                                  }),
                                ),
                            ],
                            if (_showItemError) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Hóa đơn phải có ít nhất một khoản phí hợp lệ.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _TotalPanel(
                              itemCount:
                                  _itemEditors.length +
                                  _eligibleServices
                                      .where(
                                        (charge) => _selectedServiceIds
                                            .contains(charge.id),
                                      )
                                      .length,
                              amount: _currentTotal,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (apartments.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 20,
                  10,
                  compact ? 12 : 20,
                  14,
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Hủy',
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    AppButton(
                      label: 'Lưu bản nháp',
                      icon: Icons.save_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _submit(publish: false),
                    ),
                    AppButton(
                      label: 'Tạo và phát hành',
                      icon: Icons.send_rounded,
                      onPressed: () => _submit(publish: true),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double get _currentTotal {
    final fees = _itemEditors.fold<double>(0, (sum, item) {
      return sum + item.quantity * item.unitPrice;
    });
    return fees +
        _eligibleServices
            .where((charge) => _selectedServiceIds.contains(charge.id))
            .fold<double>(0, (sum, charge) => sum + charge.amount);
  }

  List<UnbilledServiceCharge> get _eligibleServices {
    final apartmentId = _apartmentId;
    if (apartmentId == null) return const [];
    final payerId = _responsibleMembershipFor(apartmentId)?.residentId;
    final nextMonth = DateTime(_billingMonth.year, _billingMonth.month + 1);
    return widget.unbilledServices
        .where(
          (charge) =>
              charge.apartmentId == apartmentId &&
              charge.requestedById == payerId &&
              charge.completedAt.isBefore(nextMonth),
        )
        .toList(growable: false);
  }

  Apartment? get _selectedApartment => _apartmentId == null
      ? null
      : widget.apartments.where((item) => item.id == _apartmentId).firstOrNull;

  void _changeApartment(String? value) {
    setState(() => _apartmentId = value);
  }

  void _addItem({String name = '', String quantity = '1'}) {
    setState(() {
      _itemEditors.add(
        _ItemEditor(
          id: 'fee-${DateTime.now().microsecondsSinceEpoch}-${_itemEditors.length}',
          name: name,
          quantity: quantity,
          onChanged: _refreshTotal,
        ),
      );
      _showItemError = false;
    });
  }

  void _addFeeType(FeeType feeType) {
    final apartment = _selectedApartment;
    final quantity = switch (feeType.calculationType) {
      FeeCalculationType.fixed => 1.0,
      FeeCalculationType.byArea => apartment?.area ?? 1.0,
      FeeCalculationType.byQuantity => 1.0,
    };
    setState(() {
      _itemEditors.add(
        _ItemEditor(
          id: 'fee-${DateTime.now().microsecondsSinceEpoch}-${_itemEditors.length}',
          name: feeType.name,
          quantity: quantity.toString(),
          unitPrice: feeType.defaultUnitPrice.toStringAsFixed(0),
          feeTypeId: feeType.id,
          feeTypeCode: feeType.code,
          onChanged: _refreshTotal,
        ),
      );
      _showItemError = false;
    });
  }

  void _removeItem(int index) {
    if (_itemEditors.length <= 1) return;
    final editor = _itemEditors.removeAt(index);
    editor.dispose();
    setState(() {});
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  Future<void> _pickBillingMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingMonth,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Chọn một ngày trong tháng thu phí',
      cancelText: 'Hủy',
      confirmText: 'Chọn tháng',
    );
    if (picked == null || !mounted) return;
    final month = DateTime(picked.year, picked.month);
    setState(() {
      _billingMonth = month;
      if (_dueDate.isBefore(month)) {
        _dueDate = DateTime(month.year, month.month + 1, 10);
      }
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_billingMonth) ? _billingMonth : _dueDate,
      firstDate: _billingMonth,
      lastDate: DateTime(2036, 12, 31),
      helpText: 'Chọn hạn thanh toán',
      cancelText: 'Hủy',
      confirmText: 'Xong',
    );
    if (picked == null || !mounted) return;
    setState(() => _dueDate = picked);
  }

  void _submit({required bool publish}) {
    final valid = _formKey.currentState?.validate() ?? false;
    final items = _itemEditors.map((editor) => editor.toInvoiceItem()).toList();
    final validItems = items.every(
      (item) =>
          item.name.trim().isNotEmpty &&
          item.quantity > 0 &&
          item.unitPrice > 0,
    );
    setState(() => _showItemError = items.isEmpty || !validItems);

    if (!valid || !validItems || _dueDate.isBefore(_billingMonth)) return;
    final apartmentId = _apartmentId;
    final payerId = apartmentId == null
        ? null
        : _responsibleMembershipFor(apartmentId)?.residentId;
    if (apartmentId == null || payerId == null) return;

    Navigator.of(context).pop(
      InvoiceFormData(
        apartmentId: apartmentId,
        payerResidentId: payerId,
        billingMonth: _billingMonth,
        dueDate: _dueDate,
        items: [
          ...items,
          for (final charge in _eligibleServices)
            if (_selectedServiceIds.contains(charge.id))
              InvoiceItem(
                id: 'service-${charge.id}',
                name: '${charge.serviceName} · ${charge.code}',
                quantity: charge.quantity,
                unitPrice: charge.unitPrice,
                serviceRequestId: charge.id,
                source: 'service',
              ),
        ],
        publish: publish,
      ),
    );
  }
}

class _InvoiceItemEditor extends StatelessWidget {
  const _InvoiceItemEditor({
    required this.index,
    required this.editor,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    required this.feeTypes,
    required this.apartmentArea,
    super.key,
  });

  final int index;
  final _ItemEditor editor;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final List<FeeType> feeTypes;
  final double? apartmentArea;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Khoản phí ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: 'Xóa khoản phí',
                    visualDensity: VisualDensity.compact,
                    color: colors.error,
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: editor.feeTypeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nguồn khoản phí',
                prefixIcon: Icon(Icons.source_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Khoản thu nhập thủ công'),
                ),
                for (final feeType in feeTypes)
                  DropdownMenuItem<String?>(
                    value: feeType.id,
                    child: Text(feeType.name),
                  ),
              ],
              onChanged: (value) {
                final feeType = feeTypes
                    .where((item) => item.id == value)
                    .firstOrNull;
                editor.selectFeeType(feeType, apartmentArea: apartmentArea);
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: editor.nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tên khoản phí *',
                hintText: 'Ví dụ: Tiền nước',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Vui lòng nhập tên khoản phí'
                  : null,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final quantity = TextFormField(
                  controller: editor.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Số lượng *',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  validator: (value) {
                    final parsed = _parseDecimal(value ?? '');
                    return parsed <= 0 ? 'Phải lớn hơn 0' : null;
                  },
                  onChanged: (_) => onChanged(),
                );
                final unitPrice = TextFormField(
                  controller: editor.unitPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá (VND) *',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final parsed = _parseMoney(value ?? '');
                    return parsed <= 0 ? 'Phải lớn hơn 0' : null;
                  },
                  onChanged: (_) => onChanged(),
                );

                if (constraints.maxWidth < 470) {
                  return Column(
                    children: [quantity, const SizedBox(height: 12), unitPrice],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: quantity),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: unitPrice),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Thành tiền: ${formatVnd(editor.quantity * editor.unitPrice)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditor {
  _ItemEditor({
    required this.id,
    required String name,
    required String quantity,
    String unitPrice = '',
    this.feeTypeId,
    this.feeTypeCode,
    required VoidCallback onChanged,
  }) : nameController = TextEditingController(text: name),
       quantityController = TextEditingController(text: quantity),
       unitPriceController = TextEditingController(text: unitPrice) {
    nameController.addListener(onChanged);
    quantityController.addListener(onChanged);
    unitPriceController.addListener(onChanged);
  }

  final String id;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  String? feeTypeId;
  String? feeTypeCode;

  double get quantity => _parseDecimal(quantityController.text);
  double get unitPrice => _parseMoney(unitPriceController.text);

  InvoiceItem toInvoiceItem() {
    return InvoiceItem(
      id: id,
      name: nameController.text.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      feeTypeId: feeTypeId,
      feeTypeCode: feeTypeCode,
      source: feeTypeId == null ? 'manual' : 'catalog',
    );
  }

  void selectFeeType(FeeType? feeType, {double? apartmentArea}) {
    feeTypeId = feeType?.id;
    feeTypeCode = feeType?.code;
    if (feeType == null) return;
    nameController.text = feeType.name;
    unitPriceController.text = feeType.defaultUnitPrice.toStringAsFixed(0);
    quantityController.text = switch (feeType.calculationType) {
      FeeCalculationType.fixed => '1',
      FeeCalculationType.byArea => (apartmentArea ?? 1).toString(),
      FeeCalculationType.byQuantity =>
        quantityController.text.isEmpty ? '1' : quantityController.text,
    };
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 10, 18),
      color: colors.primaryContainer.withValues(alpha: 0.52),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.post_add_rounded, color: colors.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo hóa đơn mới',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Chọn căn hộ và khai báo các khoản phí',
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

class _NoEligibleApartment extends StatelessWidget {
  const _NoEligibleApartment({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 54,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có căn hộ đủ điều kiện',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm chủ sở hữu, người thuê hoặc thành viên đang hiệu lực cho căn hộ trước khi tạo hóa đơn.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onClose, child: const Text('Đã hiểu')),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(value),
      ),
    );
  }
}

class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.itemCount, required this.amount});

  final int itemCount;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng hóa đơn',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '$itemCount khoản phí',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              formatVnd(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _parseDecimal(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}

double _parseMoney(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(normalized) ?? 0;
}
