import 'dart:async';

import 'package:homie/core/network/api_client.dart';
import 'package:homie/core/network/api_exception.dart';
import 'package:homie/features/auth/models/authentication_exception.dart';
import 'package:homie/features/auth/models/user_model.dart';
import 'package:homie/features/auth/models/forgot_password_result.dart';
import 'package:homie/features/auth/models/registration_otp_result.dart';

import 'auth_data_source.dart';
import 'auth_session_store.dart';

class AuthApiDataSource implements AuthDataSource {
  AuthApiDataSource(this._apiClient, {this.sessionStore}) {
    if (sessionStore != null) {
      _apiClient.refreshAccessToken = _refreshAccessToken;
    }
  }

  final ApiClient _apiClient;
  final AuthSessionStore? sessionStore;

  @override
  Future<UserModel?> restoreSession() async {
    final store = sessionStore;
    if (store == null) return null;
    try {
      final token = await store.readAccessToken();
      final refreshToken = await store.readRefreshToken();
      if ((token == null || token.isEmpty) &&
          (refreshToken == null || refreshToken.isEmpty)) {
        return null;
      }
      _apiClient.accessToken = token;
      if ((token == null || token.isEmpty) && !await _refreshAccessToken()) {
        return null;
      }
      final response = await _apiClient.get('/auth/profile');
      return UserModel.fromApiMap(response);
    } catch (_) {
      _apiClient.accessToken = null;
      await store.clear();
      return null;
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return _authenticate('/auth/login', <String, Object?>{
      'email': email,
      'password': password,
    });
  }

  @override
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        body: <String, Object?>{
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      return RegistrationOtpResult(
        message:
            response['message'] as String? ??
            'Homie đã gửi mã OTP xác minh đến email của bạn.',
        expiresInSeconds: response['expiresInSeconds'] as int? ?? 900,
        developmentCode: response['developmentCode'] as String?,
      );
    } on ApiException catch (error) {
      throw AuthenticationException(error.message);
    }
  }

  @override
  Future<UserModel> verifyRegistrationOtp({
    required String email,
    required String code,
  }) {
    return _authenticate('/auth/register/verify', <String, Object?>{
      'email': email,
      'code': code,
    });
  }

  @override
  Future<ForgotPasswordResult> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        body: <String, Object?>{'email': email},
      );
      return ForgotPasswordResult(
        message:
            response['message'] as String? ??
            'Nếu email tồn tại, Homie đã gửi mã đặt lại mật khẩu.',
        developmentCode: response['developmentCode'] as String?,
      );
    } on ApiException catch (error) {
      throw AuthenticationException(error.message);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        '/auth/reset-password',
        body: <String, Object?>{
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on ApiException catch (error) {
      throw AuthenticationException(error.message);
    }
  }

  Future<UserModel> _authenticate(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _apiClient.post(path, body: body);
      final token = response['accessToken'];
      final refreshToken = response['refreshToken'];
      final user = response['user'];
      if (token is! String || user is! Map<String, dynamic>) {
        throw const AuthenticationException('Phản hồi đăng nhập không hợp lệ.');
      }
      _apiClient.accessToken = token;
      if (refreshToken is String && refreshToken.isNotEmpty) {
        await sessionStore?.saveSession(
          accessToken: token,
          refreshToken: refreshToken,
        );
      } else {
        await sessionStore?.saveAccessToken(token);
      }
      return UserModel.fromApiMap(user);
    } on ApiException catch (error) {
      throw AuthenticationException(error.message);
    }
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
    try {
      final response = await _apiClient.patch(
        '/auth/profile',
        body: <String, Object?>{
          'fullName': fullName,
          if (phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber,
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          if (contactAddress.trim().isNotEmpty)
            'contactAddress': contactAddress,
          'avatarUrl': ?avatarUrl,
        },
      );
      return UserModel.fromApiMap(response);
    } on ApiException catch (error) {
      throw AuthenticationException(error.message);
    }
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/change-password',
        body: <String, Object?>{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      await _saveTokens(response);
    } on ApiException catch (error) {
      throw AuthenticationException(error.message);
    }
  }

  @override
  void logout() {
    unawaited(_revokeAndClear());
  }

  Future<bool> _refreshAccessToken() async {
    final store = sessionStore;
    if (store == null) return false;
    final token = await store.readRefreshToken();
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        body: <String, Object?>{'refreshToken': token},
        retryOnUnauthorized: false,
      );
      return await _saveTokens(response);
    } catch (_) {
      _apiClient.accessToken = null;
      await store.clear();
      return false;
    }
  }

  Future<bool> _saveTokens(Map<String, dynamic> response) async {
    final accessToken = response['accessToken'];
    final refreshToken = response['refreshToken'];
    if (accessToken is! String || refreshToken is! String) return false;
    _apiClient.accessToken = accessToken;
    await sessionStore?.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    return true;
  }

  Future<void> _revokeAndClear() async {
    final store = sessionStore;
    final refreshToken = await store?.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.post(
          '/auth/logout',
          body: <String, Object?>{'refreshToken': refreshToken},
          retryOnUnauthorized: false,
        );
      } catch (_) {
        // Phiên cục bộ vẫn phải được xóa nếu máy chủ tạm thời không truy cập được.
      }
    }
    _apiClient.accessToken = null;
    await store?.clear();
  }
}
