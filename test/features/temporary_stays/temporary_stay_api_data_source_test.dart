import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/temporary_stays/models/temporary_stay_status.dart';
import 'package:homie/features/temporary_stays/services/temporary_stay_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc và tạo đăng ký tạm trú qua API', () async {
    final item = <String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'apartmentId': '22222222-2222-4222-8222-222222222222',
      'apartmentCode': 'A-0101',
      'declaredById': '33333333-3333-4333-8333-333333333333',
      'declaredByName': 'Cư dân kiểm thử',
      'guestFullName': 'Khách kiểm thử',
      'guestDateOfBirth': null,
      'guestPhone': '0909000000',
      'relationshipToResident': 'Bạn',
      'startDate': '2026-10-23T00:00:00.000Z',
      'endDate': '2026-10-25T00:00:00.000Z',
      'purpose': 'Thăm gia đình',
      'status': 'pending',
      'reviewNote': null,
      'reviewedByName': null,
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
        expect(body['guestFullName'], 'Khách kiểm thử');
        return http.Response(
          jsonEncode(item),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final source = TemporaryStayApiDataSource(client);
    expect(
      (await source.getStays()).single.status,
      TemporaryStayStatus.pending,
    );
    final created = await source.create(
      apartmentId: item['apartmentId']! as String,
      guestFullName: 'Khách kiểm thử',
      startDate: DateTime.utc(2026, 10, 23),
      endDate: DateTime.utc(2026, 10, 25),
    );
    expect(created.apartmentCode, 'A-0101');
  });
}
