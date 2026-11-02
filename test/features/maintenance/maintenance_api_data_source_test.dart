import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/maintenance/models/maintenance_category.dart';
import 'package:homie/features/maintenance/models/maintenance_priority.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/features/maintenance/services/maintenance_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc và tạo yêu cầu sửa chữa qua API', () async {
    final item = <String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'code': 'YC-2026-TEST',
      'apartmentId': '22222222-2222-4222-8222-222222222222',
      'residentId': '33333333-3333-4333-8333-333333333333',
      'title': 'Vòi nước bị rò rỉ',
      'description': 'Vòi nước trong bếp đang bị rò rỉ liên tục.',
      'location': 'Bếp căn hộ A-0101',
      'category': 'plumbing',
      'priority': 'high',
      'status': 'submitted',
      'createdAt': '2026-10-21T00:00:00.000Z',
      'updatedAt': '2026-10-21T00:00:00.000Z',
      'assignedTo': null,
      'history': <Map<String, Object?>>[
        <String, Object?>{
          'id': '44444444-4444-4444-8444-444444444444',
          'status': 'submitted',
          'note': 'Yêu cầu đã được gửi đến ban quản lý.',
          'actorName': 'Cư dân kiểm thử',
          'createdAt': '2026-10-21T00:00:00.000Z',
        },
      ],
    };
    final httpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': [item],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['category'], 'PLUMBING');
      expect(body['priority'], 'HIGH');
      return http.Response(
        jsonEncode(item),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final dataSource = MaintenanceApiDataSource(client);

    final requests = await dataSource.getRequests();
    final created = await dataSource.createRequest(
      apartmentId: '22222222-2222-4222-8222-222222222222',
      residentId: '33333333-3333-4333-8333-333333333333',
      residentName: 'Cư dân kiểm thử',
      title: 'Vòi nước bị rò rỉ',
      description: 'Vòi nước trong bếp đang bị rò rỉ liên tục.',
      location: 'Bếp căn hộ A-0101',
      category: MaintenanceCategory.plumbing,
      priority: MaintenancePriority.high,
    );

    expect(requests.single.status, MaintenanceStatus.submitted);
    expect(created.history.single.actorName, 'Cư dân kiểm thử');
  });
}
