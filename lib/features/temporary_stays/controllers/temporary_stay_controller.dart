import 'package:flutter/foundation.dart';

import '../models/temporary_stay.dart';
import '../services/temporary_stay_repository.dart';

class TemporaryStayController extends ChangeNotifier {
  TemporaryStayController({required this.repository});
  final TemporaryStayRepository repository;
  bool isLoading = false;
  String? errorMessage;
  List<TemporaryStay> stays = const [];

  Future<void> load() async => _run(() async {
    final result = await repository.getStays();
    stays = List.unmodifiable(result);
  });

  Future<bool> create({
    required String apartmentId,
    required String guestFullName,
    DateTime? guestDateOfBirth,
    String? guestPhone,
    String? relationshipToResident,
    required DateTime startDate,
    required DateTime endDate,
    String? purpose,
  }) => _mutate(
    () => repository.create(
      apartmentId: apartmentId,
      guestFullName: guestFullName,
      guestDateOfBirth: guestDateOfBirth,
      guestPhone: guestPhone,
      relationshipToResident: relationshipToResident,
      startDate: startDate,
      endDate: endDate,
      purpose: purpose,
    ),
  );
  Future<bool> cancel(String id) => _mutate(() => repository.cancel(id));
  Future<bool> review({
    required String id,
    required bool approved,
    required String note,
  }) =>
      _mutate(() => repository.review(id: id, approved: approved, note: note));
  Future<bool> checkIn(String id) => _mutate(() => repository.checkIn(id));
  Future<bool> checkOut(String id) => _mutate(() => repository.checkOut(id));

  Future<bool> _mutate(Future<Object> Function() action) async {
    var success = true;
    await _run(() async {
      await action();
      stays = List.unmodifiable(await repository.getStays());
    }, onError: () => success = false);
    return success;
  }

  Future<void> _run(
    Future<void> Function() action, {
    VoidCallback? onError,
  }) async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = error is StateError
          ? error.message
          : 'Không thể cập nhật đăng ký khách lưu trú.';
      onError?.call();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
