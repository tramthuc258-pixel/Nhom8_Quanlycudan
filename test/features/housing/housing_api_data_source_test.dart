import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/services/housing_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc và tạo bài đăng căn hộ qua API', () async {
    final httpClient = MockClient((request) async {
      final listing = <String, Object?>{
        'id': '11111111-1111-4111-8111-111111111111',
        'apartmentId': '22222222-2222-4222-8222-222222222222',
        'apartmentCode': 'A-0101',
        'buildingName': 'Tòa nhà Homie A',
        'title': 'Căn hộ hai phòng ngủ',
        'description': 'Căn hộ thoáng và có thể nhận nhà ngay.',
        'transactionType': 'rent',
        'price': 12000000,
        'deposit': 24000000,
        'availableFrom': '2026-11-01T00:00:00.000Z',
        'status': 'available',
        'createdAt': '2026-10-21T00:00:00.000Z',
        'submittedById': '33333333-3333-4333-8333-333333333333',
        'submittedByName': 'Ban quản lý',
        'ownerSubmitted': false,
        'reviewedAt': null,
        'reviewedBy': null,
        'reviewNote': null,
      };
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': [listing],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['transactionType'], 'RENT');
      expect(body['apartmentId'], listing['apartmentId']);
      return http.Response(
        jsonEncode(listing),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final dataSource = HousingApiDataSource(client);

    final listings = await dataSource.getListings();
    final created = await dataSource.createListing(
      apartmentId: '22222222-2222-4222-8222-222222222222',
      apartmentCode: 'A-0101',
      buildingName: 'Tòa nhà Homie A',
      title: 'Căn hộ hai phòng ngủ',
      description: 'Căn hộ thoáng và có thể nhận nhà ngay.',
      transactionType: HousingTransactionType.rent,
      price: 12000000,
      deposit: 24000000,
      availableFrom: DateTime.utc(2026, 11),
      status: HousingListingStatus.available,
      submittedById: '33333333-3333-4333-8333-333333333333',
      submittedByName: 'Ban quản lý',
      ownerSubmitted: false,
    );

    expect(dataSource.managesMemberships, isTrue);
    expect(listings.single.apartmentCode, 'A-0101');
    expect(created.transactionType, HousingTransactionType.rent);
    expect(created.status, HousingListingStatus.available);
  });
}
