import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/resident_services/models/service_booking_status.dart';
import 'package:homie/features/resident_services/models/service_category.dart';
import 'package:homie/features/resident_services/services/service_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc danh mục và tạo đăng ký dịch vụ qua API', () async {
    const serviceId = '11111111-1111-4111-8111-111111111111';
    const apartmentId = '22222222-2222-4222-8222-222222222222';
    final service = <String, Object?>{
      'id': serviceId,
      'name': 'Vệ sinh căn hộ',
      'description': 'Vệ sinh tổng quát căn hộ.',
      'category': 'cleaning',
      'unitLabel': 'lần',
      'unitPrice': 350000,
      'estimatedDurationMinutes': 120,
      'providerName': 'Homie Cleaning',
      'contactPhone': '02873001205',
      'isActive': true,
    };
    final booking = <String, Object?>{
      'id': '33333333-3333-4333-8333-333333333333',
      'code': 'DV-2026-TEST',
      'serviceId': serviceId,
      'serviceName': 'Vệ sinh căn hộ',
      'unitPrice': 350000,
      'apartmentId': apartmentId,
      'residentId': '44444444-4444-4444-8444-444444444444',
      'residentName': 'Cư dân kiểm thử',
      'quantity': 2,
      'scheduledAt': '2026-10-25T02:00:00.000Z',
      'note': 'Ưu tiên khu vực bếp.',
      'status': 'pending',
      'createdAt': '2026-10-22T00:00:00.000Z',
      'updatedAt': '2026-10-22T00:00:00.000Z',
      'assignedTo': null,
      'managementNote': null,
    };
    final httpClient = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/catalog')) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': [service],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(<String, Object?>{'items': <Object?>[]}),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['serviceId'], serviceId);
      expect(body['apartmentId'], apartmentId);
      expect(body['quantity'], 2);
      expect(body.containsKey('residentId'), isFalse);
      return http.Response(
        jsonEncode(booking),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final dataSource = ServiceApiDataSource(client);

    final catalog = await dataSource.getServices();
    final requests = await dataSource.getBookings();
    final created = await dataSource.createBooking(
      serviceId: serviceId,
      apartmentId: apartmentId,
      residentId: 'ignored-by-api',
      residentName: 'ignored-by-api',
      quantity: 2,
      scheduledAt: DateTime.utc(2026, 10, 25, 2),
      note: 'Ưu tiên khu vực bếp.',
    );

    expect(catalog.single.category, ServiceCategory.cleaning);
    expect(requests, isEmpty);
    expect(created.status, ServiceBookingStatus.pending);
    expect(created.totalAmount, 700000);
  });
}
