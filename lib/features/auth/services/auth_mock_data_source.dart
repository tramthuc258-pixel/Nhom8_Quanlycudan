import 'package:homie/features/auth/models/authentication_exception.dart';

import '../models/user_model.dart';
import '../models/forgot_password_result.dart';
import '../models/registration_otp_result.dart';
import 'auth_data_source.dart';

class AuthMockDataSource implements AuthDataSource {
  AuthMockDataSource({this.responseDelay = const Duration(milliseconds: 650)})
    : _accounts = _seedAccounts.map(
        (email, account) => MapEntry(
          email,
          _MockAccount(
            password: account.password,
            userData: Map<String, Object?>.from(account.userData),
          ),
        ),
      );

  final Duration responseDelay;
  final Map<String, _MockAccount> _accounts;
  int _nextResidentNumber = 100;
  final Map<String, String> _resetCodes = <String, String>{};
  final Map<String, _PendingRegistration> _pendingRegistrations =
      <String, _PendingRegistration>{};

  static const Map<String, _MockAccount> _seedAccounts = <String, _MockAccount>{
    'anh.resident@homie.com': _MockAccount(
      password: '12345678',
      userData: <String, Object?>{
        'id': 'resident-001',
        'fullName': 'Nguyễn Minh Anh',
        'email': 'anh.resident@homie.com',
        'role': 'resident',
        'apartmentCode': 'A-1205',
        'phoneNumber': '0901 234 567',
        'dateOfBirth': '1999-03-18T00:00:00.000',
        'contactAddress': 'Căn A-1205, Homie Residence',
      },
    ),
    'trang.owner@homie.com': _MockAccount(
      password: '12345678',
      userData: <String, Object?>{
        'id': 'resident-owner-initial',
        'fullName': 'Đặng Thu Trang',
        'email': 'trang.owner@homie.com',
        'role': 'resident',
        'apartmentCode': 'D-0602',
        'phoneNumber': '0906 777 888',
        'dateOfBirth': '1992-05-20T00:00:00.000',
        'contactAddress': 'Căn D-0602, Homie Residence',
      },
    ),
    'nam.management@homie.com': _MockAccount(
      password: '12345678',
      userData: <String, Object?>{
        'id': 'manager-001',
        'fullName': 'Trần Hoàng Nam',
        'email': 'nam.management@homie.com',
        'role': 'manager',
        'apartmentCode': null,
        'phoneNumber': '0909 888 666',
        'dateOfBirth': '1988-08-12T00:00:00.000',
        'contactAddress': 'Văn phòng Ban quản lý Homie Residence',
      },
    ),
  };

  @override
  Future<UserModel?> restoreSession() async => null;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Mô phỏng thời gian phản hồi của API để UI thể hiện trạng thái tải.
    await Future<void>.delayed(responseDelay);

    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      throw const AuthenticationException(
        'Email hoặc mật khẩu không chính xác.',
      );
    }

    return UserModel.fromMap(account.userData);
  }

  @override
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(responseDelay);

    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      throw const AuthenticationException('Email này đã được sử dụng.');
    }

    _pendingRegistrations[normalizedEmail] = _PendingRegistration(
      fullName: fullName.trim(),
      password: password,
      code: '123456',
    );
    return const RegistrationOtpResult(
      message: 'Mã OTP thử nghiệm đã được tạo.',
      expiresInSeconds: 900,
      developmentCode: '123456',
    );
  }

  @override
  Future<UserModel> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(responseDelay);
    final normalizedEmail = email.trim().toLowerCase();
    final pending = _pendingRegistrations[normalizedEmail];
    if (pending == null || pending.code != code.trim()) {
      throw const AuthenticationException(
        'Mã OTP không hợp lệ hoặc đã hết hạn.',
      );
    }
    final userData = <String, Object?>{
      'id': 'resident-${_nextResidentNumber++}',
      'fullName': pending.fullName,
      'email': normalizedEmail,
      'role': 'resident',
      'apartmentCode': null,
      'phoneNumber': '',
      'dateOfBirth': null,
      'contactAddress': '',
    };
    _accounts[normalizedEmail] = _MockAccount(
      password: pending.password,
      userData: userData,
    );
    _pendingRegistrations.remove(normalizedEmail);
    return UserModel.fromMap(userData);
  }

  @override
  Future<ForgotPasswordResult> requestPasswordReset({
    required String email,
  }) async {
    await Future<void>.delayed(responseDelay);
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      _resetCodes[normalizedEmail] = '123456';
    }
    return const ForgotPasswordResult(
      message: 'Nếu email tồn tại, Homie đã gửi mã đặt lại mật khẩu.',
      developmentCode: '123456',
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(responseDelay);
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null || _resetCodes[normalizedEmail] != code) {
      throw const AuthenticationException(
        'Mã xác nhận không hợp lệ hoặc đã hết hạn.',
      );
    }
    _accounts[normalizedEmail] = _MockAccount(
      password: newPassword,
      userData: account.userData,
    );
    _resetCodes.remove(normalizedEmail);
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String contactAddress,
    String? avatarUrl,
  }) async {
    await Future<void>.delayed(responseDelay);
    final entry = _accounts.entries.where(
      (item) => item.value.userData['id'] == userId,
    );
    if (entry.isEmpty) {
      throw const AuthenticationException('Không tìm thấy tài khoản.');
    }
    final account = entry.first.value;
    account.userData
      ..['fullName'] = fullName.trim()
      ..['phoneNumber'] = phoneNumber.trim()
      ..['dateOfBirth'] = dateOfBirth?.toIso8601String()
      ..['contactAddress'] = contactAddress.trim();
    if (avatarUrl != null) account.userData['avatarUrl'] = avatarUrl;
    return UserModel.fromMap(account.userData);
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(responseDelay);
    final entry = _accounts.entries.where(
      (item) => item.value.userData['id'] == userId,
    );
    if (entry.isEmpty || entry.first.value.password != currentPassword) {
      throw const AuthenticationException('Mật khẩu hiện tại không chính xác.');
    }
    _accounts[entry.first.key] = _MockAccount(
      password: newPassword,
      userData: entry.first.value.userData,
    );
  }

  @override
  void logout() {}
}

class _MockAccount {
  const _MockAccount({required this.password, required this.userData});

  final String password;
  final Map<String, Object?> userData;
}

class _PendingRegistration {
  const _PendingRegistration({
    required this.fullName,
    required this.password,
    required this.code,
  });

  final String fullName;
  final String password;
  final String code;
}
