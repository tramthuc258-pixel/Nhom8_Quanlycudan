import 'package:flutter/foundation.dart';

import '../models/audit_log_entry.dart';
import '../services/audit_log_api_data_source.dart';

class AuditLogController extends ChangeNotifier {
  AuditLogController(this._dataSource);

  final AuditLogApiDataSource _dataSource;
  List<AuditLogEntry> entries = const [];
  bool isLoading = false;
  String? errorMessage;
  String action = '';
  String resource = '';

  Future<void> load({String? action, String? resource}) async {
    this.action = action ?? this.action;
    this.resource = resource ?? this.resource;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      entries = await _dataSource.findAll(
        action: this.action,
        resource: this.resource,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('ApiException: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
