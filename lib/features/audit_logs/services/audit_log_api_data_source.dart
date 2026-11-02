import 'package:homie/core/network/api_client.dart';

import '../models/audit_log_entry.dart';

class AuditLogApiDataSource {
  const AuditLogApiDataSource(this._client);

  final ApiClient _client;

  Future<List<AuditLogEntry>> findAll({
    String? action,
    String? resource,
  }) async {
    final query = <String>[
      if (action != null && action.isNotEmpty)
        'action=${Uri.encodeQueryComponent(action)}',
      if (resource != null && resource.isNotEmpty)
        'resource=${Uri.encodeQueryComponent(resource)}',
      'limit=150',
    ].join('&');
    final response = await _client.get('/audit-logs?$query');
    return (response['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AuditLogEntry.fromMap)
        .toList(growable: false);
  }
}
