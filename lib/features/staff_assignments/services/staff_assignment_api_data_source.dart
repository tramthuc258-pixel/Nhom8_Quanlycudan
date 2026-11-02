import 'package:homie/core/network/api_client.dart';

import '../models/staff_scope.dart';

class StaffAssignmentApiDataSource {
  const StaffAssignmentApiDataSource(this._client);

  final ApiClient _client;

  Future<List<StaffScope>> findStaff() async {
    final response = await _client.get('/staff-building-assignments/staff');
    return (response['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StaffScope.fromMap)
        .toList(growable: false);
  }

  Future<List<BuildingScope>> findBuildings() async {
    final response = await _client.get('/buildings');
    return (response['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BuildingScope.fromMap)
        .toList(growable: false);
  }

  Future<({bool globalAccess, List<BuildingScope> buildings})>
  findMyBuildings() async {
    final response = await _client.get('/staff-building-assignments/me');
    final globalAccess = response['globalAccess'] as bool? ?? false;
    final items = response['items'] as List<dynamic>? ?? const [];
    final buildings = items
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final building = item['building'];
          if (building is Map<String, dynamic>) {
            return BuildingScope.fromMap(<String, dynamic>{
              ...building,
              'assignmentId': item['id'],
              'isActive': item['isActive'] ?? true,
            });
          }
          return BuildingScope.fromMap(item);
        })
        .toList(growable: false);
    return (globalAccess: globalAccess, buildings: buildings);
  }

  Future<void> assign({required String userId, required String buildingId}) =>
      _client.post(
        '/staff-building-assignments',
        body: {'userId': userId, 'buildingId': buildingId},
      );

  Future<void> end(String assignmentId) =>
      _client.patch('/staff-building-assignments/$assignmentId/end');

  Future<StaffInvitationResult> createStaff({
    required String fullName,
    required String email,
    required String role,
    required List<String> buildingIds,
  }) async {
    final response = await _client.post(
      '/staff-building-assignments/staff',
      body: {
        'fullName': fullName,
        'email': email,
        'role': role,
        'buildingIds': buildingIds,
      },
    );
    return _invitationFromMap(response['invitation']);
  }

  Future<void> updateStaff({
    required String id,
    required String fullName,
    required String role,
  }) => _client.patch(
    '/staff-building-assignments/staff/$id',
    body: {'fullName': fullName, 'role': role},
  );

  Future<void> updateStatus({required String id, required String status}) =>
      _client.patch(
        '/staff-building-assignments/staff/$id/status',
        body: {'status': status},
      );

  Future<StaffInvitationResult> resetPassword(String id) async {
    final response = await _client.post(
      '/staff-building-assignments/staff/$id/reset-password',
    );
    return StaffInvitationResult(
      emailDelivered: response['emailDelivered'] as bool? ?? false,
      temporaryPassword: response['developmentTemporaryPassword'] as String?,
    );
  }

  StaffInvitationResult _invitationFromMap(Object? raw) {
    final map = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    return StaffInvitationResult(
      emailDelivered: map['emailDelivered'] as bool? ?? false,
      temporaryPassword: map['developmentTemporaryPassword'] as String?,
    );
  }
}
