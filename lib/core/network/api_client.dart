import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? accessToken;
  Future<bool> Function()? refreshAccessToken;

  Future<Map<String, dynamic>> get(String path) {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?>? body,
    bool retryOnUnauthorized = true,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, Object?>? body,
  }) {
    return _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send('DELETE', path);
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required List<int> bytes,
    required String fileName,
    required String fieldName,
    required String mimeType,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(<String, String>{
        'accept': 'application/json',
        if (accessToken != null) 'authorization': 'Bearer $accessToken',
      })
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeBody(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _readErrorMessage(decoded),
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException('Tải tệp quá lâu. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException('Không thể kết nối máy chủ để tải tệp.');
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)
      ..headers.addAll(<String, String>{
        'accept': 'application/json',
        'content-type': 'application/json; charset=utf-8',
        if (accessToken != null) 'authorization': 'Bearer $accessToken',
      });
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeBody(response);

      if (response.statusCode == 401 && retryOnUnauthorized) {
        final refreshed = await refreshAccessToken?.call() ?? false;
        if (refreshed) {
          return await _send(
            method,
            path,
            body: body,
            retryOnUnauthorized: false,
          );
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _readErrorMessage(decoded),
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'API phản hồi quá lâu. Hãy kiểm tra NestJS đang chạy.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Không thể kết nối API. Hãy kiểm tra địa chỉ máy chủ.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    try {
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String _readErrorMessage(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List) {
      return message.whereType<String>().join('\n');
    }
    return 'Yêu cầu không thành công. Vui lòng thử lại.';
  }

  void close() => _client.close();
}
