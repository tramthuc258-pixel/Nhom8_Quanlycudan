import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/auth/models/authentication_exception.dart';
import 'package:homie/features/auth/services/auth_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đăng ký gọi gửi OTP trước rồi mới xác minh tạo tài khoản', () async {
    final requests = <http.Request>[];
    final httpClient = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/auth/register')) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'message': 'Mã OTP đã được gửi.',
            'expiresInSeconds': 900,
            'developmentCode': '123456',
          }),
          201,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode(<String, Object?>{
          'accessToken': 'jwt-resident-token',
          'user': <String, Object?>{
            'id': 'resident-new',
            'fullName': 'Lê Thanh Bình',
            'email': 'binh@example.com',
            'phone': null,
            'dateOfBirth': null,
            'contactAddress': null,
            'apartmentCode': null,
            'roles': <String>['RESIDENT'],
          },
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    );
    addTearDown(apiClient.close);
    final dataSource = AuthApiDataSource(apiClient);

    final otp = await dataSource.requestRegistrationOtp(
      fullName: 'Lê Thanh Bình',
      email: 'binh@example.com',
      password: '12345678',
    );
    expect(otp.developmentCode, '123456');
    expect(apiClient.accessToken, isNull);

    final user = await dataSource.verifyRegistrationOtp(
      email: 'binh@example.com',
      code: '123456',
    );
    expect(user.email, 'binh@example.com');
    expect(user.apartmentCode, isNull);
    expect(apiClient.accessToken, 'jwt-resident-token');
    expect(requests.map((item) => item.url.path), <String>[
      '/api/auth/register',
      '/api/auth/register/verify',
    ]);
  });

  test('đăng nhập qua API lưu JWT và chuyển dữ liệu người dùng', () async {
    late http.Request receivedRequest;
    final httpClient = MockClient((request) async {
      receivedRequest = request;
      return http.Response(
        jsonEncode(<String, Object?>{
          'accessToken': 'jwt-test-token',
          'user': <String, Object?>{
            'id': 'user-1',
            'fullName': 'Quản trị viên',
            'email': 'admin@example.com',
            'phone': '0900000000',
            'dateOfBirth': null,
            'contactAddress': null,
            'apartmentCode': null,
            'roles': <String>['ADMIN'],
          },
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    );
    addTearDown(apiClient.close);
    final dataSource = AuthApiDataSource(apiClient);

    final user = await dataSource.login(
      email: 'admin@example.com',
      password: 'password-123',
    );

    expect(receivedRequest.method, 'POST');
    expect(receivedRequest.url.path, '/api/auth/login');
    expect(apiClient.accessToken, 'jwt-test-token');
    expect(user.email, 'admin@example.com');
    expect(user.role, UserRole.admin);
  });

  test('lỗi từ API được hiển thị thành lỗi đăng nhập tiếng Việt', () async {
    final httpClient = MockClient(
      (_) async => http.Response(
        jsonEncode(<String, Object?>{
          'message': 'Email hoặc mật khẩu không đúng.',
        }),
        401,
        headers: <String, String>{'content-type': 'application/json'},
      ),
    );
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    );
    addTearDown(apiClient.close);
    final dataSource = AuthApiDataSource(apiClient);

    expect(
      () =>
          dataSource.login(email: 'sai@example.com', password: 'password-123'),
      throwsA(
        isA<AuthenticationException>().having(
          (error) => error.message,
          'message',
          'Email hoặc mật khẩu không đúng.',
        ),
      ),
    );
  });
}
