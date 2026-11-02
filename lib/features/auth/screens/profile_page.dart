import 'package:flutter/material.dart';

import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/controllers/auth_controller.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/core/storage/file_upload_service.dart';
import 'package:homie/features/auth/widgets/user_avatar.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/residents/screens/resident/residence_verification_card.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/residence_verification.dart';
import 'package:homie/features/residents/widgets/resident_apartment_picker.dart';
import 'package:homie/core/notifications/push_notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.controller,
    required this.user,
    required this.fileUploadService,
    required this.onLogout,
    this.membershipController,
    this.pushNotificationService,
    this.onOpenHousehold,
    this.onOpenNotifications,
    this.apartmentCode,
    super.key,
  });
  final AuthController controller;
  final User user;
  final FileUploadService fileUploadService;
  final VoidCallback onLogout;
  final ApartmentMembershipController? membershipController;
  final PushNotificationService? pushNotificationService;
  final VoidCallback? onOpenHousehold;
  final VoidCallback? onOpenNotifications;
  final String? apartmentCode;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.user.fullName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user.phoneNumber ?? '',
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.user.contactAddress ?? '',
  );
  DateTime? _birthday;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _birthday = widget.user.dateOfBirth;
  }

  String _verificationLabel(ApartmentMembershipController controller) {
    return switch (controller.myVerification.state) {
      ResidenceVerificationState.notSubmitted => 'Chưa gửi yêu cầu xác minh',
      ResidenceVerificationState.pending => 'Đang chờ ban quản lý duyệt',
      ResidenceVerificationState.approved => 'Đã xác minh cư dân',
      ResidenceVerificationState.rejected => 'Cần bổ sung thông tin',
    };
  }

  Future<void> _showApartmentPicker() async {
    final controller = widget.membershipController;
    if (controller == null) return;
    await showResidentApartmentPicker(
      context: context,
      controller: controller,
      residentId: (widget.controller.currentUser ?? widget.user).id,
    );
  }

  Future<void> _showPersonalInfo() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Thông tin cá nhân',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Email đăng nhập',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  child: Text(widget.user.email),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  leading: const Icon(Icons.cake_outlined),
                  title: const Text('Ngày sinh'),
                  subtitle: Text(
                    _birthday == null
                        ? 'Chưa cập nhật'
                        : '${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    await _pickBirthday();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ liên hệ',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: widget.controller.isLoading
                      ? null
                      : () async {
                          final success = await _save();
                          if (success && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu thay đổi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showVerification(ApartmentMembershipController controller) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: ResidenceVerificationCard(
              controller: controller,
              user: widget.controller.currentUser ?? widget.user,
            ),
          ),
        ),
      );

  Future<void> _showNotificationDevice() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.phone_android_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Thiết bị Android này',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thiết bị sẽ nhận thông báo hóa đơn, yêu cầu và tin từ ban quản lý.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.pushNotificationService == null
                    ? null
                    : () async {
                        final success = await widget.pushNotificationService!
                            .registerCurrentDevice();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Đã bật nhận thông báo trên thiết bị này.'
                                  : 'Chưa thể đăng ký thiết bị. Hãy kiểm tra quyền thông báo.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Bật nhận thông báo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPrivacyPolicy() => _showInformationSheet(
    icon: Icons.privacy_tip_outlined,
    title: 'Chính sách bảo mật',
    message: 'Homie chỉ sử dụng thông tin tài khoản, căn hộ và yêu cầu dịch vụ để vận hành khu dân cư. Dữ liệu được giới hạn theo vai trò và tòa nhà; người dùng khác không được tự do truy cập hồ sơ của bạn.',
  );

  Future<void> _showAppInfo() => _showInformationSheet(
    icon: Icons.home_work_rounded,
    title: 'Homie 1.0.0',
    message: 'Ứng dụng quản lý căn hộ, hóa đơn, dịch vụ và kết nối cư dân với ban quản lý. Phiên bản dựng: 1.',
  );

  Future<void> _showInformationSheet({
    required IconData icon,
    required String title,
    required String message,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.logout_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 34,
        ),
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có muốn đăng xuất khỏi ứng dụng?',
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy bỏ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop();
    widget.onLogout();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membershipController = widget.membershipController;
    if (membershipController == null) return _buildAccountPage(context, null);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.controller,
        membershipController,
      ]),
      builder: (context, _) => _buildAccountPage(context, membershipController),
    );
  }

  Widget _buildAccountPage(
    BuildContext context,
    ApartmentMembershipController? membershipController,
  ) {
    final currentUser = widget.controller.currentUser ?? widget.user;
    final memberships =
        membershipController?.activeMembershipsForResident(currentUser.id) ??
        const <ApartmentMembership>[];
    final membership = membershipController?.activeMembershipForResident(
      currentUser.id,
    );
    final apartment = membershipController?.apartmentById(
      membership?.apartmentId ?? '',
    );
    final relation = membership?.type.displayName ?? currentUser.role.label;

    return ResidentPageScaffold(
      title: 'Tài khoản',
      subtitle: 'Hồ sơ, cư trú và cài đặt',
      icon: Icons.manage_accounts_rounded,
      accentColor: AppColors.secondary,
      accentSoftColor: AppColors.secondaryLight,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
        children: <Widget>[
          _ProfileHeader(
            user: currentUser,
            relation: relation,
            uploadingAvatar: _uploadingAvatar,
            onAvatarTap: _uploadingAvatar ? null : _uploadAvatar,
          ),
          const SizedBox(height: 16),
          if (membershipController != null)
            _ApartmentCard(
              code: apartment?.code ?? widget.apartmentCode ?? 'Chưa liên kết',
              buildingName: apartment?.buildingName ?? 'Chưa có tòa nhà',
              relation: relation,
              canSwitch: memberships.length > 1,
              onSwitch: memberships.length > 1 ? _showApartmentPicker : null,
            ),
          const SizedBox(height: 24),
          _SettingGroup(
            title: 'Tài khoản',
            children: <Widget>[
              _SettingTile(
                icon: Icons.badge_outlined,
                color: AppColors.primary,
                title: 'Thông tin cá nhân',
                subtitle: 'Họ tên, số điện thoại và địa chỉ liên hệ',
                onTap: _showPersonalInfo,
              ),
              _SettingTile(
                icon: Icons.lock_outline_rounded,
                color: const Color(0xFF7C3AED),
                title: 'Đổi mật khẩu',
                subtitle: 'Cập nhật mật khẩu đăng nhập',
                onTap: _showChangePassword,
              ),
              _SettingTile(
                icon: Icons.devices_rounded,
                color: const Color(0xFF0F9F8F),
                title: 'Thiết bị nhận thông báo',
                subtitle: 'Quản lý thông báo trên thiết bị này',
                onTap: _showNotificationDevice,
              ),
            ],
          ),
          if (membershipController != null) ...<Widget>[
            const SizedBox(height: 22),
            _SettingGroup(
              title: 'Cư trú',
              children: <Widget>[
                _SettingTile(
                  icon: Icons.apartment_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'Căn hộ của tôi',
                  subtitle: apartment == null
                      ? 'Chưa có căn hộ được liên kết'
                      : '${apartment.code} · ${apartment.buildingName}',
                  onTap: widget.onOpenHousehold,
                ),
                _SettingTile(
                  icon: Icons.groups_2_outlined,
                  color: const Color(0xFF16A34A),
                  title: 'Thành viên trong hộ',
                  subtitle: 'Xem và cập nhật người đang cư trú',
                  onTap: widget.onOpenHousehold,
                ),
                _SettingTile(
                  icon: Icons.verified_user_outlined,
                  color: const Color(0xFF059669),
                  title: 'Thông tin xác minh cư dân',
                  subtitle: _verificationLabel(membershipController),
                  onTap: () => _showVerification(membershipController),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          _SettingGroup(
            title: 'Ứng dụng',
            children: <Widget>[
              _SettingTile(
                icon: Icons.notifications_none_rounded,
                color: const Color(0xFFEA580C),
                title: 'Trung tâm thông báo',
                subtitle: 'Tin từ ban quản lý và trạng thái yêu cầu',
                onTap: widget.onOpenNotifications,
              ),
              _SettingTile(
                icon: Icons.privacy_tip_outlined,
                color: const Color(0xFF0891B2),
                title: 'Chính sách bảo mật',
                subtitle: 'Cách Homie sử dụng và bảo vệ dữ liệu',
                onTap: _showPrivacyPolicy,
              ),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFF64748B),
                title: 'Thông tin ứng dụng',
                subtitle: 'Homie · Phiên bản 1.0.0 (1)',
                onTap: _showAppInfo,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error
                    .withValues(alpha: .4),
              ),
              backgroundColor: Theme.of(context).colorScheme.errorContainer
                  .withValues(alpha: .22),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  Future<bool> _save() async {
    final success = await widget.controller.updateProfile(
      fullName: _name.text,
      phoneNumber: _phone.text,
      dateOfBirth: _birthday,
      contactAddress: _address.text,
    );
    if (!mounted) return success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã cập nhật hồ sơ.'
              : widget.controller.errorMessage ?? 'Chưa thể cập nhật hồ sơ.',
        ),
      ),
    );
    return success;
  }

  Future<void> _uploadAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      final file = await widget.fileUploadService.pickAndUpload(
        category: 'avatar',
        imagesOnly: true,
        maxSizeBytes: 2 * 1024 * 1024,
      );
      if (file == null) return;
      final success = await widget.controller.updateAvatar(file.url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã cập nhật ảnh đại diện.'
                : widget.controller.errorMessage ??
                      'Chưa thể cập nhật ảnh đại diện.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : error.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _showChangePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await widget.controller.changePassword(
      currentPassword: current.text,
      newPassword: next.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã đổi mật khẩu.'
              : widget.controller.errorMessage ?? 'Chưa thể đổi mật khẩu.',
        ),
      ),
    );
    current.dispose();
    next.dispose();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.relation,
    required this.uploadingAvatar,
    required this.onAvatarTap,
  });

  final User user;
  final String relation;
  final bool uploadingAvatar;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF2F6FED), Color(0xFF00A8B8)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x302F6FED),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        InkWell(
          onTap: onAvatarTap,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              UserAvatar(
                user: user,
                radius: 36,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              if (uploadingAvatar)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x990F2446),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2446),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFE4F2FF)),
              ),
              if (user.phoneNumber?.isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  user.phoneNumber!,
                  style: const TextStyle(color: Color(0xFFE4F2FF)),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .28),
                  ),
                ),
                child: Text(
                  relation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({
    required this.code,
    required this.buildingName,
    required this.relation,
    required this.canSwitch,
    required this.onSwitch,
  });

  final String code;
  final String buildingName;
  final String relation;
  final bool canSwitch;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.apartment_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  code,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text('$buildingName · $relation'),
              ],
            ),
          ),
          if (canSwitch)
            TextButton(onPressed: onSwitch, child: const Text('Đổi căn hộ')),
        ],
      ),
    );
  }
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (var index = 0; index < children.length; index++) ...<Widget>[
                children[index],
                if (index < children.length - 1)
                  Divider(height: 1, indent: 70, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 72,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    onTap: onTap,
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
  );
}
