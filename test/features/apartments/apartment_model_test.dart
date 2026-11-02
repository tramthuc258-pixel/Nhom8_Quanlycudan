import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/apartments/models/apartment_model.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';

void main() {
  test('đọc được trạng thái bảo trì từ API ở cả camelCase và snake_case', () {
    Map<String, Object?> apartment(String status) => <String, Object?>{
      'id': 'apartment-1',
      'code': 'A-0101',
      'buildingName': 'Tòa A',
      'floor': 1,
      'area': 68.5,
      'bedrooms': 2,
      'status': status,
    };

    expect(
      ApartmentModel.fromMap(apartment('underMaintenance')).status,
      ApartmentStatus.underMaintenance,
    );
    expect(
      ApartmentModel.fromMap(apartment('under_maintenance')).status,
      ApartmentStatus.underMaintenance,
    );
  });
}
