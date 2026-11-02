import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/models/forgot_password_result.dart';
import 'package:homie/features/auth/models/registration_otp_result.dart';
import 'package:homie/features/auth/services/auth_data_source.dart';
import 'package:homie/features/auth/services/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  @override
  Future<User?> restoreSession() => _dataSource.restoreSession();

  @override
  Future<User> login({required String email, required String password}) {
    return _dataSource.login(email: email, password: password);
  }

  @override
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _dataSource.requestRegistrationOtp(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  @override
  Future<User> verifyRegistrationOtp({
    required String email,
    required String code,
  }) {
    return _dataSource.verifyRegistrationOtp(email: email, code: code);
  }

  @override
  Future<ForgotPasswordResult> requestPasswordReset({required String email}) {
    return _dataSource.requestPasswordReset(email: email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _dataSource.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  @override
  Future<User> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String contactAddress,
    String? avatarUrl,
  }) => _dataSource.updateProfile(
    userId: userId,
    fullName: fullName,
    phoneNumber: phoneNumber,
    dateOfBirth: dateOfBirth,
    contactAddress: contactAddress,
    avatarUrl: avatarUrl,
  );

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) => _dataSource.changePassword(
    userId: userId,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  @override
  void logout() => _dataSource.logout();
}
