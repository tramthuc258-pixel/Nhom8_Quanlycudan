import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/apartments/services/apartment_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc và tạo căn hộ qua API', () async {
    final httpClient = MockClient((request) async {
      final apartment = <String, Object?>{
        'id': 'apartment-id',
        'code': 'A-0101',
        'buildingName': 'Tòa nhà Homie A',
        'floor': 1,
        'area': 68.5,
        'bedrooms': 2,
        'status': 'vacant',
      };
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': [apartment],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['status'], 'VACANT');
      return http.Response(
        jsonEncode(apartment),
        201,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final dataSource = ApartmentApiDataSource(client);

    final apartments = await dataSource.getApartments();
    final created = await dataSource.createApartment(
      code: 'A-0101',
      buildingName: 'Tòa nhà Homie A',
      floor: 1,
      area: 68.5,
      bedrooms: 2,
      status: ApartmentStatus.vacant,
    );

    expect(apartments.single.code, 'A-0101');
    expect(created.area, 68.5);
    expect(created.status, ApartmentStatus.vacant);
  });
}
