import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:homie/core/notifications/push_notification_service.dart';
import 'package:homie/features/auth/models/authentication_exception.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/models/forgot_password_result.dart';
import 'package:homie/features/auth/models/registration_otp_result.dart';
import 'package:homie/features/auth/services/auth_repository.dart';
import 'package:homie/features/auth/services/login.dart';
import 'package:homie/features/auth/services/register.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._login,
    this._register, [
    this._repository,
    this._pushNotificationService,
  ]);

  final Login _login;
  final Register _register;
  final AuthRepository? _repository;
  final PushNotificationService? _pushNotificationService;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> restoreSession() async {
    final repository = _repository;
    if (repository == null || _currentUser != null) return;
    _currentUser = await repository.restoreSession();
    if (_currentUser != null) {
      unawaited(_pushNotificationService?.registerCurrentDevice());
    }
  }

  Future<User?> login({required String email, required String password}) async {
    if (_isLoading) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _login(email: email, password: password);
      _currentUser = user;
      unawaited(_pushNotificationService?.registerCurrentDevice());
      return user;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Không thể đăng nhập lúc này. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RegistrationOtpResult?> requestRegistrationOtp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _register.requestOtp(
        fullName: fullName,
        email: email,
        password: password,
      );
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Không thể tạo tài khoản lúc này. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _register.verifyOtp(email: email, code: code);
      _currentUser = user;
      unawaited(_pushNotificationService?.registerCurrentDevice());
      return user;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Không thể xác minh đăng ký lúc này.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ForgotPasswordResult?> requestPasswordReset({
    required String email,
  }) async {
    final repository = _repository;
    if (_isLoading || repository == null) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await repository.requestPasswordReset(email: email);
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Không thể gửi mã xác nhận lúc này.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final repository = _repository;
    if (_isLoading || repository == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Không thể đặt lại mật khẩu lúc này.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void rejectCurrentLogin(String message) {
    unawaited(_pushNotificationService?.deactivateCurrentDevice());
    _repository?.logout();
    _currentUser = null;
    _errorMessage = message;
    notifyListeners();
  }

  void logout() {
    unawaited(_pushNotificationService?.deactivateCurrentDevice());
    _repository?.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String contactAddress,
    String? avatarUrl,
  }) async {
    final user = _currentUser;
    final repository = _repository;
    if (user == null || _isLoading || repository == null) return false;
    if (fullName.trim().length < 2) {
      _errorMessage = 'Họ và tên phải có ít nhất 2 ký tự.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await repository.updateProfile(
        userId: user.id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        contactAddress: contactAddress,
        avatarUrl: avatarUrl,
      );
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvatar(String avatarUrl) {
    final user = _currentUser;
    if (user == null) return Future<bool>.value(false);
    return updateProfile(
      fullName: user.fullName,
      phoneNumber: user.phoneNumber ?? '',
      dateOfBirth: user.dateOfBirth,
      contactAddress: user.contactAddress ?? '',
      avatarUrl: avatarUrl,
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    final repository = _repository;
    if (user == null || _isLoading || repository == null) return false;
    if (newPassword.length < 8) {
      _errorMessage = 'Mật khẩu mới phải có ít nhất 8 ký tự.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.changePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _currentUser = user.copyWith(mustChangePassword: false);
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
