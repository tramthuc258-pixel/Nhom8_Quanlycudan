import 'package:flutter/foundation.dart';

import '../models/staff_scope.dart';
import '../services/staff_assignment_api_data_source.dart';

class StaffAssignmentController extends ChangeNotifier {
  StaffAssignmentController(this._dataSource);

  final StaffAssignmentApiDataSource _dataSource;
  List<StaffScope> staff = const [];
  List<BuildingScope> buildings = const [];
  List<BuildingScope> myBuildings = const [];
  bool globalAccess = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _dataSource.findStaff(),
        _dataSource.findBuildings(),
      ]);
      staff = result[0] as List<StaffScope>;
      buildings = result[1] as List<BuildingScope>;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('ApiException: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assign({required String userId, required String buildingId}) =>
      _save(() => _dataSource.assign(userId: userId, buildingId: buildingId));

  Future<void> loadMyScope() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _dataSource.findMyBuildings();
      globalAccess = result.globalAccess;
      myBuildings = result.buildings;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('ApiException: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> end(String assignmentId) =>
      _save(() => _dataSource.end(assignmentId));

  Future<StaffInvitationResult?> createStaff({
    required String fullName,
    required String email,
    required String role,
    required List<String> buildingIds,
  }) async {
    StaffInvitationResult? result;
    final ok = await _save(() async {
      result = await _dataSource.createStaff(
        fullName: fullName,
        email: email,
        role: role,
        buildingIds: buildingIds,
      );
    });
    return ok ? result : null;
  }

  Future<bool> updateStaff({
    required String id,
    required String fullName,
    required String role,
  }) => _save(
    () => _dataSource.updateStaff(id: id, fullName: fullName, role: role),
  );

  Future<bool> setActive(StaffScope staff, bool active) => _save(
    () => _dataSource.updateStatus(
      id: staff.id,
      status: active ? 'ACTIVE' : 'LOCKED',
    ),
  );

  Future<StaffInvitationResult?> resetPassword(String id) async {
    StaffInvitationResult? result;
    final ok = await _save(() async {
      result = await _dataSource.resetPassword(id);
    });
    return ok ? result : null;
  }

  Future<bool> _save(Future<void> Function() action) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
