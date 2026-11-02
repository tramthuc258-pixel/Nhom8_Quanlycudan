import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/apartments/services/apartment_mock_data_source.dart';
import 'package:homie/features/apartments/services/apartment_repository_impl.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/residents/services/resident_mock_data_source.dart';
import 'package:homie/features/residents/services/resident_repository_impl.dart';

void main() {
  late ApartmentMembershipController controller;

  setUp(() {
    controller = ApartmentMembershipController(
      apartmentRepository: ApartmentRepositoryImpl(ApartmentMockDataSource()),
      residentRepository: ResidentRepositoryImpl(ResidentMockDataSource()),
    );
  });

  tearDown(() => controller.dispose());

  test('chọn căn chung cho tài khoản và bỏ qua căn đã hết hiệu lực', () async {
    await controller.load();
    final owner = controller.residents.singleWhere(
      (item) => item.email == 'an.owner@homie.com',
    );
    final originalApartmentId = controller
        .activeMembershipForResident(owner.id)!
        .apartmentId;
    final otherApartment = controller.apartments.singleWhere(
      (item) => item.status == ApartmentStatus.vacant,
    );
    expect(
      await controller.addMembership(
        residentId: owner.id,
        apartmentId: otherApartment.id,
        fullName: owner.fullName,
        phone: owner.phone,
        email: owner.email,
        type: MembershipType.owner,
        startDate: DateTime(2026, 10, 1),
      ),
      isTrue,
    );

    expect(controller.activeMembershipsForResident(owner.id), hasLength(2));
    expect(
      controller.selectApartmentForResident(owner.id, otherApartment.id),
      isTrue,
    );
    expect(
      controller.activeMembershipForResident(owner.id)?.apartmentId,
      otherApartment.id,
    );
    expect(
      controller.selectApartmentForResident('resident-001', otherApartment.id),
      isFalse,
    );

    final selectedMembership = controller.memberships.singleWhere(
      (item) =>
          item.residentId == owner.id && item.apartmentId == otherApartment.id,
    );
    expect(await controller.endMembership(selectedMembership.id), isTrue);
    expect(
      controller.activeMembershipForResident(owner.id)?.apartmentId,
      originalApartmentId,
    );
  });

  test('A-1205 có chủ sở hữu và người thuê là hai người khác nhau', () async {
    await controller.load();

    final apartment = controller.apartments.singleWhere(
      (item) => item.code == 'A-1205',
    );
    final activeMemberships = controller.membershipsForApartment(
      apartment.id,
      includeEnded: false,
    );
    final owner = activeMemberships.singleWhere(
      (membership) => membership.type == MembershipType.owner,
    );
    final tenant = activeMemberships.singleWhere(
      (membership) => membership.type == MembershipType.tenant,
    );

    expect(owner.residentId, isNot(tenant.residentId));
    expect(
      controller.residentById(owner.residentId)?.fullName,
      'Nguyễn Văn An',
    );
    expect(
      controller.residentById(tenant.residentId)?.fullName,
      'Nguyễn Minh Anh',
    );
  });

  test('không cho thêm chủ sở hữu thứ hai đang hiệu lực', () async {
    await controller.load();
    final apartment = controller.apartments.singleWhere(
      (item) => item.code == 'A-1205',
    );

    final success = await controller.addMembership(
      apartmentId: apartment.id,
      fullName: 'Chủ sở hữu thứ hai',
      phone: '0909999999',
      email: 'owner2@homie.com',
      type: MembershipType.owner,
      startDate: DateTime(2026, 10, 16),
    );

    expect(success, isFalse);
    expect(controller.errorMessage, contains('đã có một chủ sở hữu'));
  });

  test('không cho thêm người thuê đại diện thứ hai đang hiệu lực', () async {
    await controller.load();
    final apartment = controller.apartments.singleWhere(
      (item) => item.code == 'A-1205',
    );

    final success = await controller.addMembership(
      apartmentId: apartment.id,
      fullName: 'Người thuê thứ hai',
      phone: '0909999998',
      email: 'tenant2@homie.com',
      type: MembershipType.tenant,
      startDate: DateTime(2026, 10, 27),
    );

    expect(success, isFalse);
    expect(controller.errorMessage, contains('người thuê đại diện'));
  });

  test('thành viên trong hộ không tạo thêm tài khoản đăng nhập', () async {
    await controller.load();
    final apartment = controller.apartments.singleWhere(
      (item) => item.code == 'A-1205',
    );
    final accountCount = controller.residents.length;

    final success = await controller.addHouseholdMember(
      apartmentId: apartment.id,
      fullName: 'Nguyễn Gia Bảo',
      dateOfBirth: DateTime(2015, 8, 20),
      phone: '',
      relationship: 'Con',
      startDate: DateTime(2026, 10, 27),
    );

    expect(success, isTrue);
    expect(controller.residents.length, accountCount);
    final member = controller
        .householdMembersForApartment(apartment.id)
        .singleWhere((item) => item.fullName == 'Nguyễn Gia Bảo');
    expect(member.relationship, 'Con');
    expect(member.phone, isEmpty);
  });

  test('thêm người thuê làm căn hộ trống chuyển sang đang sử dụng', () async {
    await controller.load();
    final apartment = controller.apartments.singleWhere(
      (item) => item.status == ApartmentStatus.vacant,
    );

    final success = await controller.addMembership(
      apartmentId: apartment.id,
      fullName: 'Trần Thị Bình',
      phone: '0908888888',
      email: 'binh.tenant@homie.com',
      type: MembershipType.tenant,
      startDate: DateTime(2026, 10, 16),
      endDate: DateTime(2027, 10, 15),
    );

    expect(success, isTrue);
    expect(
      controller.apartmentById(apartment.id)?.status,
      ApartmentStatus.occupied,
    );
    expect(
      controller
          .membershipsForApartment(apartment.id, includeEnded: false)
          .any((membership) => membership.type == MembershipType.tenant),
      isTrue,
    );
  });

  test('dùng mã tài khoản làm mã cư dân khi tạo hồ sơ mới', () async {
    await controller.load();
    final apartment = controller.apartments.singleWhere(
      (item) => item.status == ApartmentStatus.vacant,
    );

    final success = await controller.addMembership(
      residentId: 'user-applicant-101',
      apartmentId: apartment.id,
      fullName: 'Người đăng ký mới',
      phone: '0907777777',
      email: 'applicant101@homie.com',
      type: MembershipType.tenant,
      startDate: DateTime(2026, 10, 16),
    );

    expect(success, isTrue);
    expect(
      controller.residentById('user-applicant-101')?.email,
      'applicant101@homie.com',
    );
  });

  test(
    'ưu tiên cư dân cũ trùng email thay vì mã tài khoản truyền vào',
    () async {
      await controller.load();
      final apartment = controller.apartments.singleWhere(
        (item) => item.status == ApartmentStatus.vacant,
      );

      final success = await controller.addMembership(
        residentId: 'user-alias-001',
        apartmentId: apartment.id,
        fullName: 'Nguyễn Minh Anh',
        phone: '0912345678',
        email: 'anh.resident@homie.com',
        type: MembershipType.tenant,
        startDate: DateTime(2026, 10, 16),
      );

      expect(success, isTrue);
      expect(controller.residentById('user-alias-001'), isNull);
      expect(
        controller
            .membershipsForApartment(apartment.id, includeEnded: false)
            .single
            .residentId,
        'resident-001',
      );
    },
  );

  test('kết thúc quan hệ vẫn giữ bản ghi lịch sử', () async {
    await controller.load();
    final membership = controller.memberships.singleWhere(
      (item) =>
          item.residentId == 'resident-001' &&
          item.type == MembershipType.tenant,
    );

    final success = await controller.endMembership(membership.id);

    expect(success, isTrue);
    final endedMembership = controller.memberships.singleWhere(
      (item) => item.id == membership.id,
    );
    expect(endedMembership.status, MembershipStatus.ended);
    expect(endedMembership.endDate, isNotNull);
    expect(
      controller
          .membershipsForApartment(membership.apartmentId, includeEnded: false)
          .any((item) => item.id == membership.id),
      isFalse,
    );
    expect(
      controller
          .membershipsForApartment(membership.apartmentId)
          .any((item) => item.id == membership.id),
      isTrue,
    );
  });

  test('thêm căn hộ mới và chuẩn hóa mã căn hộ', () async {
    await controller.load();

    final success = await controller.createApartment(
      code: ' d-0201 ',
      buildingName: ' Tòa D ',
      floor: 2,
      area: 76.5,
      bedrooms: 2,
      status: ApartmentStatus.vacant,
    );

    expect(success, isTrue);
    final apartment = controller.apartments.singleWhere(
      (item) => item.code == 'D-0201',
    );
    expect(apartment.buildingName, 'Tòa D');
    expect(apartment.floor, 2);
    expect(apartment.area, 76.5);
  });

  test('không cho tạo hai căn hộ trùng mã', () async {
    await controller.load();

    final success = await controller.createApartment(
      code: 'a-1205',
      buildingName: 'Tòa khác',
      floor: 3,
      area: 60,
      bedrooms: 2,
      status: ApartmentStatus.vacant,
    );

    expect(success, isFalse);
    expect(controller.errorMessage, contains('đã tồn tại'));
  });

  test('cập nhật thông tin căn hộ chưa có cư dân', () async {
    await controller.load();
    final apartment = controller.apartments.singleWhere(
      (item) => item.code == 'B-0803',
    );

    final success = await controller.updateApartment(
      apartmentId: apartment.id,
      code: 'B-0803A',
      buildingName: 'Tòa B mở rộng',
      floor: 8,
      area: 62,
      bedrooms: 3,
      status: ApartmentStatus.underMaintenance,
    );

    expect(success, isTrue);
    final updated = controller.apartmentById(apartment.id)!;
    expect(updated.code, 'B-0803A');
    expect(updated.bedrooms, 3);
    expect(updated.status, ApartmentStatus.underMaintenance);
  });

  test('chỉ xóa căn hộ chưa có lịch sử cư trú', () async {
    await controller.load();
    final occupied = controller.apartments.singleWhere(
      (item) => item.code == 'A-1205',
    );

    final rejected = await controller.deleteApartment(occupied.id);
    expect(rejected, isFalse);
    expect(controller.errorMessage, contains('lịch sử cư trú'));

    final created = await controller.createApartment(
      code: 'E-0101',
      buildingName: 'Tòa E',
      floor: 1,
      area: 55,
      bedrooms: 1,
      status: ApartmentStatus.vacant,
    );
    expect(created, isTrue);
    final emptyApartment = controller.apartments.singleWhere(
      (item) => item.code == 'E-0101',
    );

    final deleted = await controller.deleteApartment(emptyApartment.id);
    expect(deleted, isTrue);
    expect(controller.apartmentById(emptyApartment.id), isNull);
  });
}
