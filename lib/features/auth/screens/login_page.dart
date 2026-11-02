import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/auth/models/user.dart';

import '../controllers/auth_controller.dart';
import '../widgets/forgot_password_sheet.dart';
import '../widgets/registration_otp_notice.dart';

enum LoginPortal { combined, resident, staff }

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.controller,
    required this.onLoginSuccess,
    this.portal = LoginPortal.combined,
    this.onContinueAsGuest,
    super.key,
  });

  final AuthController controller;
  final ValueChanged<User> onLoginSuccess;
  final LoginPortal portal;
  final VoidCallback? onContinueAsGuest;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _registrationOtpController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegisterMode = false;
  bool _registrationOtpRequested = false;
  String? _registrationDevelopmentCode;
  late LoginPortal _selectedPortal;

  LoginPortal get _effectivePortal =>
      widget.portal == LoginPortal.combined ? _selectedPortal : widget.portal;

  @override
  void initState() {
    super.initState();
    _selectedPortal = widget.portal == LoginPortal.staff
        ? LoginPortal.staff
        : LoginPortal.resident;
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portal != widget.portal &&
        widget.portal != LoginPortal.combined) {
      _selectedPortal = widget.portal;
    }
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registrationOtpController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toggleMode() {
    if (widget.controller.isLoading || _effectivePortal == LoginPortal.staff) {
      return;
    }
    widget.controller.clearError();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _registrationOtpController.clear();
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _registrationOtpRequested = false;
      _registrationDevelopmentCode = null;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  void _selectPortal(LoginPortal portal) {
    if (widget.portal != LoginPortal.combined ||
        widget.controller.isLoading ||
        portal == _selectedPortal) {
      return;
    }
    widget.controller.clearError();
    FocusScope.of(context).unfocus();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _registrationOtpController.clear();
    setState(() {
      _selectedPortal = portal;
      _isRegisterMode = false;
      _registrationOtpRequested = false;
      _registrationDevelopmentCode = null;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    if (_isRegisterMode && !_registrationOtpRequested) {
      final result = await widget.controller.requestRegistrationOtp(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted || result == null) return;
      setState(() {
        _registrationOtpRequested = true;
        _registrationDevelopmentCode = result.developmentCode;
      });
      return;
    }

    final user = _isRegisterMode
        ? await widget.controller.verifyRegistrationOtp(
            email: _emailController.text,
            code: _registrationOtpController.text,
          )
        : await widget.controller.login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (!mounted || user == null) return;
    if (_effectivePortal == LoginPortal.resident && !user.role.isResident) {
      widget.controller.rejectCurrentLogin(
        'Đây là tài khoản quản lý hoặc nhân viên. Vui lòng chuyển sang tab Quản lý & nhân viên.',
      );
      return;
    }
    if (_effectivePortal == LoginPortal.staff && !user.role.isStaff) {
      widget.controller.rejectCurrentLogin(
        'Đây là tài khoản cư dân. Vui lòng chuyển sang tab Cư dân.',
      );
      return;
    }
    widget.onLoginSuccess(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFEAF2FF),
              AppColors.background,
              Color(0xFFEDF9F7),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showBrandPanel = constraints.maxWidth >= 960;

              if (showBrandPanel) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 11,
                        child: _BrandPanel(
                          isRegisterMode: _isRegisterMode,
                          portal: _effectivePortal,
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 28,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: _buildAnimatedAuthContent(
                                showCompactBrand: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth < 420 ? 16 : 24,
                    8,
                    constraints.maxWidth < 420 ? 16 : 24,
                    16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildAnimatedAuthContent(showCompactBrand: true),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAuthContent({required bool showCompactBrand}) {
    return _buildLoginContent(showCompactBrand: showCompactBrand);
  }

  Widget _buildLoginContent({required bool showCompactBrand}) {
    if (_isRegisterMode) {
      return _buildRegisterContent(showCompactBrand: showCompactBrand);
    }

    final theme = Theme.of(context);
    final isLoading = widget.controller.isLoading;
    final compactViewport = MediaQuery.sizeOf(context).height < 960;
    final portal = _effectivePortal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showCompactBrand) ...<Widget>[
          _MobileAuthHeader(
            title: portal == LoginPortal.staff
                ? 'Cổng quản lý Homie'
                : 'Chào mừng trở lại',
            subtitle: portal == LoginPortal.staff
                ? 'Dành cho ban quản lý và nhân viên được cấp quyền.'
                : 'Đăng nhập tài khoản cư dân Homie.',
            imagePath: 'assets/images/auth/login-living-room.png',
          ),
          SizedBox(height: compactViewport ? 12 : 16),
        ] else ...<Widget>[
          Text(
            portal == LoginPortal.staff
                ? 'QUẢN LÝ & NHÂN VIÊN'
                : 'HOMIE CƯ DÂN',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            portal == LoginPortal.staff
                ? 'Đăng nhập nội bộ'
                : 'Chào mừng trở lại',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            portal == LoginPortal.staff
                ? 'Truy cập không gian vận hành theo vai trò được quản trị viên cấp.'
                : 'Quản lý căn hộ và dịch vụ của bạn.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 4),
        ],
        SizedBox(height: compactViewport ? 8 : 16),
        if (widget.portal == LoginPortal.combined) ...<Widget>[
          _PortalSwitcher(
            selected: portal,
            enabled: !isLoading,
            onSelected: _selectPortal,
          ),
          SizedBox(height: compactViewport ? 12 : 16),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD7E3F4)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x1A1B4D9B),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compactViewport ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _AuthFormHeader(
                    icon: portal == LoginPortal.staff
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline_rounded,
                    eyebrow: portal == LoginPortal.staff
                        ? 'TÀI KHOẢN NỘI BỘ'
                        : '',
                    title: portal == LoginPortal.staff
                        ? 'Đăng nhập quản lý'
                        : 'Tài khoản cư dân',
                    subtitle: portal == LoginPortal.staff
                        ? 'Chỉ tài khoản đã được quản trị viên cấp quyền mới có thể truy cập.'
                        : '',
                    compact: compactViewport,
                  ),
                  SizedBox(height: compactViewport ? 16 : 22),
                  TextFormField(
                    key: const ValueKey<String>('auth-email'),
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'tenban@example.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Vui lòng nhập email.';
                      final looksLikeEmail = RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email);
                      if (!looksLikeEmail) return 'Email chưa đúng định dạng.';
                      return null;
                    },
                    onChanged: (_) => widget.controller.clearError(),
                  ),
                  SizedBox(height: compactViewport ? 12 : 18),
                  TextFormField(
                    key: const ValueKey<String>('auth-password'),
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Vui lòng nhập mật khẩu.';
                      }
                      if (value!.length < 8) {
                        return 'Mật khẩu cần ít nhất 8 ký tự.';
                      }
                      return null;
                    },
                    onChanged: (_) => widget.controller.clearError(),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey<String>('forgot-password'),
                      onPressed: isLoading
                          ? null
                          : () => ForgotPasswordSheet.show(
                              context,
                              controller: widget.controller,
                              initialEmail: _emailController.text,
                            ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: widget.controller.errorMessage == null
                        ? SizedBox(height: compactViewport ? 8 : 22)
                        : Padding(
                            key: const ValueKey<String>('login-error'),
                            padding: const EdgeInsets.only(top: 16),
                            child: _ErrorMessage(
                              message: widget.controller.errorMessage!,
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  _GradientActionButton(
                    label: 'Đăng nhập',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (portal != LoginPortal.staff) ...<Widget>[
          const SizedBox(height: 14),
          _AuthModePrompt(
            message: 'Bạn chưa có tài khoản?',
            actionLabel: 'Đăng ký',
            isLoading: isLoading,
            onPressed: _toggleMode,
          ),
        ],
        if (portal == LoginPortal.resident &&
            widget.onContinueAsGuest != null) ...<Widget>[
          const SizedBox(height: 14),
          _GuestAccessButton(
            key: const ValueKey<String>('continue-as-guest'),
            onPressed: isLoading ? null : widget.onContinueAsGuest,
          ),
        ],
        if (portal == LoginPortal.staff) ...<Widget>[
          const SizedBox(height: 14),
          const _SecurityCaption(
            label: 'Tài khoản nhân viên do quản trị viên cấp',
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterContent({required bool showCompactBrand}) {
    final theme = Theme.of(context);
    final isLoading = widget.controller.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showCompactBrand) ...<Widget>[
          const _MobileAuthHeader(
            title: 'Tạo tài khoản mới',
            subtitle: 'Xác minh email để bắt đầu cùng Homie.',
            imagePath: 'assets/images/auth/register-apartments.png',
          ),
          const SizedBox(height: 16),
        ] else ...<Widget>[
          Text(
            'HOMIE CƯ DÂN',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tạo tài khoản mới',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xác minh email, sau đó liên kết căn hộ khi cần.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD7E3F4)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x1A1B4D9B),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _AuthFormHeader(
                  icon: Icons.person_add_alt_1_rounded,
                  eyebrow: '',
                  title: 'Thông tin đăng ký',
                  subtitle: '',
                ),
                const SizedBox(height: 14),
                const _GuestAccountNotice(),
                const SizedBox(height: 18),
                TextFormField(
                  key: const ValueKey<String>('register-full-name'),
                  controller: _fullNameController,
                  enabled: !isLoading && !_registrationOtpRequested,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nguyễn Văn An',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    final fullName = value?.trim() ?? '';
                    if (fullName.isEmpty) return 'Vui lòng nhập họ và tên.';
                    if (fullName.length < 2) {
                      return 'Họ và tên cần ít nhất 2 ký tự.';
                    }
                    return null;
                  },
                  onChanged: (_) => widget.controller.clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('auth-email'),
                  controller: _emailController,
                  enabled: !isLoading && !_registrationOtpRequested,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'tenban@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Vui lòng nhập email.';
                    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(email);
                    if (!valid) return 'Email chưa đúng định dạng.';
                    return null;
                  },
                  onChanged: (_) => widget.controller.clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('auth-password'),
                  controller: _passwordController,
                  enabled: !isLoading && !_registrationOtpRequested,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                      onPressed: isLoading || _registrationOtpRequested
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Vui lòng nhập mật khẩu.';
                    }
                    if (value!.length < 8) {
                      return 'Mật khẩu cần ít nhất 8 ký tự.';
                    }
                    return null;
                  },
                  onChanged: (_) => widget.controller.clearError(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Sử dụng ít nhất 8 ký tự',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey<String>('register-confirm-password'),
                  controller: _confirmPasswordController,
                  enabled: !isLoading && !_registrationOtpRequested,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Hiện mật khẩu xác nhận'
                          : 'Ẩn mật khẩu xác nhận',
                      onPressed: isLoading || _registrationOtpRequested
                          ? null
                          : () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu.';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận chưa khớp.';
                    }
                    return null;
                  },
                  onChanged: (_) => widget.controller.clearError(),
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_registrationOtpRequested) ...<Widget>[
                  const SizedBox(height: 16),
                  RegistrationOtpNotice(
                    email: _emailController.text.trim().toLowerCase(),
                    developmentCode: _registrationDevelopmentCode,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey<String>('register-otp-code'),
                    controller: _registrationOtpController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP email',
                      hintText: 'Nhập 6 chữ số',
                      counterText: '',
                      prefixIcon: Icon(Icons.mark_email_read_outlined),
                    ),
                    validator: (value) {
                      if (!_registrationOtpRequested) return null;
                      if (!RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')) {
                        return 'Mã OTP phải gồm đúng 6 chữ số.';
                      }
                      return null;
                    },
                    onChanged: (_) => widget.controller.clearError(),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final result = await widget.controller
                                  .requestRegistrationOtp(
                                    fullName: _fullNameController.text,
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );
                              if (!mounted || result == null) return;
                              _registrationOtpController.clear();
                              setState(
                                () => _registrationDevelopmentCode =
                                    result.developmentCode,
                              );
                            },
                      child: const Text('Gửi lại mã'),
                    ),
                  ),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: widget.controller.errorMessage == null
                      ? const SizedBox(height: 20)
                      : Padding(
                          key: const ValueKey<String>('login-error'),
                          padding: const EdgeInsets.only(top: 16),
                          child: _ErrorMessage(
                            message: widget.controller.errorMessage!,
                          ),
                        ),
                ),
                _GradientActionButton(
                  label: _registrationOtpRequested
                      ? 'Xác minh và tạo tài khoản'
                      : 'Gửi mã xác minh email',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _AuthModePrompt(
          message: 'Bạn đã có tài khoản?',
          actionLabel: 'Đăng nhập',
          isLoading: isLoading,
          onPressed: _toggleMode,
        ),
      ],
    );
  }
}

class _PortalSwitcher extends StatelessWidget {
  const _PortalSwitcher({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final LoginPortal selected;
  final bool enabled;
  final ValueChanged<LoginPortal> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5E1F1)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _PortalTab(
              key: const ValueKey<String>('portal-resident-tab'),
              label: 'Cư dân',
              icon: Icons.home_work_outlined,
              selected: selected == LoginPortal.resident,
              enabled: enabled,
              selectedColor: AppColors.primary,
              onTap: () => onSelected(LoginPortal.resident),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PortalTab(
              key: const ValueKey<String>('portal-staff-tab'),
              label: 'Quản lý & nhân viên',
              icon: Icons.admin_panel_settings_outlined,
              selected: selected == LoginPortal.staff,
              enabled: enabled,
              selectedColor: AppColors.primaryDark,
              onTap: () => onSelected(LoginPortal.staff),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalTab extends StatelessWidget {
  const _PortalTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.selectedColor,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: selectedColor.withValues(alpha: .24),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 19, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileAuthHeader extends StatelessWidget {
  const _MobileAuthHeader({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final compactHeader = viewportHeight < 720;

    return Container(
      height: compactHeader
          ? 110
          : viewportHeight < 960
          ? 226
          : 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x242F6FED),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: <double>[0, 0.5, 1],
                colors: <Color>[
                  Color(0xFFF7FBFF),
                  Color(0xE6F7FBFF),
                  Color(0x05FFFFFF),
                ],
              ),
            ),
          ),
          Positioned(
            left: compactHeader ? 12 : 20,
            top: compactHeader ? 12 : 20,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compactHeader ? 8 : 12,
                vertical: compactHeader ? 6 : 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white),
              ),
              child: const _BrandMark(
                textColor: AppColors.primaryDark,
                compact: true,
              ),
            ),
          ),
          Positioned(
            left: compactHeader ? 16 : 22,
            right: compactHeader ? 72 : 138,
            bottom: compactHeader ? 14 : 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style:
                      (compactHeader
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                            letterSpacing: -1.0,
                          ),
                ),
                if (!compactHeader) ...<Widget>[
                  const SizedBox(height: 9),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF536680),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.brightness_5_rounded,
                color: Color(0xFFFFA45B),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestAccountNotice extends StatelessWidget {
  const _GuestAccountNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8F8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Quyền cư dân được mở sau khi căn hộ được xác minh.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF526581),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? const <Color>[Color(0xFF9BB7F0), Color(0xFF8CD8E3)]
              : const <Color>[Color(0xFF2868F4), Color(0xFF00BEDA)],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: onPressed == null
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x332A77ED),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Center(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_forward_rounded, size: 21),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AuthFormHeader extends StatelessWidget {
  const _AuthFormHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (eyebrow.isNotEmpty) ...[
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              if (!compact && subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFEAF1FF), Color(0xFFE7FAF7)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ],
    );
  }
}

class _GuestAccessButton extends StatelessWidget {
  const _GuestAccessButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF117D87), Color(0xFF0BA8A5)],
              ),
        color: onPressed == null ? AppColors.surfaceMuted : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: onPressed == null ? AppColors.border : const Color(0xFF0D8F98),
        ),
        boxShadow: onPressed == null
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x260F8E97),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    'Tiếp tục với tư cách khách',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthModePrompt extends StatelessWidget {
  const _AuthModePrompt({
    required this.message,
    required this.actionLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          key: const ValueKey<String>('toggle-auth-mode'),
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SecurityCaption extends StatelessWidget {
  const _SecurityCaption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.shield_outlined, size: 15, color: AppColors.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.isRegisterMode, required this.portal});

  final bool isRegisterMode;
  final LoginPortal portal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x302F6FED),
            blurRadius: 42,
            offset: Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              isRegisterMode
                  ? 'assets/images/auth/register-apartments.png'
                  : 'assets/images/auth/login-living-room.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xE6164FAF),
                    Color(0xB81958C5),
                    Color(0x6B082D6A),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: -100,
            top: -100,
            child: _DecorativeOrb(size: 280, color: Color(0x24FFFFFF)),
          ),
          const Positioned(
            left: -70,
            bottom: 70,
            child: _DecorativeOrb(size: 190, color: Color(0x1F73DCCF)),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _BrandMark(textColor: Colors.white),
                const Spacer(),
                Text(
                  isRegisterMode
                      ? 'Bắt đầu hành trình\ncùng Homie'
                      : portal == LoginPortal.staff
                      ? 'Vận hành tập trung,\nphân quyền rõ ràng'
                      : 'Sống tiện nghi hơn\ncùng Homie',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isRegisterMode
                      ? 'Tạo tài khoản để khám phá căn hộ và kết nối với cộng đồng cư dân.'
                      : portal == LoginPortal.staff
                      ? 'Quản lý cư dân, căn hộ, tài chính và yêu cầu vận hành trong một cổng nội bộ.'
                      : 'Căn hộ, dịch vụ và cộng đồng trong một ứng dụng.',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: const Color(0xFFDDEAFF), height: 1.45),
                ),
                const SizedBox(height: 28),
                _LivingPreview(isRegisterMode: isRegisterMode),
                const Spacer(),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 17,
                      color: Color(0xFFDDEAFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Riêng tư theo từng tài khoản',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFFDDEAFF)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivingPreview extends StatelessWidget {
  const _LivingPreview({required this.isRegisterMode});

  final bool isRegisterMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26113A82),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isRegisterMode
                          ? 'Tài khoản cư dân mới'
                          : 'Mọi thứ trong tầm tay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isRegisterMode
                          ? 'Chưa liên kết căn hộ'
                          : 'Dành riêng cho cư dân Homie',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isRegisterMode ? 'Chờ xác minh' : 'Bảo mật',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _PreviewShortcut(
                  icon: isRegisterMode
                      ? Icons.travel_explore_rounded
                      : Icons.apartment_outlined,
                  label: isRegisterMode ? 'Khám phá' : 'Căn hộ',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PreviewShortcut(
                  icon: isRegisterMode
                      ? Icons.real_estate_agent_outlined
                      : Icons.room_service_outlined,
                  label: isRegisterMode ? 'Thuê / mua' : 'Dịch vụ',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PreviewShortcut(
                  icon: isRegisterMode
                      ? Icons.verified_user_outlined
                      : Icons.groups_outlined,
                  label: isRegisterMode ? 'Xác minh' : 'Cộng đồng',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewShortcut extends StatelessWidget {
  const _PreviewShortcut({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 21, color: AppColors.primary),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.textColor, this.compact = false});

  final Color textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 38 : 50,
          height: compact ? 38 : 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF2D6BFF), Color(0xFF00BDD3)],
            ),
            borderRadius: BorderRadius.circular(compact ? 13 : 16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x35205FE2),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          padding: EdgeInsets.all(compact ? 7 : 9),
          child: CustomPaint(painter: const _HomieLogoPainter()),
        ),
        SizedBox(width: compact ? 10 : 12),
        Text(
          'Homie',
          style:
              (compact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
        ),
      ],
    );
  }
}

class _HomieLogoPainter extends CustomPainter {
  const _HomieLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final house = Path()
      ..moveTo(size.width * 0.12, size.height * 0.44)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.88, size.height * 0.44)
      ..lineTo(size.width * 0.88, size.height * 0.86)
      ..moveTo(size.width * 0.12, size.height * 0.44)
      ..lineTo(size.width * 0.12, size.height * 0.86);
    canvas.drawPath(house, stroke);

    final monogram = Path()
      ..moveTo(size.width * 0.34, size.height * 0.48)
      ..lineTo(size.width * 0.34, size.height * 0.84)
      ..moveTo(size.width * 0.66, size.height * 0.48)
      ..lineTo(size.width * 0.66, size.height * 0.84)
      ..moveTo(size.width * 0.34, size.height * 0.66)
      ..lineTo(size.width * 0.66, size.height * 0.66);
    canvas.drawPath(monogram, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
