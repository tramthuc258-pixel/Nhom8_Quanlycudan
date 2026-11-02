import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';

import '../controllers/staff_assignment_controller.dart';
import '../models/staff_scope.dart';

class StaffAssignmentPage extends StatefulWidget {
  const StaffAssignmentPage({required this.controller, super.key});

  final StaffAssignmentController controller;

  @override
  State<StaffAssignmentPage> createState() => _StaffAssignmentPageState();
}

class _StaffAssignmentPageState extends State<StaffAssignmentPage> {
  String? _staffId;
  String? _buildingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.load(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FC),
    appBar: AppBar(
      title: const Text('Nhân sự & phân công'),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: widget.controller.load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading && widget.controller.staff.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _accountHeader(),
              const SizedBox(height: 16),
              _assignmentForm(),
              if (widget.controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                _message(widget.controller.errorMessage!),
              ],
              const SizedBox(height: 20),
              Text(
                'Danh sách nhân viên và phạm vi phụ trách',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...widget.controller.staff.map(_staffCard),
            ],
          ),
        );
      },
    ),
  );

  Widget _accountHeader() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3157D5), Color(0xFF16A6B6)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x243157D5),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        const introduction = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản nhân viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Tạo người mới, cấp vai trò và chọn tòa phụ trách ban đầu.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        );
        final createButton = FilledButton.icon(
          key: const ValueKey<String>('create-staff-account'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2549BC),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onPressed: widget.controller.isSaving ? null : _openCreateStaff,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Tạo tài khoản nhân viên'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [introduction, const SizedBox(height: 18), createButton],
          );
        }
        return Row(
          children: [
            const Expanded(child: introduction),
            const SizedBox(width: 18),
            createButton,
          ],
        );
      },
    ),
  );

  Widget _assignmentForm() => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFDCE5F5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final staffField = DropdownButtonFormField<String>(
            initialValue: _staffId,
            decoration: const InputDecoration(
              labelText: 'Nhân viên',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: widget.controller.staff
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.fullName),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _staffId = value),
          );
          final buildingField = DropdownButtonFormField<String>(
            initialValue: _buildingId,
            decoration: const InputDecoration(
              labelText: 'Tòa nhà phụ trách',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
            items: widget.controller.buildings
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _buildingId = value),
          );
          final button = FilledButton.icon(
            onPressed: widget.controller.isSaving ? null : _assign,
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Phân công'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Phân công thêm tòa cho nhân viên đã có',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                staffField,
                const SizedBox(height: 12),
                buildingField,
                const SizedBox(height: 14),
                button,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: staffField),
              const SizedBox(width: 14),
              Expanded(child: buildingField),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    ),
  );

  Widget _staffCard(StaffScope staff) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFDCE5F5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: .1),
                foregroundColor: AppColors.primary,
                child: Text(staff.fullName.substring(0, 1).toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(staff.email),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(staff),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(staff.roles.firstOrNull ?? ''),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Quản lý tài khoản',
                onSelected: (value) => _handleStaffAction(staff, value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Sửa thông tin'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: ListTile(
                      leading: Icon(Icons.password_rounded),
                      title: Text('Cấp lại mật khẩu'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      leading: Icon(
                        staff.isActive
                            ? Icons.lock_outline_rounded
                            : Icons.lock_open_rounded,
                      ),
                      title: Text(
                        staff.isActive ? 'Khóa tài khoản' : 'Mở tài khoản',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (staff.buildings.where((item) => item.isActive).isEmpty)
            const Text('Chưa được phân công tòa nhà.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: staff.buildings
                  .where((item) => item.isActive)
                  .map(
                    (building) => InputChip(
                      avatar: const Icon(Icons.apartment_rounded, size: 18),
                      label: Text(building.name),
                      onDeleted: building.assignmentId == null
                          ? null
                          : () => _end(building),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    ),
  );

  Widget _message(String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );

  Future<void> _assign() async {
    if (_staffId == null || _buildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn nhân viên và tòa nhà.')),
      );
      return;
    }
    final ok = await widget.controller.assign(
      userId: _staffId!,
      buildingId: _buildingId!,
    );
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật phạm vi phụ trách.')),
      );
    }
  }

  Future<void> _end(BuildingScope building) async {
    final ok = await widget.controller.end(building.assignmentId!);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã kết thúc phân công ${building.name}.')),
      );
    }
  }

  Widget _statusChip(StaffScope staff) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: staff.isActive ? const Color(0xFFE4F8F1) : const Color(0xFFFFE8E8),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      staff.isActive
          ? staff.mustChangePassword
                ? 'Chờ đổi mật khẩu'
                : 'Đang hoạt động'
          : 'Đã khóa',
      style: TextStyle(
        color: staff.isActive
            ? const Color(0xFF087A5B)
            : const Color(0xFFB42318),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  static const _roles = <String, String>{
    'MANAGEMENT': 'Ban quản lý',
    'ACCOUNTANT': 'Kế toán',
    'RECEPTIONIST': 'Lễ tân',
    'SECURITY': 'Bảo vệ',
    'TECHNICIAN': 'Kỹ thuật viên',
  };

  String _roleLabel(String code) => _roles[code] ?? code;

  Future<void> _openCreateStaff() => _openStaffDialog();

  Future<void> _openStaffDialog([StaffScope? staff]) async {
    final formKey = GlobalKey<FormState>();
    final fullName = TextEditingController(text: staff?.fullName);
    final email = TextEditingController(text: staff?.email);
    var role = staff?.roles.firstOrNull ?? 'MANAGEMENT';
    final buildingIds = <String>{};
    final created = await showDialog<StaffInvitationResult?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            staff == null ? 'Tạo tài khoản nhân viên' : 'Sửa nhân viên',
          ),
          content: SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: fullName,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) => (value ?? '').trim().length < 2
                          ? 'Hãy nhập họ tên nhân viên.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      enabled: staff == null,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email đăng nhập',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        return !text.contains('@')
                            ? 'Email chưa đúng định dạng.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: _roles.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => role = value ?? role),
                    ),
                    if (staff == null &&
                        widget.controller.buildings.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tòa phụ trách ban đầu',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...widget.controller.buildings.map(
                        (building) => CheckboxListTile(
                          value: buildingIds.contains(building.id),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(building.name),
                          subtitle: Text(building.code),
                          onChanged: (checked) => setDialogState(() {
                            checked == true
                                ? buildingIds.add(building.id)
                                : buildingIds.remove(building.id);
                          }),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                if (staff == null) {
                  final result = await widget.controller.createStaff(
                    fullName: fullName.text.trim(),
                    email: email.text.trim(),
                    role: role,
                    buildingIds: buildingIds.toList(),
                  );
                  if (dialogContext.mounted && result != null) {
                    Navigator.pop(dialogContext, result);
                  }
                } else {
                  final ok = await widget.controller.updateStaff(
                    id: staff.id,
                    fullName: fullName.text.trim(),
                    role: role,
                  );
                  if (dialogContext.mounted && ok) {
                    Navigator.pop(
                      dialogContext,
                      const StaffInvitationResult(emailDelivered: true),
                    );
                  }
                }
              },
              child: Text(staff == null ? 'Tạo và gửi email' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
    fullName.dispose();
    email.dispose();
    if (!mounted || created == null) return;
    if (staff != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật tài khoản nhân viên.')),
      );
      return;
    }
    await _showInvitationResult(created);
  }

  Future<void> _handleStaffAction(StaffScope staff, String action) async {
    if (action == 'edit') return _openStaffDialog(staff);
    if (action == 'toggle') {
      final ok = await widget.controller.setActive(staff, !staff.isActive);
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              staff.isActive
                  ? 'Đã khóa tài khoản ${staff.fullName}.'
                  : 'Đã mở lại tài khoản ${staff.fullName}.',
            ),
          ),
        );
      }
      return;
    }
    if (action == 'reset') {
      final result = await widget.controller.resetPassword(staff.id);
      if (mounted && result != null) await _showInvitationResult(result);
    }
  }

  Future<void> _showInvitationResult(StaffInvitationResult result) async {
    final temporaryPassword = result.temporaryPassword;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.emailDelivered
              ? Icons.mark_email_read_outlined
              : Icons.key_rounded,
          color: AppColors.primary,
        ),
        title: Text(
          result.emailDelivered
              ? 'Đã gửi tài khoản qua email'
              : 'Mật khẩu tạm thời',
        ),
        content: Text(
          result.emailDelivered
              ? 'Nhân viên sẽ nhận được email và phải đổi mật khẩu ở lần đăng nhập đầu tiên.'
              : 'Email chưa gửi được. Hãy chuyển mật khẩu tạm thời này cho nhân viên:\n\n${temporaryPassword ?? 'Không có mật khẩu'}',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
