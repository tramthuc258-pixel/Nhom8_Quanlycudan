import 'package:homie/features/auth/models/authentication_exception.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/models/registration_otp_result.dart';
import 'package:homie/features/auth/services/auth_repository.dart';

class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<RegistrationOtpResult> requestOtp({
    required String fullName,
    required String email,
    required String password,
  }) {
    final normalizedFullName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedFullName.length < 2) {
      throw const AuthenticationException('Họ và tên cần có ít nhất 2 ký tự.');
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail)) {
      throw const AuthenticationException('Email chưa đúng định dạng.');
    }
    if (password.length < 8) {
      throw const AuthenticationException('Mật khẩu cần có ít nhất 8 ký tự.');
    }

    return _repository.requestRegistrationOtp(
      fullName: normalizedFullName,
      email: normalizedEmail,
      password: password,
    );
  }

  Future<User> verifyOtp({required String email, required String code}) {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedCode = code.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail)) {
      throw const AuthenticationException('Email chưa đúng định dạng.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedCode)) {
      throw const AuthenticationException('Mã OTP phải gồm đúng 6 chữ số.');
    }
    return _repository.verifyRegistrationOtp(
      email: normalizedEmail,
      code: normalizedCode,
    );
  }
}
