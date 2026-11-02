import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({
    required this.controller,
    required this.initialEmail,
    super.key,
  });

  final AuthController controller;
  final String initialEmail;

  static Future<void> show(
    BuildContext context, {
    required AuthController controller,
    required String initialEmail,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ForgotPasswordSheet(
        controller: controller,
        initialEmail: initialEmail,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;
  String? _error;
  String? _developmentCode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email chưa đúng định dạng.';
    }
    return null;
  }

  Future<void> _sendCode() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.controller.requestPasswordReset(
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result == null) {
        _error = widget.controller.errorMessage;
        return;
      }
      _codeSent = true;
      _message = result.message;
      _developmentCode = result.developmentCode;
      if (_developmentCode != null) {
        _codeController.text = _developmentCode!;
      }
    });
  }

  Future<void> _resetPassword() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await widget.controller.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = success ? null : widget.controller.errorMessage;
    });
    if (!success) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đổi mật khẩu. Bạn có thể đăng nhập ngay.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxWidth = MediaQuery.sizeOf(context).width >= 720 ? 560.0 : 520.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _codeSent ? _buildResetStep() : _buildEmailStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Column(
      children: <Widget>[
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey<String>('forgot-email-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(
            title: 'Quên mật khẩu?',
            subtitle: 'Nhập email tài khoản Homie. Chúng tôi sẽ gửi mã xác nhận gồm 6 chữ số.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const ValueKey<String>('forgot-email'),
            controller: _emailController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: _validateEmail,
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            _InlineMessage(message: _error!, isError: true),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey<String>('send-reset-code'),
            onPressed: _busy ? null : _sendCode,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mail_outline_rounded),
            label: const Text('Gửi mã xác nhận'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Quay lại đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey<String>('forgot-reset-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(
            title: 'Tạo mật khẩu mới',
            subtitle: 'Nhập mã đã gửi tới ${_emailController.text.trim()}.',
          ),
          const SizedBox(height: 18),
          if (_message != null) _InlineMessage(message: _message!),
          if (_developmentCode != null) ...<Widget>[
            const SizedBox(height: 10),
            _InlineMessage(
              message:
                  'Chế độ phát triển: mã xác nhận là $_developmentCode. Khi cấu hình SMTP, mã này sẽ chỉ được gửi qua email.',
            ),
          ],
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey<String>('reset-code'),
            controller: _codeController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Mã xác nhận',
              prefixIcon: Icon(Icons.password_rounded),
              counterText: '',
            ),
            validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                ? null
                : 'Mã xác nhận phải gồm 6 chữ số.',
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey<String>('reset-new-password'),
            controller: _passwordController,
            enabled: !_busy,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: _busy
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => (value ?? '').length >= 8
                ? null
                : 'Mật khẩu mới cần ít nhất 8 ký tự.',
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey<String>('reset-confirm-password'),
            controller: _confirmPasswordController,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Xác nhận mật khẩu mới',
              prefixIcon: Icon(Icons.lock_reset_rounded),
            ),
            validator: (value) => value == _passwordController.text
                ? null
                : 'Mật khẩu xác nhận chưa khớp.',
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            _InlineMessage(message: _error!, isError: true),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey<String>('confirm-reset-password'),
            onPressed: _busy ? null : _resetPassword,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Đặt lại mật khẩu'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _codeSent = false;
                    _error = null;
                  }),
            child: const Text('Gửi lại mã cho email khác'),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background = isError
        ? Theme.of(context).colorScheme.errorContainer
        : const Color(0xFFEAF2FF);
    final foreground = isError
        ? Theme.of(context).colorScheme.onErrorContainer
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: TextStyle(color: foreground, height: 1.4)),
    );
  }
}
