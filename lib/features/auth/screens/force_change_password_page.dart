import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/auth/controllers/auth_controller.dart';
import 'package:homie/features/auth/models/user.dart';

class ForceChangePasswordPage extends StatefulWidget {
  const ForceChangePasswordPage({
    required this.controller,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final AuthController controller;
  final User user;
  final VoidCallback onLogout;

  @override
  State<ForceChangePasswordPage> createState() =>
      _ForceChangePasswordPageState();
}

class _ForceChangePasswordPageState extends State<ForceChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7FD),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFD9E4F5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFE5EDFF),
                        foregroundColor: AppColors.primary,
                        child: Icon(Icons.password_rounded, size: 30),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Đổi mật khẩu lần đầu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Xin chào ${widget.user.fullName}. Hãy thay mật khẩu tạm thời trước khi sử dụng cổng nhân viên.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF66738D)),
                      ),
                      const SizedBox(height: 26),
                      _passwordField(
                        controller: _currentController,
                        label: 'Mật khẩu tạm thời',
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        controller: _newController,
                        label: 'Mật khẩu mới',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        controller: _confirmController,
                        label: 'Xác nhận mật khẩu mới',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        confirmation: true,
                      ),
                      if (widget.controller.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          widget.controller.errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: widget.controller.isLoading ? null : _submit,
                        icon: widget.controller.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Đổi mật khẩu và tiếp tục'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: widget.onLogout,
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    bool confirmation = false,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) {
      if ((value ?? '').length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
      if (confirmation && value != _newController.text) {
        return 'Mật khẩu xác nhận chưa khớp.';
      }
      return null;
    },
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.controller.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đổi mật khẩu thành công.')),
    );
  }
}
