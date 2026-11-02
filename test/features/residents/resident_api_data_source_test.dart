import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/residence_verification.dart';
import 'package:homie/features/residents/services/resident_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc cư dân và quan hệ căn hộ qua API', () async {
    final httpClient = MockClient((request) async {
      if (request.url.path.endsWith('/residents')) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'id': 'resident-id',
                'fullName': 'Nguyễn Văn An',
                'phone': '0900000000',
                'email': 'an@example.com',
              },
            ],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }
      if (request.url.path.endsWith('/household-members')) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'id': 'household-member-id',
                'apartmentId': 'apartment-id',
                'createdById': 'resident-id',
                'fullName': 'Nguyễn Gia Bảo',
                'dateOfBirth': '2015-08-20T00:00:00.000Z',
                'phone': '',
                'relationship': 'Con',
                'startDate': '2026-10-21T00:00:00.000Z',
                'endDate': null,
                'status': 'active',
              },
            ],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }
      return http.Response(
        jsonEncode(<String, Object?>{
          'items': <Object?>[
            <String, Object?>{
              'id': 'membership-id',
              'apartmentId': 'apartment-id',
              'residentId': 'resident-id',
              'type': 'owner',
              'startDate': '2026-10-21T00:00:00.000Z',
              'endDate': null,
              'status': 'active',
              'isPrimary': true,
            },
          ],
        }),
        200,
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
    final dataSource = ResidentApiDataSource(client);

    final residents = await dataSource.getResidents();
    final memberships = await dataSource.getMemberships();
    final householdMembers = await dataSource.getHouseholdMembers();

    expect(residents.single.email, 'an@example.com');
    expect(memberships.single.type, MembershipType.owner);
    expect(memberships.single.status, MembershipStatus.active);
    expect(householdMembers.single.relationship, 'Con');
    expect(householdMembers.single.phone, isEmpty);
  });

  test('đọc trạng thái riêng tư của chủ sở hữu và người thuê', () {
    final verification = ResidenceVerification.fromMyResponse(<String, Object?>{
      'state': 'approved',
      'membership': <String, Object?>{
        'id': 'membership-id',
        'apartmentId': 'apartment-id',
        'residentId': 'resident-id',
        'type': 'tenant',
        'status': 'active',
        'privacy': <String, Object?>{
          'hasVerifiedOwner': true,
          'hasActiveTenant': true,
        },
      },
    });

    expect(verification.hasVerifiedOwner, isTrue);
    expect(verification.hasActiveTenant, isTrue);
  });
}
