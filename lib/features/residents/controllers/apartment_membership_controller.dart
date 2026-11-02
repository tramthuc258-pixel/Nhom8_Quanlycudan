import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/resident.dart';
import 'package:homie/features/residents/models/household_member.dart';
import 'package:homie/features/residents/models/residence_verification.dart';
import 'package:homie/features/residents/services/resident_repository.dart';
import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/services/apartment_repository.dart';

class ApartmentMembershipController extends ChangeNotifier {
  ApartmentMembershipController({
    required this.apartmentRepository,
    required this.residentRepository,
    this.persistSelection = true,
  });

  final ApartmentRepository apartmentRepository;
  final ResidentRepository residentRepository;
  final bool persistSelection;
  final FlutterSecureStorage _selectionStorage = const FlutterSecureStorage();
  final Map<String, String> _selectedApartmentIds = <String, String>{};
  final Set<String> _restoredResidentIds = <String>{};

  bool _isLoading = false;
  String? _errorMessage;
  List<Apartment> _apartments = const <Apartment>[];
  List<Resident> _residents = const <Resident>[];
  List<ApartmentMembership> _memberships = const <ApartmentMembership>[];
  List<HouseholdMember> _householdMembers = const <HouseholdMember>[];
  List<Apartment> _verificationApartments = const <Apartment>[];
  ResidenceVerification _myVerification = const ResidenceVerification(
    state: ResidenceVerificationState.notSubmitted,
  );
  List<ResidenceVerification> _verificationRequests =
      const <ResidenceVerification>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Apartment> get apartments => _apartments;
  List<Resident> get residents => _residents;
  List<ApartmentMembership> get memberships => _memberships;
  List<HouseholdMember> get householdMembers => _householdMembers;
  List<Apartment> get verificationApartments => _verificationApartments;
  ResidenceVerification get myVerification => _myVerification;
  List<ResidenceVerification> get verificationRequests => _verificationRequests;

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _refreshData();
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Apartment? apartmentById(String id) {
    for (final apartment in _apartments) {
      if (apartment.id == id) return apartment;
    }
    return null;
  }

  Resident? residentById(String id) {
    for (final resident in _residents) {
      if (resident.id == id) return resident;
    }
    return null;
  }

  List<ApartmentMembership> membershipsForApartment(
    String id, {
    bool includeEnded = true,
  }) {
    final result = _memberships.where((membership) {
      if (membership.apartmentId != id) return false;
      return includeEnded || membership.status == MembershipStatus.active;
    }).toList();

    result.sort((first, second) {
      final statusComparison = _statusPriority(first.status)
          .compareTo(_statusPriority(second.status));
      if (statusComparison != 0) return statusComparison;

      final typeComparison = _typePriority(first.type)
          .compareTo(_typePriority(second.type));
      if (typeComparison != 0) return typeComparison;

      return second.startDate.compareTo(first.startDate);
    });
    return List<ApartmentMembership>.unmodifiable(result);
  }

  List<HouseholdMember> householdMembersForApartment(
    String apartmentId, {
    bool includeEnded = false,
  }) {
    final result = _householdMembers.where((member) {
      if (member.apartmentId != apartmentId) return false;
      return includeEnded || member.isActive;
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
    return List<HouseholdMember>.unmodifiable(result);
  }

  List<ApartmentMembership> activeMembershipsForResident(String residentId) {
    final activeMemberships =
        _memberships
            .where(
              (membership) =>
                  membership.residentId == residentId && membership.isActive,
            )
            .toList()
          ..sort((first, second) {
            final typeComparison = _typePriority(first.type)
                .compareTo(_typePriority(second.type));
            if (typeComparison != 0) return typeComparison;
            return second.startDate.compareTo(first.startDate);
          });

    final seenApartmentIds = <String>{};
    return List<ApartmentMembership>.unmodifiable(
      activeMemberships.where(
        (membership) => seenApartmentIds.add(membership.apartmentId),
      ),
    );
  }

  String? selectedApartmentIdForResident(String residentId) =>
      _selectedApartmentIds[residentId];

  Future<void> restoreApartmentForResident(String residentId) async {
    if (!_restoredResidentIds.add(residentId)) return;
    if (!persistSelection) return;
    try {
      final saved = await _selectionStorage.read(
        key: 'homie_selected_apartment_$residentId',
      );
      if (saved != null && !_selectedApartmentIds.containsKey(residentId)) {
        _selectedApartmentIds[residentId] = saved;
        notifyListeners();
      }
    } catch (_) {
      // Vẫn có thể chọn căn trong phiên này nếu thiết bị không hỗ trợ lưu trữ.
    }
  }

  bool selectApartmentForResident(String residentId, String apartmentId) {
    final canSelect = activeMembershipsForResident(residentId)
        .any((membership) => membership.apartmentId == apartmentId);
    if (!canSelect) return false;
    _selectedApartmentIds[residentId] = apartmentId;
    notifyListeners();
    if (persistSelection) {
      unawaited(_saveApartmentSelection(residentId, apartmentId));
    }
    return true;
  }

  Future<void> _saveApartmentSelection(
    String residentId,
    String apartmentId,
  ) async {
    try {
      await _selectionStorage.write(
        key: 'homie_selected_apartment_$residentId',
        value: apartmentId,
      );
    } catch (_) {
      // Lựa chọn trong bộ nhớ vẫn có hiệu lực.
    }
  }

  ApartmentMembership? activeMembershipForResident(String residentId) {
    final activeMemberships = activeMembershipsForResident(residentId);
    final selectedId = _selectedApartmentIds[residentId];
    if (selectedId != null) {
      for (final membership in activeMemberships) {
        if (membership.apartmentId == selectedId) return membership;
      }
    }
    return activeMemberships.isEmpty ? null : activeMemberships.first;
  }

  Future<bool> createApartment({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _validateApartmentInput(
        code: code,
        buildingName: buildingName,
        floor: floor,
        area: area,
        bedrooms: bedrooms,
      );
      await apartmentRepository.createApartment(
        code: code.trim(),
        buildingName: buildingName.trim(),
        floor: floor,
        area: area,
        bedrooms: bedrooms,
        status: status,
      );
      await _refreshData();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateApartment({
    required String apartmentId,
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    required ApartmentStatus status,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final current = apartmentById(apartmentId);
      if (current == null) {
        throw StateError('Không tìm thấy căn hộ cần cập nhật.');
      }
      _validateApartmentInput(
        code: code,
        buildingName: buildingName,
        floor: floor,
        area: area,
        bedrooms: bedrooms,
        excludingId: apartmentId,
      );
      final hasActiveResidents = _memberships.any(
        (item) => item.apartmentId == apartmentId && item.isActive,
      );
      if (hasActiveResidents && status != ApartmentStatus.occupied) {
        throw StateError(
          'Căn hộ còn cư dân đang hiệu lực nên phải giữ trạng thái đang có người ở.',
        );
      }

      await apartmentRepository.updateApartment(
        current.copyWith(
          code: code.trim(),
          buildingName: buildingName.trim(),
          floor: floor,
          area: area,
          bedrooms: bedrooms,
          status: status,
        ),
      );
      await _refreshData();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteApartment(String apartmentId) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apartment = apartmentById(apartmentId);
      if (apartment == null) {
        throw StateError('Không tìm thấy căn hộ cần xóa.');
      }
      if (_memberships.any((item) => item.apartmentId == apartmentId) ||
          _householdMembers.any((item) => item.apartmentId == apartmentId)) {
        throw StateError(
          'Không thể xóa căn hộ đã có cư dân hoặc lịch sử cư trú.',
        );
      }

      await apartmentRepository.deleteApartment(apartmentId);
      await _refreshData();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMembership({
    String? residentId,
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _validateMembershipInput(
        apartmentId: apartmentId,
        fullName: fullName,
        phone: phone,
        email: email,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      await residentRepository.addMembership(
        residentId: residentId,
        apartmentId: apartmentId,
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim().toLowerCase(),
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      final apartment = apartmentById(apartmentId);
      if (apartment?.status == ApartmentStatus.vacant) {
        await apartmentRepository.updateStatus(
          apartmentId,
          ApartmentStatus.occupied,
        );
      }

      await _refreshData();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> endMembership(String membershipId) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      ApartmentMembership? membership;
      for (final candidate in _memberships) {
        if (candidate.id == membershipId) {
          membership = candidate;
          break;
        }
      }
      if (membership == null) {
        throw StateError('Không tìm thấy quan hệ cư trú cần kết thúc.');
      }
      if (membership.status == MembershipStatus.ended) {
        throw StateError('Quan hệ cư trú này đã kết thúc trước đó.');
      }

      await residentRepository.endMembership(membershipId);
      await _refreshData();

      final hasActiveMembership = _memberships.any(
        (candidate) =>
            candidate.apartmentId == membership!.apartmentId &&
            candidate.status == MembershipStatus.active,
      );
      final apartment = apartmentById(membership.apartmentId);
      if (!hasActiveMembership &&
          apartment?.status == ApartmentStatus.occupied) {
        await apartmentRepository.updateStatus(
          membership.apartmentId,
          ApartmentStatus.vacant,
        );
        _apartments = List<Apartment>.unmodifiable(
          await apartmentRepository.getApartments(),
        );
      }
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHouseholdMember({
    required String apartmentId,
    required String fullName,
    DateTime? dateOfBirth,
    required String phone,
    required String relationship,
    required DateTime startDate,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (fullName.trim().length < 2 || relationship.trim().length < 2) {
        throw ArgumentError(
          'Vui lòng nhập họ tên và quan hệ với người đại diện.',
        );
      }
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.trim().isNotEmpty &&
          (digits.length < 8 || digits.length > 11)) {
        throw ArgumentError('Số điện thoại thành viên không hợp lệ.');
      }
      if (dateOfBirth != null && dateOfBirth.isAfter(DateTime.now())) {
        throw ArgumentError('Ngày sinh không được ở trong tương lai.');
      }
      await residentRepository.addHouseholdMember(
        apartmentId: apartmentId,
        fullName: fullName.trim(),
        dateOfBirth: dateOfBirth,
        phone: phone.trim(),
        relationship: relationship.trim(),
        startDate: startDate,
      );
      await _refreshData();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> endHouseholdMember(String memberId) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await residentRepository.endHouseholdMember(memberId);
      await _refreshData();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitResidenceVerification({
    required String apartmentId,
    required MembershipType type,
    required DateTime startDate,
    required String contactPhone,
    String? note,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _myVerification = await residentRepository.createResidenceVerification(
        apartmentId: apartmentId,
        type: type,
        startDate: startDate,
        contactPhone: contactPhone.trim(),
        note: note,
      );
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVerificationRequests() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _verificationRequests = List.unmodifiable(
        await residentRepository.getResidenceVerificationRequests(),
      );
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reviewResidenceVerification({
    required String requestId,
    required bool approve,
    String? verificationBasis,
    String? reviewNote,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await residentRepository.reviewResidenceVerification(
        requestId: requestId,
        approve: approve,
        verificationBasis: verificationBasis,
        reviewNote: reviewNote,
      );
      await _refreshData();
      _verificationRequests = List.unmodifiable(
        await residentRepository.getResidenceVerificationRequests(),
      );
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshData() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      apartmentRepository.getApartments(),
      residentRepository.getResidents(),
      residentRepository.getMemberships(),
      residentRepository.getHouseholdMembers(),
      residentRepository.getMyResidenceVerification(),
      residentRepository.getResidenceVerificationApartments(),
    ]);

    final apartments = List<Apartment>.from(results[0] as List<Apartment>)
      ..sort((first, second) => first.code.compareTo(second.code));
    final residents = List<Resident>.from(results[1] as List<Resident>)
      ..sort((first, second) => first.fullName.compareTo(second.fullName));

    _apartments = List<Apartment>.unmodifiable(apartments);
    _residents = List<Resident>.unmodifiable(residents);
    _memberships = List<ApartmentMembership>.unmodifiable(
      results[2] as List<ApartmentMembership>,
    );
    _householdMembers = List<HouseholdMember>.unmodifiable(
      results[3] as List<HouseholdMember>,
    );
    _myVerification = results[4] as ResidenceVerification;
    _verificationApartments = List<Apartment>.unmodifiable(
      results[5] as List<Apartment>,
    );
  }

  void _validateMembershipInput({
    required String apartmentId,
    required String fullName,
    required String phone,
    required String email,
    required MembershipType type,
    required DateTime startDate,
    required DateTime? endDate,
  }) {
    if (apartmentById(apartmentId) == null) {
      throw StateError('Căn hộ được chọn không tồn tại.');
    }
    if (fullName.trim().isEmpty ||
        phone.trim().isEmpty ||
        email.trim().isEmpty) {
      throw ArgumentError('Vui lòng nhập đầy đủ thông tin cư dân.');
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email.trim())) {
      throw ArgumentError('Email cư dân không hợp lệ.');
    }
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhone.length < 9 || normalizedPhone.length > 11) {
      throw ArgumentError('Số điện thoại cư dân không hợp lệ.');
    }
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
  }

  void _validateApartmentInput({
    required String code,
    required String buildingName,
    required int floor,
    required double area,
    required int bedrooms,
    String? excludingId,
  }) {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty || buildingName.trim().isEmpty) {
      throw ArgumentError('Vui lòng nhập đầy đủ mã căn hộ và tên tòa nhà.');
    }
    if (_apartments.any(
      (item) =>
          item.id != excludingId &&
          item.code.trim().toUpperCase() == normalizedCode,
    )) {
      throw StateError('Mã căn hộ $normalizedCode đã tồn tại.');
    }
    if (floor < 1) {
      throw ArgumentError('Tầng phải lớn hơn hoặc bằng 1.');
    }
    if (!area.isFinite || area <= 0) {
      throw ArgumentError('Diện tích phải lớn hơn 0.');
    }
    if (bedrooms < 1) {
      throw ArgumentError('Số phòng ngủ phải lớn hơn hoặc bằng 1.');
    }
  }

  int _typePriority(MembershipType type) {
    return switch (type) {
      MembershipType.owner => 0,
      MembershipType.tenant => 1,
    };
  }

  int _statusPriority(MembershipStatus status) {
    return switch (status) {
      MembershipStatus.active => 0,
      MembershipStatus.ended => 1,
    };
  }

  String _messageFor(Object error) {
    return switch (error) {
      StateError(message: final message) => message,
      ArgumentError(message: final Object? message) =>
        message?.toString() ?? 'Dữ liệu không hợp lệ.',
      _ => 'Không thể cập nhật dữ liệu căn hộ. Vui lòng thử lại.',
    };
  }
}
