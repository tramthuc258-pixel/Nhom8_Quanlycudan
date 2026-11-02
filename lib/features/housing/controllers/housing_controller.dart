import 'package:flutter/foundation.dart';

import 'package:homie/features/apartments/models/apartment.dart';
import 'package:homie/features/apartments/models/apartment_status.dart';
import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_inquiry.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/services/housing_repository.dart';

class HousingController extends ChangeNotifier {
  HousingController({
    required this.repository,
    required this.apartmentMembershipController,
  });

  final HousingRepository repository;
  final ApartmentMembershipController apartmentMembershipController;

  bool _isLoading = false;
  String? _errorMessage;
  List<HousingListing> _allListings = const <HousingListing>[];
  List<HousingApplication> _applications = const <HousingApplication>[];
  List<HousingInquiry> _inquiries = const <HousingInquiry>[];
  String _searchQuery = '';
  HousingTransactionType? _transactionTypeFilter;
  HousingListingStatus? _listingStatusFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HousingListing> get allListings => _allListings;
  List<HousingApplication> get applications => _applications;
  List<HousingInquiry> get inquiries => _inquiries;
  String get searchQuery => _searchQuery;
  HousingTransactionType? get transactionTypeFilter => _transactionTypeFilter;
  HousingListingStatus? get listingStatusFilter => _listingStatusFilter;

  List<HousingListing> get listings {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return List<HousingListing>.unmodifiable(
      _allListings.where((listing) {
        if (_transactionTypeFilter != null &&
            listing.transactionType != _transactionTypeFilter) {
          return false;
        }
        if (_listingStatusFilter != null &&
            listing.status != _listingStatusFilter) {
          return false;
        }
        if (normalizedQuery.isEmpty) return true;
        return listing.apartmentCode.toLowerCase().contains(normalizedQuery) ||
            listing.buildingName.toLowerCase().contains(normalizedQuery) ||
            listing.title.toLowerCase().contains(normalizedQuery) ||
            listing.description.toLowerCase().contains(normalizedQuery);
      }),
    );
  }

  List<HousingListing> get availableListings =>
      List<HousingListing>.unmodifiable(
        _allListings.where((listing) => listing.isAvailable),
      );

  List<HousingListing> get publicListings => List<HousingListing>.unmodifiable(
    _allListings.where((listing) => listing.status.isPublic),
  );

  List<HousingApplication> get pendingApplications =>
      applicationsByStatus(HousingApplicationStatus.pending);

  List<HousingListing> listingsSubmittedBy(String userId) {
    return List<HousingListing>.unmodifiable(
      _allListings.where((listing) => listing.submittedById == userId),
    );
  }

  List<Apartment> apartmentsEligibleForListing(User actor) {
    if (actor.role.isManager) {
      return List<Apartment>.unmodifiable(
        apartmentMembershipController.apartments.where((apartment) {
          final hasOwner = apartmentMembershipController
              .membershipsForApartment(apartment.id, includeEnded: false)
              .any((membership) => membership.type == MembershipType.owner);
          return !hasOwner && _canStartListingFor(apartment);
        }),
      );
    }
    if (!actor.role.isResident) return const <Apartment>[];
    final ownedApartmentIds = apartmentMembershipController.memberships
        .where(
          (membership) =>
              membership.residentId == actor.id &&
              membership.type == MembershipType.owner &&
              membership.status == MembershipStatus.active,
        )
        .map((membership) => membership.apartmentId)
        .toSet();
    return List<Apartment>.unmodifiable(
      apartmentMembershipController.apartments.where(
        (apartment) =>
            ownedApartmentIds.contains(apartment.id) &&
            _canStartListingFor(apartment),
      ),
    );
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait<void>(<Future<void>>[
        _refresh(),
        apartmentMembershipController.load(),
      ]);
      final membershipError = apartmentMembershipController.errorMessage;
      if (membershipError != null) throw StateError(membershipError);
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPublic() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final listings = await repository.getPublicListings();
      _allListings = List<HousingListing>.unmodifiable(
        List<HousingListing>.from(listings)..sort(_compareListings),
      );
      _applications = const <HousingApplication>[];
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInquiries() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _inquiries = List<HousingInquiry>.unmodifiable(
        await repository.getInquiries(),
      );
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPublicInquiry({
    required String listingId,
    required String fullName,
    required String phone,
    required String email,
    required String message,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.submitPublicInquiry(
        listingId: listingId,
        fullName: fullName,
        phone: phone,
        email: email,
        message: message,
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

  Future<bool> updateInquiry({
    required String inquiryId,
    required HousingInquiryStatus status,
    required String staffNote,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.updateInquiry(
        inquiryId: inquiryId,
        status: status,
        staffNote: staffNote,
      );
      _inquiries = List<HousingInquiry>.unmodifiable(
        _inquiries.map((item) => item.id == updated.id ? updated : item),
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

  HousingListing? listingById(String listingId) {
    for (final listing in _allListings) {
      if (listing.id == listingId) return listing;
    }
    return null;
  }

  HousingApplication? applicationById(String applicationId) {
    for (final application in _applications) {
      if (application.id == applicationId) return application;
    }
    return null;
  }

  Future<bool> createListing({
    required User actor,
    required String apartmentId,
    required String title,
    required String description,
    required HousingTransactionType transactionType,
    required double price,
    required double deposit,
    required DateTime availableFrom,
    List<String> imageUrls = const <String>[],
  }) async {
    return _mutate(() async {
      final apartment = apartmentMembershipController.apartmentById(
        apartmentId,
      );
      if (apartment == null) throw StateError('Không tìm thấy căn hộ.');
      final eligible = apartmentsEligibleForListing(actor)
          .any((item) => item.id == apartmentId);
      if (!eligible) {
        throw StateError(
          actor.role.isManager
              ? 'Ban quản lý chỉ được đăng căn thuộc quỹ quản lý và chưa có bài đang xử lý.'
              : 'Bạn không có quyền đăng căn hộ này hoặc căn hộ đã có bài đang xử lý.',
        );
      }
      if (apartment.status == ApartmentStatus.underMaintenance) {
        throw StateError('Không thể đăng căn hộ đang bảo trì.');
      }
      final hasActiveTenant = apartmentMembershipController
          .membershipsForApartment(apartmentId, includeEnded: false)
          .any((membership) => membership.type == MembershipType.tenant);
      if (hasActiveTenant) {
        throw StateError(
          'Căn hộ đang có người thuê. Hãy kết thúc quan hệ thuê trước khi đăng.',
        );
      }
      if (title.trim().length < 5 || description.trim().length < 10) {
        throw ArgumentError('Tiêu đề hoặc mô tả bài đăng quá ngắn.');
      }
      if (!price.isFinite || price <= 0 || !deposit.isFinite || deposit < 0) {
        throw ArgumentError('Giá và tiền đặt cọc không hợp lệ.');
      }

      await repository.createListing(
        apartmentId: apartment.id,
        apartmentCode: apartment.code,
        buildingName: apartment.buildingName,
        title: title,
        description: description,
        transactionType: transactionType,
        price: price,
        deposit: deposit,
        availableFrom: availableFrom,
        status: actor.role.isManager
            ? HousingListingStatus.available
            : HousingListingStatus.pendingApproval,
        submittedById: actor.id,
        submittedByName: actor.fullName,
        ownerSubmitted: actor.role.isResident,
        imageUrls: imageUrls,
      );
    });
  }

  Future<bool> approveListing({
    required String listingId,
    required User reviewer,
  }) async {
    return _mutate(() async {
      _ensureManager(reviewer);
      await repository.approveListing(
        listingId: listingId,
        reviewedBy: reviewer.fullName,
      );
    });
  }

  Future<bool> rejectListing({
    required String listingId,
    required User reviewer,
    required String reason,
  }) async {
    return _mutate(() async {
      _ensureManager(reviewer);
      await repository.rejectListing(
        listingId: listingId,
        reviewedBy: reviewer.fullName,
        reason: reason,
      );
    });
  }

  List<HousingApplication> applicationsForApplicant(String applicantId) {
    return List<HousingApplication>.unmodifiable(
      _applications.where(
        (application) => application.applicantId == applicantId,
      ),
    );
  }

  List<HousingApplication> applicationsByStatus(
    HousingApplicationStatus status,
  ) {
    return List<HousingApplication>.unmodifiable(
      _applications.where((application) => application.status == status),
    );
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setTransactionTypeFilter(HousingTransactionType? value) {
    if (_transactionTypeFilter == value) return;
    _transactionTypeFilter = value;
    notifyListeners();
  }

  void setListingStatusFilter(HousingListingStatus? value) {
    if (_listingStatusFilter == value) return;
    _listingStatusFilter = value;
    notifyListeners();
  }

  void clearListingFilters() {
    if (_searchQuery.isEmpty &&
        _transactionTypeFilter == null &&
        _listingStatusFilter == null) {
      return;
    }
    _searchQuery = '';
    _transactionTypeFilter = null;
    _listingStatusFilter = null;
    notifyListeners();
  }

  Future<bool> submitApplication({
    required String listingId,
    required User applicant,
    required String phone,
    required DateTime preferredStartDate,
    DateTime? preferredEndDate,
    String note = '',
  }) async {
    return _mutate(() async {
      if (!applicant.role.isResident) {
        throw StateError('Chỉ tài khoản cư dân mới có thể nộp hồ sơ.');
      }
      final listing = listingById(listingId);
      if (listing == null) throw StateError('Không tìm thấy tin đăng căn hộ.');
      if (!listing.isAvailable) {
        throw StateError('Tin đăng này không còn nhận hồ sơ.');
      }
      await repository.submitApplication(
        listingId: listing.id,
        applicantId: applicant.id,
        applicantFullName: applicant.fullName,
        applicantEmail: applicant.email,
        applicantPhone: phone,
        preferredStartDate: preferredStartDate,
        preferredEndDate: preferredEndDate,
        note: note,
      );
    });
  }

  Future<bool> completeApplication({
    required String applicationId,
    required User reviewer,
    required String contractNumber,
    required DateTime contractSignedAt,
    required DateTime effectiveDate,
    String note = '',
  }) async {
    return _mutate(() async {
      _ensureManager(reviewer);
      final application = applicationById(applicationId);
      if (application == null) {
        throw StateError('Không tìm thấy hồ sơ đăng ký.');
      }
      if (!application.canBeReviewed) {
        throw StateError('Hồ sơ này đã được xử lý trước đó.');
      }
      final listing = listingById(application.listingId);
      if (listing == null || !listing.isAvailable) {
        throw StateError('Tin đăng không còn nhận hồ sơ.');
      }
      if (contractNumber.trim().length < 4) {
        throw ArgumentError('Mã hợp đồng phải có ít nhất 4 ký tự.');
      }
      if (effectiveDate.isBefore(contractSignedAt)) {
        throw ArgumentError('Ngày hiệu lực không được trước ngày ký hợp đồng.');
      }
      if (application.transactionType == HousingTransactionType.rent &&
          application.preferredEndDate != null &&
          !application.preferredEndDate!.isAfter(effectiveDate)) {
        throw ArgumentError('Ngày kết thúc thuê phải sau ngày hiệu lực.');
      }
      if (!repository.managesMemberships) {
        _validateApplicantCanReceiveMembership(application);
        if (application.transactionType == HousingTransactionType.purchase) {
          await _endActiveOwners(application.apartmentId);
        }

        final membershipType =
            application.transactionType == HousingTransactionType.rent
            ? MembershipType.tenant
            : MembershipType.owner;
        final membershipCreated = await apartmentMembershipController
            .addMembership(
              apartmentId: application.apartmentId,
              residentId: application.applicantId,
              fullName: application.applicantFullName,
              phone: application.applicantPhone,
              email: application.applicantEmail,
              type: membershipType,
              startDate: effectiveDate,
              endDate:
                  application.transactionType == HousingTransactionType.rent
                  ? application.preferredEndDate
                  : null,
            );
        if (!membershipCreated) {
          throw StateError(
            apartmentMembershipController.errorMessage ??
                'Không thể tạo quan hệ với căn hộ.',
          );
        }
      }
      await repository.completeApplication(
        applicationId: application.id,
        completedBy: reviewer.fullName,
        contractNumber: contractNumber,
        contractSignedAt: contractSignedAt,
        effectiveDate: effectiveDate,
        note: note,
      );
      if (repository.managesMemberships) {
        await apartmentMembershipController.load();
        if (apartmentMembershipController.errorMessage case final message?) {
          throw StateError(message);
        }
      }
    });
  }

  Future<bool> rejectApplication({
    required String applicationId,
    required User reviewer,
    required String reason,
  }) async {
    return _mutate(() async {
      _ensureManager(reviewer);
      await repository.rejectApplication(
        applicationId: applicationId,
        reviewedBy: reviewer.fullName,
        reason: reason,
      );
    });
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _endActiveOwners(String apartmentId) async {
    final owners = apartmentMembershipController
        .membershipsForApartment(apartmentId, includeEnded: false)
        .where(
          (membership) =>
              membership.type == MembershipType.owner &&
              membership.status == MembershipStatus.active,
        )
        .toList(growable: false);
    for (final owner in owners) {
      final ended = await apartmentMembershipController.endMembership(owner.id);
      if (!ended) {
        throw StateError(
          apartmentMembershipController.errorMessage ??
              'Không thể kết thúc quyền sở hữu hiện tại.',
        );
      }
    }
  }

  void _validateApplicantCanReceiveMembership(HousingApplication application) {
    for (final resident in apartmentMembershipController.residents) {
      if (resident.id == application.applicantId &&
          resident.email.toLowerCase() !=
              application.applicantEmail.toLowerCase()) {
        throw StateError('Mã người dùng đã thuộc về một cư dân khác.');
      }
    }

    final normalizedPhone = application.applicantPhone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final matchingResidentIds = apartmentMembershipController.residents
        .where(
          (resident) =>
              resident.id == application.applicantId ||
              resident.email.toLowerCase() ==
                  application.applicantEmail.toLowerCase() ||
              resident.phone.replaceAll(RegExp(r'[^0-9]'), '') ==
                  normalizedPhone,
        )
        .map((resident) => resident.id)
        .toSet();
    final alreadyRelated = apartmentMembershipController.memberships.any(
      (membership) =>
          membership.apartmentId == application.apartmentId &&
          matchingResidentIds.contains(membership.residentId) &&
          membership.status == MembershipStatus.active,
    );
    if (alreadyRelated) {
      throw StateError(
        '${application.applicantFullName} đã có quan hệ đang hiệu lực với căn hộ.',
      );
    }
  }

  void _ensureManager(User reviewer) {
    if (!reviewer.role.isManager) {
      throw StateError('Chỉ ban quản lý mới có quyền xử lý hồ sơ.');
    }
  }

  bool _canStartListingFor(Apartment apartment) {
    if (apartment.status == ApartmentStatus.underMaintenance) return false;
    return !_allListings.any(
      (listing) =>
          listing.apartmentId == apartment.id &&
          listing.status != HousingListingStatus.closed &&
          listing.status != HousingListingStatus.rejected,
    );
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await _refresh();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      repository.getListings(),
      repository.getApplications(),
    ]);
    final listings = List<HousingListing>.from(
      results[0] as List<HousingListing>,
    )..sort(_compareListings);
    final applications = List<HousingApplication>.from(
      results[1] as List<HousingApplication>,
    )..sort(_compareApplications);
    _allListings = List<HousingListing>.unmodifiable(listings);
    _applications = List<HousingApplication>.unmodifiable(applications);
  }

  int _compareListings(HousingListing first, HousingListing second) {
    if (first.isAvailable != second.isAvailable) {
      return first.isAvailable ? -1 : 1;
    }
    return second.createdAt.compareTo(first.createdAt);
  }

  int _compareApplications(
    HousingApplication first,
    HousingApplication second,
  ) {
    if (first.status.isPending != second.status.isPending) {
      return first.status.isPending ? -1 : 1;
    }
    return second.submittedAt.compareTo(first.submittedAt);
  }

  String _messageFor(Object error) => switch (error) {
    StateError(message: final message) => message,
    ArgumentError(message: final Object? message) =>
      message?.toString() ?? 'Dữ liệu hồ sơ không hợp lệ.',
    _ => 'Không thể cập nhật hồ sơ thuê/mua. Vui lòng thử lại.',
  };
}
