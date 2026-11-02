import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/network/api_client.dart';
import 'package:homie/features/notifications/models/app_notification.dart';
import 'package:homie/features/notifications/services/notification_api_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('đọc và đánh dấu thông báo qua API', () async {
    final item = <String, Object?>{
      'id': '11111111-1111-4111-8111-111111111111',
      'userId': '22222222-2222-4222-8222-222222222222',
      'title': 'Hóa đơn mới',
      'message': 'Hóa đơn tháng 10 đã được phát hành.',
      'type': 'invoice',
      'referenceType': 'invoice',
      'referenceId': '33333333-3333-4333-8333-333333333333',
      'readAt': null,
      'isRead': false,
      'createdAt': '2026-10-22T00:00:00.000Z',
    };
    var patchCount = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'items': [item],
              'unreadCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        patchCount++;
        return http.Response(
          jsonEncode({'success': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..accessToken = 'jwt-test';
    addTearDown(client.close);
    final source = NotificationApiDataSource(client);

    final notifications = await source.getForUser(item['userId']! as String);
    expect(notifications.single.type, AppNotificationType.invoice);
    expect(notifications.single.isRead, isFalse);
    expect(notifications.single.referenceType, 'invoice');
    expect(
      notifications.single.referenceId,
      '33333333-3333-4333-8333-333333333333',
    );
    expect(notifications.single.readAt, isNull);
    await source.markAsRead(item['id']! as String);
    await source.markAllAsRead(item['userId']! as String);
    expect(patchCount, 2);
  });
}
