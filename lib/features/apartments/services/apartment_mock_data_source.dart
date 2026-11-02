import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/apartments/models/apartment.dart';

import '../models/apartment_model.dart';
import 'apartment_data_source.dart';

class ApartmentMockDataSource implements ApartmentDataSource {
  int _nextApartmentNumber = 7;

  final List<ApartmentModel> _apartments = <ApartmentModel>[
    const ApartmentModel(
      id: 'apartment-001',
      code: 'A-1205',
      buildingName: 'Tòa A',
      floor: 12,
      area: 72.5,
      bedrooms: 2,
      status: ApartmentStatus.occupied,
    ),
    const ApartmentModel(
      id: 'apartment-002',
      code: 'A-1002',
      buildingName: 'Tòa A',
      floor: 10,
      area: 65,
      bedrooms: 2,
      status: ApartmentStatus.occupied,
    ),
    const ApartmentModel(
      id: 'apartment-003',
      code: 'B-0803',
      buildingName: 'Tòa B',
      floor: 8,
      area: 58,
      bedrooms: 2,
      status: ApartmentStatus.vacant,
    ),
    const ApartmentModel(
      id: 'apartment-004',
      code: 'B-1501',
      buildingName: 'Tòa B',
      floor: 15,
      area: 91.5,
      bedrooms: 3,
      status: ApartmentStatus.occupied,
    ),
    const ApartmentModel(
      id: 'apartment-005',
      code: 'C-0406',
      buildingName: 'Tòa C',
      floor: 4,
      area: 69,
      bedrooms: 2,
      status: ApartmentStatus.underMaintenance,
    ),
    const ApartmentModel(
      id: 'apartment-006',
      code: 'D-0602',
      buildingName: 'Tòa D',
      floor: 6,
      area: 78,
      bedrooms: 2,
      status: ApartmentStatus.occupied,
    ),
  ];

  @override
  Future<List<ApartmentModel>> getApartments() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<ApartmentModel>.unmodifiable(_apartments);
  }

  @override
  Future<ApartmentModel> createApartment({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final normalizedCode = code.trim().toUpperCase();
    _ensureUniqueCode(normalizedCode);

    final apartment = ApartmentModel(
      id: 'apartment-${(_nextApartmentNumber++).toString().padLeft(3, '0')}',
      code: normalizedCode,
      buildingName: buildingName.trim(),
      floor: floor,
      area: area,
      bedrooms: bedrooms,
      status: status,
    );
    _apartments.add(apartment);
    return apartment;
  }

  @override
  Future<ApartmentModel> updateApartment(Apartment apartment) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _apartments.indexWhere((item) => item.id == apartment.id);
    if (index == -1) {
      throw StateError('Không tìm thấy căn hộ cần cập nhật.');
    }

    final normalizedCode = apartment.code.trim().toUpperCase();
    _ensureUniqueCode(normalizedCode, excludingId: apartment.id);
    final updated = ApartmentModel.fromEntity(
      apartment.copyWith(
        code: normalizedCode,
        buildingName: apartment.buildingName.trim(),
      ),
    );
    _apartments[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteApartment(String apartmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _apartments.indexWhere((item) => item.id == apartmentId);
    if (index == -1) {
      throw StateError('Không tìm thấy căn hộ cần xóa.');
    }
    _apartments.removeAt(index);
  }

  @override
  Future<ApartmentModel> updateStatus(
    String apartmentId,
    ApartmentStatus status,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _apartments.indexWhere(
      (apartment) => apartment.id == apartmentId,
    );
    if (index == -1) {
      throw StateError('Không tìm thấy căn hộ cần cập nhật.');
    }

    final updated = ApartmentModel.fromEntity(
      _apartments[index].copyWith(status: status),
    );
    _apartments[index] = updated;
    return updated;
  }

  void _ensureUniqueCode(String code, {String? excludingId}) {
    final duplicated = _apartments.any(
      (item) =>
          item.id != excludingId && item.code.trim().toUpperCase() == code,
    );
    if (duplicated) {
      throw StateError('Mã căn hộ $code đã tồn tại.');
    }
  }
}
