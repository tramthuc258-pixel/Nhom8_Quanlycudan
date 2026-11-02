import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/models/forgot_password_result.dart';
import 'package:homie/features/auth/models/registration_otp_result.dart';

abstract interface class AuthRepository {
  Future<User?> restoreSession();

  Future<User> login({required String email, required String password});

  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<User> verifyRegistrationOtp({
    required String email,
    required String code,
  });

  Future<ForgotPasswordResult> requestPasswordReset({required String email});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<User> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String contactAddress,
    String? avatarUrl,
  });

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  void logout();
}
