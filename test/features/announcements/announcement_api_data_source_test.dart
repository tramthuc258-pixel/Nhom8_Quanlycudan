import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/announcements/models/announcement_audience.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_model.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/features/announcements/services/announcement_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc, tạo và đánh dấu thông báo đã đọc qua API', () async {
    const userId = '11111111-1111-4111-8111-111111111111';
    const announcementId = '22222222-2222-4222-8222-222222222222';
    final responseItem = <String, Object?>{
      'id': announcementId,
      'title': 'Thông báo kiểm thử',
      'content': 'Nội dung thông báo kiểm thử đầy đủ.',
      'category': 'general',
      'priority': 'important',
      'audience': 'residents',
      'publishedAt': '2026-10-21T00:00:00.000Z',
      'expiresAt': null,
      'isPinned': true,
      'isPublished': true,
      'authorName': 'Ban quản lý',
      'isRead': false,
    };
    final httpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'userId': userId,
            'items': [responseItem],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/read')) {
        return http.Response(
          jsonEncode(<String, Object?>{'success': true}),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['category'], 'GENERAL');
      expect(body['priority'], 'IMPORTANT');
      expect(body['audience'], 'RESIDENTS');
      return http.Response(
        jsonEncode(responseItem),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: httpClient,
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final dataSource = AnnouncementApiDataSource(client);

    final announcements = await dataSource.getAnnouncements();
    expect(announcements.single.id, announcementId);
    expect(dataSource.isRead(announcementId, userId), isFalse);

    await dataSource.markAsRead(announcementId, userId);
    expect(dataSource.isRead(announcementId, userId), isTrue);

    final created = await dataSource.createAnnouncement(
      AnnouncementModel(
        id: 'local-id',
        title: 'Thông báo kiểm thử',
        content: 'Nội dung thông báo kiểm thử đầy đủ.',
        category: AnnouncementCategory.general,
        priority: AnnouncementPriority.important,
        audience: AnnouncementAudience.residents,
        publishedAt: DateTime.utc(2026, 10, 21),
        isPinned: true,
        isPublished: true,
        authorName: 'Ban quản lý',
      ),
    );
    expect(created.category, AnnouncementCategory.general);
  });
}
