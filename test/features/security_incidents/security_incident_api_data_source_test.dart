import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/security_incidents/models/security_incident_status.dart';
import 'package:homie/features/security_incidents/models/security_incident_type.dart';
import 'package:homie/features/security_incidents/services/security_incident_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc và gửi sự cố an ninh qua API', () async {
    final item = <String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'code': 'AN-2026-TEST',
      'buildingId': '22222222-2222-4222-8222-222222222222',
      'buildingName': 'Homie A',
      'apartmentId': '33333333-3333-4333-8333-333333333333',
      'apartmentCode': 'A-0101',
      'reportedById': '44444444-4444-4444-8444-444444444444',
      'reportedByName': 'Cư dân kiểm thử',
      'type': 'noise',
      'title': 'Tiếng ồn hành lang',
      'description': 'Tiếng nhạc lớn kéo dài ngoài hành lang.',
      'location': 'Tầng 1',
      'occurredAt': '2026-10-22T00:00:00.000Z',
      'status': 'reported',
      'resolutionNote': null,
      'resolvedByName': null,
      'createdAt': '2026-10-22T00:00:00.000Z',
      'updatedAt': '2026-10-22T00:00:00.000Z',
    };
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'items': [item],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'NOISE');
        return http.Response(
          jsonEncode(item),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final source = SecurityIncidentApiDataSource(client);
    expect(
      (await source.getIncidents()).single.status,
      SecurityIncidentStatus.reported,
    );
    final created = await source.create(
      apartmentId: item['apartmentId']! as String,
      type: SecurityIncidentType.noise,
      title: 'Tiếng ồn hành lang',
      description: 'Tiếng nhạc lớn kéo dài ngoài hành lang.',
      location: 'Tầng 1',
      occurredAt: DateTime.utc(2026, 10, 22),
    );
    expect(created.type, SecurityIncidentType.noise);
  });
}
