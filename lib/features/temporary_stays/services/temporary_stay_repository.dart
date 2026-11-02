import '../models/temporary_stay.dart';

abstract interface class TemporaryStayRepository {
  Future<List<TemporaryStay>> getStays();
  Future<TemporaryStay> create({
    required String apartmentId,
    required String guestFullName,
    DateTime? guestDateOfBirth,
    String? guestPhone,
    String? relationshipToResident,
    required DateTime startDate,
    required DateTime endDate,
    String? purpose,
  });
  Future<TemporaryStay> cancel(String id);
  Future<TemporaryStay> review({
    required String id,
    required bool approved,
    required String note,
  });
  Future<TemporaryStay> checkIn(String id);
  Future<TemporaryStay> checkOut(String id);
}
