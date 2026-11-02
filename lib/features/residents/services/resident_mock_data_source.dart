import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/residents/models/residence_verification.dart';

import '../models/apartment_membership_model.dart';
import '../models/household_member.dart';
import '../models/household_member_model.dart';
import '../models/resident_model.dart';
import 'resident_data_source.dart';

class ResidentMockDataSource implements ResidentDataSource {
  final List<ResidentModel> _residents = <ResidentModel>[
    const ResidentModel(
      id: 'resident-owner-001',
      fullName: 'Nguyễn Văn An',
      phone: '0901234567',
      email: 'an.owner@homie.com',
    ),
    const ResidentModel(
      id: 'resident-001',
      fullName: 'Nguyễn Minh Anh',
      phone: '0912345678',
      email: 'anh.resident@homie.com',
    ),
    const ResidentModel(
      id: 'resident-002',
      fullName: 'Lê Gia Hân',
      phone: '0988123456',
      email: 'han.resident@homie.com',
    ),
    const ResidentModel(
      id: 'resident-003',
      fullName: 'Phạm Quốc Bảo',
      phone: '0903456789',
      email: 'bao.resident@homie.com',
    ),
    const ResidentModel(
      id: 'resident-004',
      fullName: 'Trần Thu Hà',
      phone: '0934567890',
      email: 'ha.resident@homie.com',
    ),
    const ResidentModel(
      id: 'resident-005',
      fullName: 'Đỗ Hoàng Long',
      phone: '0977654321',
      email: 'long.resident@homie.com',
    ),
    const ResidentModel(
      id: 'resident-006',
      fullName: 'Vũ Ngọc Mai',
      phone: '0966543210',
      email: 'mai.resident@homie.com',
    ),
    const ResidentModel(
      id: 'resident-owner-initial',
      fullName: 'Đặng Thu Trang',
      phone: '0906777888',
      email: 'trang.owner@homie.com',
    ),
  ];

  final List<ApartmentMembershipModel> _memberships =
      <ApartmentMembershipModel>[
        ApartmentMembershipModel(
          id: 'membership-001',
          apartmentId: 'apartment-001',
          residentId: 'resident-owner-001',
          type: MembershipType.owner,
          startDate: DateTime(2022, 3, 15),
          status: MembershipStatus.active,
          isPrimary: true,
        ),
        ApartmentMembershipModel(
          id: 'membership-002',
          apartmentId: 'apartment-001',
          residentId: 'resident-001',
          type: MembershipType.tenant,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2027, 12, 31),
          status: MembershipStatus.active,
          isPrimary: true,
        ),
        ApartmentMembershipModel(
          id: 'membership-004',
          apartmentId: 'apartment-002',
          residentId: 'resident-003',
          type: MembershipType.owner,
          startDate: DateTime(2021, 8, 20),
          status: MembershipStatus.active,
          isPrimary: true,
        ),
        ApartmentMembershipModel(
          id: 'membership-005',
          apartmentId: 'apartment-002',
          residentId: 'resident-004',
          type: MembershipType.tenant,
          startDate: DateTime(2025, 9, 1),
          endDate: DateTime(2026, 8, 31),
          status: MembershipStatus.ended,
          isPrimary: true,
        ),
        ApartmentMembershipModel(
          id: 'membership-006',
          apartmentId: 'apartment-004',
          residentId: 'resident-005',
          type: MembershipType.owner,
          startDate: DateTime(2023, 2, 10),
          status: MembershipStatus.active,
          isPrimary: true,
        ),
        ApartmentMembershipModel(
          id: 'membership-history-001',
          apartmentId: 'apartment-001',
          residentId: 'resident-004',
          type: MembershipType.tenant,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2025, 12, 15),
          status: MembershipStatus.ended,
        ),
        ApartmentMembershipModel(
          id: 'membership-owner-initial',
          apartmentId: 'apartment-006',
          residentId: 'resident-owner-initial',
          type: MembershipType.owner,
          startDate: DateTime(2024, 6, 1),
          status: MembershipStatus.active,
          isPrimary: true,
        ),
      ];

  final List<HouseholdMemberModel> _householdMembers = <HouseholdMemberModel>[
    HouseholdMemberModel(
      id: 'household-member-001',
      apartmentId: 'apartment-001',
      createdById: 'resident-001',
      fullName: 'Lê Gia Hân',
      relationship: 'Em gái',
      startDate: DateTime(2026, 1, 1),
      status: HouseholdMemberStatus.active,
      phone: '0988123456',
    ),
    HouseholdMemberModel(
      id: 'household-member-002',
      apartmentId: 'apartment-004',
      createdById: 'resident-005',
      fullName: 'Vũ Ngọc Mai',
      relationship: 'Con',
      startDate: DateTime(2023, 2, 10),
      status: HouseholdMemberStatus.active,
    ),
  ];

  int _nextResidentNumber = 100;
  int _nextMembershipNumber = 100;
  int _nextHouseholdMemberNumber = 100;
  ResidenceVerification _myVerification = const ResidenceVerification(
    state: ResidenceVerificationState.notSubmitted,
  );
  final List<ResidenceVerification> _verificationRequests = [];

  @override
  Future<List<ResidentModel>> getResidents() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<ResidentModel>.unmodifiable(_residents);
  }

  @override
  Future<List<ApartmentMembershipModel>> getMemberships() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<ApartmentMembershipModel>.unmodifiable(_memberships);
  }

  @override
  Future<List<HouseholdMemberModel>> getHouseholdMembers() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<HouseholdMemberModel>.unmodifiable(_householdMembers);
  }

  @override
  Future<ResidenceVerification> getMyResidenceVerification() async {
    return _myVerification;
  }

  @override
  Future<List<Apartment>> getResidenceVerificationApartments() async {
    return const [
      Apartment(
        id: 'apartment-001',
        code: 'A-1205',
        buildingName: 'Tòa A',
        floor: 12,
        area: 72,
        bedrooms: 2,
        status: ApartmentStatus.occupied,
      ),
      Apartment(
        id: 'apartment-003',
        code: 'B-0802',
        buildingName: 'Tòa B',
        floor: 8,
        area: 65,
        bedrooms: 2,
        status: ApartmentStatus.vacant,
      ),
    ];
  }

  @override
  Future<List<ResidenceVerification>>
  getResidenceVerificationRequests() async =>
      List.unmodifiable(_verificationRequests);

  @override
  Future<ResidenceVerification> createResidenceVerification({
    required String apartmentId,
    required MembershipType type,
    required DateTime startDate,
    required String contactPhone,
    String? note,
  }) async {
    final request = ResidenceVerification(
      state: ResidenceVerificationState.pending,
      id: 'verification-${_verificationRequests.length + 1}',
      userId: 'mock-current-user',
      apartmentId: apartmentId,
      apartmentCode: apartmentId == 'apartment-001' ? 'A-1205' : 'B-0802',
      buildingName: apartmentId == 'apartment-001' ? 'Tòa A' : 'Tòa B',
      fullName: 'Tài khoản hiện tại',
      email: 'anh.resident@homie.com',
      phone: contactPhone.trim(),
      type: type,
      startDate: startDate,
      note: note,
      createdAt: DateTime.now(),
    );
    _myVerification = request;
    _verificationRequests.insert(0, request);
    return request;
  }

  @override
  Future<ResidenceVerification> reviewResidenceVerification({
    required String requestId,
    required bool approve,
    String? verificationBasis,
    String? reviewNote,
  }) async {
    final index = _verificationRequests.indexWhere(
      (item) => item.id == requestId,
    );
    if (index < 0) throw StateError('Không tìm thấy yêu cầu xác minh.');
    final current = _verificationRequests[index];
    final reviewed = ResidenceVerification(
      state: approve
          ? ResidenceVerificationState.approved
          : ResidenceVerificationState.rejected,
      id: current.id,
      userId: current.userId,
      apartmentId: current.apartmentId,
      apartmentCode: current.apartmentCode,
      buildingName: current.buildingName,
      fullName: current.fullName,
      email: current.email,
      phone: current.phone,
      type: current.type,
      startDate: current.startDate,
      verificationBasis: verificationBasis,
      note: current.note,
      reviewNote: reviewNote,
      createdAt: current.createdAt,
    );
    _verificationRequests[index] = reviewed;
    if (_myVerification.id == requestId) _myVerification = reviewed;
    return reviewed;
  }

  @override
  Future<ApartmentMembershipModel> addMembership({
    String? residentId,
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    if (endDate != null && endDate.isBefore(startDate)) {
      throw ArgumentError('Ngày kết thúc phải sau ngày bắt đầu.');
    }

    if ((type == MembershipType.owner || type == MembershipType.tenant) &&
        _memberships.any(
          (membership) =>
              membership.apartmentId == apartmentId &&
              membership.type == type &&
              membership.status == MembershipStatus.active,
        )) {
      throw StateError(
        type == MembershipType.owner
            ? 'Căn hộ đã có một chủ sở hữu đang hiệu lực.'
            : 'Căn hộ đã có một người thuê đại diện đang hiệu lực.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _normalizePhone(phone);
    ResidentModel? resident;
    for (final candidate in _residents) {
      if (candidate.email.toLowerCase() == normalizedEmail ||
          _normalizePhone(candidate.phone) == normalizedPhone) {
        resident = candidate;
        break;
      }
    }

    if (resident == null) {
      final normalizedResidentId = residentId?.trim();
      if (normalizedResidentId != null && normalizedResidentId.isNotEmpty) {
        final idAlreadyExists = _residents.any(
          (candidate) => candidate.id == normalizedResidentId,
        );
        if (idAlreadyExists) {
          throw StateError('Mã cư dân đã được sử dụng bởi tài khoản khác.');
        }
      }
      resident = ResidentModel(
        id: normalizedResidentId == null || normalizedResidentId.isEmpty
            ? 'resident-${_nextResidentNumber++}'
            : normalizedResidentId,
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: normalizedEmail,
      );
    }
    if (!_residents.contains(resident)) {
      _residents.add(resident);
    }

    final effectiveResidentId = resident.id;
    final alreadyActive = _memberships.any(
      (membership) =>
          membership.apartmentId == apartmentId &&
          membership.residentId == effectiveResidentId &&
          membership.status == MembershipStatus.active,
    );
    if (alreadyActive) {
      throw StateError('$fullName đã có quan hệ đang hiệu lực với căn hộ.');
    }

    final membership = ApartmentMembershipModel(
      id: 'membership-${_nextMembershipNumber++}',
      apartmentId: apartmentId,
      residentId: effectiveResidentId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      status: MembershipStatus.active,
      isPrimary: true,
    );
    _memberships.add(membership);
    return membership;
  }

  @override
  Future<ApartmentMembershipModel> endMembership(String membershipId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final index = _memberships.indexWhere(
      (membership) => membership.id == membershipId,
    );
    if (index == -1) {
      throw StateError('Không tìm thấy quan hệ cư trú cần kết thúc.');
    }

    final current = _memberships[index];
    if (current.status == MembershipStatus.ended) {
      return current;
    }

    final ended = ApartmentMembershipModel.fromEntity(
      current.copyWith(endDate: DateTime.now(), status: MembershipStatus.ended),
    );
    _memberships[index] = ended;
    return ended;
  }

  @override
  Future<HouseholdMemberModel> addHouseholdMember({
    required String apartmentId,
    required String fullName,
    DateTime? dateOfBirth,
    required String phone,
    required String relationship,
    required DateTime startDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final duplicated = _householdMembers.any(
      (member) =>
          member.apartmentId == apartmentId &&
          member.isActive &&
          member.fullName.toLowerCase() == fullName.trim().toLowerCase() &&
          member.dateOfBirth == dateOfBirth,
    );
    if (duplicated) {
      throw StateError('Thành viên này đã có trong danh sách cư trú.');
    }
    final member = HouseholdMemberModel(
      id: 'household-member-${_nextHouseholdMemberNumber++}',
      apartmentId: apartmentId,
      createdById: 'mock-current-user',
      fullName: fullName.trim(),
      dateOfBirth: dateOfBirth,
      phone: phone.trim(),
      relationship: relationship.trim(),
      startDate: startDate,
      status: HouseholdMemberStatus.active,
    );
    _householdMembers.add(member);
    return member;
  }

  @override
  Future<HouseholdMemberModel> endHouseholdMember(String memberId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final index = _householdMembers.indexWhere(
      (member) => member.id == memberId,
    );
    if (index == -1) throw StateError('Không tìm thấy thành viên trong hộ.');
    final current = _householdMembers[index];
    if (!current.isActive) return current;
    final ended = HouseholdMemberModel(
      id: current.id,
      apartmentId: current.apartmentId,
      createdById: current.createdById,
      fullName: current.fullName,
      dateOfBirth: current.dateOfBirth,
      phone: current.phone,
      relationship: current.relationship,
      startDate: current.startDate,
      endDate: DateTime.now(),
      status: HouseholdMemberStatus.ended,
    );
    _householdMembers[index] = ended;
    return ended;
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
