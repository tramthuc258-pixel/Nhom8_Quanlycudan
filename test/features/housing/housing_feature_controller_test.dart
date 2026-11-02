import 'package:flutter_test/flutter_test.dart';
import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/features/apartments/services/apartment_mock_data_source.dart';
import 'package:homie/features/apartments/services/apartment_repository_impl.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/housing/services/housing_mock_data_source.dart';
import 'package:homie/features/housing/services/housing_repository_impl.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/residents/services/resident_mock_data_source.dart';
import 'package:homie/features/residents/services/resident_repository_impl.dart';

void main() {
  final referenceTime = DateTime(2026, 10, 16, 9);
  const manager = User(
    id: 'manager-001',
    fullName: 'Ban quản lý Homie',
    email: 'nam.management@homie.com',
    role: UserRole.manager,
  );
  const owner = User(
    id: 'resident-owner-initial',
    fullName: 'Đặng Thu Trang',
    email: 'trang.owner@homie.com',
    role: UserRole.resident,
    apartmentCode: 'D-0602',
  );

  late ApartmentMembershipController apartmentMembershipController;
  late HousingController controller;

  setUp(() async {
    apartmentMembershipController = ApartmentMembershipController(
      apartmentRepository: ApartmentRepositoryImpl(ApartmentMockDataSource()),
      residentRepository: ResidentRepositoryImpl(ResidentMockDataSource()),
    );
    controller = HousingController(
      repository: HousingRepositoryImpl(
        HousingMockDataSource(referenceTime: referenceTime),
      ),
      apartmentMembershipController: apartmentMembershipController,
    );
    await controller.load();
  });

  tearDown(() {
    controller.dispose();
    apartmentMembershipController.dispose();
  });

  test('tải và lọc tin đăng theo loại, trạng thái, từ khóa', () {
    expect(controller.allListings, hasLength(4));
    expect(controller.availableListings, hasLength(3));

    controller.setTransactionTypeFilter(HousingTransactionType.purchase);
    controller.setListingStatusFilter(HousingListingStatus.available);

    expect(controller.listings, hasLength(1));
    expect(controller.listings.single.id, 'housing-listing-purchase-001');

    controller.clearListingFilters();
    controller.setSearchQuery('A-1002');
    expect(controller.listings.single.id, 'housing-listing-rent-001');
  });

  test(
    'người dùng mới nộp hồ sơ và không thể nộp trùng khi đang chờ',
    () async {
      const applicant = User(
        id: 'user-new-001',
        fullName: 'Trần Thị Bình',
        email: 'tranthibinh@example.com',
        role: UserRole.resident,
      );

      final firstResult = await controller.submitApplication(
        listingId: 'housing-listing-rent-002',
        applicant: applicant,
        phone: '0908888888',
        preferredStartDate: DateTime(2026, 10, 20),
        preferredEndDate: DateTime(2027, 10, 19),
        note: 'Mong muốn thuê trong một năm.',
      );
      final duplicateResult = await controller.submitApplication(
        listingId: 'housing-listing-rent-002',
        applicant: applicant,
        phone: '0908888888',
        preferredStartDate: DateTime(2026, 10, 20),
        preferredEndDate: DateTime(2027, 10, 19),
      );

      expect(firstResult, isTrue);
      expect(controller.applicationsForApplicant(applicant.id), hasLength(1));
      expect(duplicateResult, isFalse);
      expect(controller.errorMessage, contains('đang chờ duyệt'));
    },
  );

  test('không cho nộp hồ sơ vào tin đăng đã đóng', () async {
    const applicant = User(
      id: 'user-new-002',
      fullName: 'Nguyễn Thanh Tâm',
      email: 'thanhtam@example.com',
      role: UserRole.resident,
    );

    final result = await controller.submitApplication(
      listingId: 'housing-listing-closed-001',
      applicant: applicant,
      phone: '0911222333',
      preferredStartDate: DateTime(2026, 12, 1),
    );

    expect(result, isFalse);
    expect(controller.errorMessage, contains('không còn nhận hồ sơ'));
  });

  test('ghi nhận hợp đồng thuê sẽ thêm người thuê và đóng bài', () async {
    final ownerBefore = apartmentMembershipController
        .membershipsForApartment('apartment-002', includeEnded: false)
        .singleWhere((membership) => membership.type == MembershipType.owner);

    final result = await controller.completeApplication(
      applicationId: 'housing-application-001',
      reviewer: manager,
      contractNumber: 'HD-THUE-001',
      contractSignedAt: DateTime(2026, 10, 18),
      effectiveDate: DateTime(2026, 11, 1),
      note: 'Đã kiểm tra hợp đồng thuê.',
    );

    final activeMemberships = apartmentMembershipController
        .membershipsForApartment('apartment-002', includeEnded: false);
    expect(result, isTrue);
    expect(
      activeMemberships.any(
        (membership) =>
            membership.id == ownerBefore.id &&
            membership.type == MembershipType.owner,
      ),
      isTrue,
    );
    expect(
      activeMemberships.any(
        (membership) =>
            membership.residentId == 'user-applicant-001' &&
            membership.type == MembershipType.tenant,
      ),
      isTrue,
    );
    final application = controller.applicationById('housing-application-001');
    expect(application?.status, HousingApplicationStatus.completed);
    expect(application?.contractNumber, 'HD-THUE-001');
    expect(application?.contractSignedAt, DateTime(2026, 10, 18));
    expect(application?.effectiveDate, DateTime(2026, 11, 1));
    expect(
      controller.listingById('housing-listing-rent-001')?.status,
      HousingListingStatus.closed,
    );
  });

  test('ghi nhận hợp đồng mua sẽ chuyển quyền sở hữu và đóng bài', () async {
    final oldOwner = apartmentMembershipController
        .membershipsForApartment('apartment-004', includeEnded: false)
        .singleWhere((membership) => membership.type == MembershipType.owner);

    final result = await controller.completeApplication(
      applicationId: 'housing-application-002',
      reviewer: manager,
      contractNumber: 'HD-MUA-001',
      contractSignedAt: DateTime(2026, 10, 18),
      effectiveDate: DateTime(2026, 12, 1),
      note: 'Hai bên đã ký hợp đồng chuyển nhượng.',
    );

    final allMemberships = apartmentMembershipController
        .membershipsForApartment('apartment-004');
    final activeOwners = allMemberships
        .where(
          (membership) =>
              membership.type == MembershipType.owner &&
              membership.status == MembershipStatus.active,
        )
        .toList();
    final endedOldOwner = allMemberships.singleWhere(
      (membership) => membership.id == oldOwner.id,
    );

    expect(result, isTrue);
    expect(endedOldOwner.status, MembershipStatus.ended);
    expect(activeOwners, hasLength(1));
    expect(activeOwners.single.residentId, 'user-applicant-002');
    final application = controller.applicationById('housing-application-002');
    expect(application?.status, HousingApplicationStatus.completed);
    expect(application?.contractNumber, 'HD-MUA-001');
    expect(application?.effectiveDate, DateTime(2026, 12, 1));
    expect(
      controller.listingById('housing-listing-purchase-001')?.status,
      HousingListingStatus.closed,
    );
  });

  test('chủ sở hữu gửi bài và ban quản lý duyệt trước khi công khai', () async {
    final eligible = controller.apartmentsEligibleForListing(owner);
    expect(eligible.map((item) => item.code), contains('D-0602'));

    final submitted = await controller.createListing(
      actor: owner,
      apartmentId: 'apartment-006',
      title: 'Cho thuê căn hộ D-0602',
      description: 'Căn hộ hai phòng ngủ, bàn giao nội thất cơ bản.',
      transactionType: HousingTransactionType.rent,
      price: 14500000,
      deposit: 29000000,
      availableFrom: DateTime(2026, 11, 1),
    );

    expect(submitted, isTrue);
    final listing = controller.listingsSubmittedBy(owner.id).single;
    expect(listing.status, HousingListingStatus.pendingApproval);
    expect(listing.ownerSubmitted, isTrue);
    expect(controller.publicListings, isNot(contains(listing)));

    final approved = await controller.approveListing(
      listingId: listing.id,
      reviewer: manager,
    );
    expect(approved, isTrue);
    expect(
      controller.listingById(listing.id)?.status,
      HousingListingStatus.available,
    );
    expect(
      controller.publicListings.map((item) => item.id),
      contains(listing.id),
    );
  });

  test('từ chối hồ sơ không tạo hoặc thay đổi quan hệ cư trú', () async {
    final membershipCountBefore =
        apartmentMembershipController.memberships.length;

    final result = await controller.rejectApplication(
      applicationId: 'housing-application-001',
      reviewer: manager,
      reason: 'Chưa đáp ứng điều kiện hồ sơ thuê.',
    );

    expect(result, isTrue);
    expect(
      controller.applicationById('housing-application-001')?.status,
      HousingApplicationStatus.rejected,
    );
    expect(
      apartmentMembershipController.memberships,
      hasLength(membershipCountBefore),
    );
    expect(
      controller.listingById('housing-listing-rent-001')?.status,
      HousingListingStatus.available,
    );
  });
}
