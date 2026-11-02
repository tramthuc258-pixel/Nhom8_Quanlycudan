import 'package:homie/features/housing/models/housing_application.dart';
import 'package:homie/features/housing/models/housing_application_status.dart';
import 'package:homie/features/housing/models/housing_listing_status.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/models/housing_inquiry.dart';

import '../models/housing_application_model.dart';
import '../models/housing_listing_model.dart';
import 'housing_data_source.dart';

class HousingMockDataSource implements HousingDataSource {
  HousingMockDataSource({this.referenceTime})
    : _listings = _seedListings(),
      _applications = _seedApplications();

  final DateTime? referenceTime;
  final List<HousingListingModel> _listings;
  final List<HousingApplicationModel> _applications;
  final List<HousingInquiry> _inquiries = <HousingInquiry>[];
  int _nextApplicationNumber = 1004;
  int _nextListingNumber = 1005;

  DateTime get _now => referenceTime ?? DateTime.now();

  @override
  bool get managesMemberships => false;

  @override
  Future<List<HousingListingModel>> getListings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List<HousingListingModel>.unmodifiable(_listings);
  }

  @override
  Future<List<HousingListingModel>> getPublicListings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List<HousingListingModel>.unmodifiable(
      _listings.where(
        (listing) => listing.status == HousingListingStatus.available,
      ),
    );
  }

  @override
  Future<List<HousingInquiry>> getInquiries() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return List<HousingInquiry>.unmodifiable(_inquiries.reversed);
  }

  @override
  Future<HousingInquiry> submitPublicInquiry({
    required String listingId,
    required String fullName,
    required String phone,
    required String email,
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final listing = _listingById(listingId);
    final inquiry = HousingInquiry(
      id: 'inquiry-${_now.microsecondsSinceEpoch}',
      code: 'LH-${_now.year}-${_inquiries.length + 1001}',
      listingId: listing.id,
      apartmentCode: listing.apartmentCode,
      buildingName: listing.buildingName,
      listingTitle: listing.title,
      transactionType: listing.transactionType.name,
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim().isEmpty ? null : email.trim(),
      message: message.trim().isEmpty ? null : message.trim(),
      status: HousingInquiryStatus.newRequest,
      createdAt: _now,
    );
    _inquiries.add(inquiry);
    return inquiry;
  }

  @override
  Future<HousingInquiry> updateInquiry({
    required String inquiryId,
    required HousingInquiryStatus status,
    required String staffNote,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _inquiries.indexWhere((item) => item.id == inquiryId);
    if (index < 0) throw StateError('Không tìm thấy yêu cầu liên hệ.');
    final current = _inquiries[index];
    final updated = HousingInquiry(
      id: current.id,
      code: current.code,
      listingId: current.listingId,
      apartmentCode: current.apartmentCode,
      buildingName: current.buildingName,
      listingTitle: current.listingTitle,
      transactionType: current.transactionType,
      fullName: current.fullName,
      phone: current.phone,
      email: current.email,
      message: current.message,
      status: status,
      staffNote: staffNote.trim().isEmpty ? null : staffNote.trim(),
      handledAt: _now,
      handledBy: 'Ban quản lý',
      createdAt: current.createdAt,
    );
    _inquiries[index] = updated;
    return updated;
  }

  @override
  Future<List<HousingApplicationModel>> getApplications() async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    return List<HousingApplicationModel>.unmodifiable(_applications);
  }

  @override
  Future<HousingListingModel> createListing({
    required String apartmentId,
    required String apartmentCode,
    required String buildingName,
    required String title,
    required String description,
    required HousingTransactionType transactionType,
    required double price,
    required double deposit,
    required DateTime availableFrom,
    required HousingListingStatus status,
    required String submittedById,
    required String submittedByName,
    required bool ownerSubmitted,
    List<String> imageUrls = const <String>[],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (title.trim().length < 5 || description.trim().length < 10) {
      throw ArgumentError('Tiêu đề hoặc mô tả bài đăng quá ngắn.');
    }
    if (!price.isFinite || price <= 0 || !deposit.isFinite || deposit < 0) {
      throw ArgumentError('Giá và tiền đặt cọc không hợp lệ.');
    }
    final hasOpenListing = _listings.any(
      (listing) =>
          listing.apartmentId == apartmentId &&
          listing.status != HousingListingStatus.closed &&
          listing.status != HousingListingStatus.rejected,
    );
    if (hasOpenListing) {
      throw StateError('Căn hộ đã có một bài đăng đang được xử lý.');
    }

    final sequence = _nextListingNumber++;
    final listing = HousingListingModel(
      id: 'housing-listing-${_now.microsecondsSinceEpoch}-$sequence',
      apartmentId: apartmentId,
      apartmentCode: apartmentCode.trim().toUpperCase(),
      buildingName: buildingName.trim(),
      title: title.trim(),
      description: description.trim(),
      transactionType: transactionType,
      price: price,
      deposit: transactionType == HousingTransactionType.rent ? deposit : 0,
      availableFrom: availableFrom,
      status: status,
      createdAt: _now,
      submittedById: submittedById.trim(),
      submittedByName: submittedByName.trim(),
      ownerSubmitted: ownerSubmitted,
      imageUrls: List<String>.unmodifiable(imageUrls),
    );
    _listings.add(listing);
    return listing;
  }

  @override
  Future<HousingListingModel> approveListing({
    required String listingId,
    required String reviewedBy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final index = _listingIndex(listingId);
    final listing = _listings[index];
    if (listing.status != HousingListingStatus.pendingApproval) {
      throw StateError('Bài đăng này đã được xử lý trước đó.');
    }
    final approved = HousingListingModel.fromEntity(
      listing.copyWith(
        status: HousingListingStatus.available,
        reviewedAt: _now,
        reviewedBy: reviewedBy.trim(),
        reviewNote: 'Bài đăng đã được ban quản lý phê duyệt.',
      ),
    );
    _listings[index] = approved;
    return approved;
  }

  @override
  Future<HousingListingModel> rejectListing({
    required String listingId,
    required String reviewedBy,
    required String reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (reason.trim().length < 5) {
      throw ArgumentError('Vui lòng nhập lý do từ chối ít nhất 5 ký tự.');
    }
    final index = _listingIndex(listingId);
    final listing = _listings[index];
    if (listing.status != HousingListingStatus.pendingApproval) {
      throw StateError('Bài đăng này đã được xử lý trước đó.');
    }
    final rejected = HousingListingModel.fromEntity(
      listing.copyWith(
        status: HousingListingStatus.rejected,
        reviewedAt: _now,
        reviewedBy: reviewedBy.trim(),
        reviewNote: reason.trim(),
      ),
    );
    _listings[index] = rejected;
    return rejected;
  }

  @override
  Future<HousingApplicationModel> submitApplication({
    required String listingId,
    required String applicantId,
    required String applicantFullName,
    required String applicantEmail,
    required String applicantPhone,
    required DateTime preferredStartDate,
    required DateTime? preferredEndDate,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final listing = _listingById(listingId);
    if (!listing.isAvailable) {
      throw StateError('Tin đăng này không còn nhận hồ sơ.');
    }
    _validateApplication(
      listing: listing,
      applicantId: applicantId,
      applicantFullName: applicantFullName,
      applicantEmail: applicantEmail,
      applicantPhone: applicantPhone,
      preferredStartDate: preferredStartDate,
      preferredEndDate: preferredEndDate,
      note: note,
    );

    final hasPendingDuplicate = _applications.any(
      (application) =>
          application.listingId == listing.id &&
          application.applicantId == applicantId.trim() &&
          application.status == HousingApplicationStatus.pending,
    );
    if (hasPendingDuplicate) {
      throw StateError('Bạn đã có một hồ sơ đang chờ duyệt cho căn hộ này.');
    }

    final now = _now;
    final sequence = _nextApplicationNumber++;
    final application = HousingApplicationModel(
      id: 'housing-application-${now.microsecondsSinceEpoch}-$sequence',
      code: 'HS-${now.year}-${sequence.toString().padLeft(4, '0')}',
      listingId: listing.id,
      apartmentId: listing.apartmentId,
      transactionType: listing.transactionType,
      applicantId: applicantId.trim(),
      applicantFullName: applicantFullName.trim(),
      applicantEmail: applicantEmail.trim().toLowerCase(),
      applicantPhone: applicantPhone.trim(),
      preferredStartDate: preferredStartDate,
      preferredEndDate: listing.transactionType == HousingTransactionType.rent
          ? preferredEndDate
          : null,
      note: note.trim(),
      status: HousingApplicationStatus.pending,
      submittedAt: now,
    );
    _applications.add(application);
    return application;
  }

  @override
  Future<HousingApplicationModel> rejectApplication({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (reason.trim().length < 5) {
      throw ArgumentError('Vui lòng nhập lý do từ chối ít nhất 5 ký tự.');
    }
    final index = _applicationIndex(applicationId);
    final application = _applications[index];
    _ensurePending(application);

    final rejected = HousingApplicationModel.fromEntity(
      application.copyWith(
        status: HousingApplicationStatus.rejected,
        reviewedAt: _now,
        reviewedBy: reviewedBy.trim(),
        reviewNote: reason.trim(),
      ),
    );
    _applications[index] = rejected;
    return rejected;
  }

  @override
  Future<HousingApplicationModel> completeApplication({
    required String applicationId,
    required String completedBy,
    required String contractNumber,
    required DateTime contractSignedAt,
    required DateTime effectiveDate,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final applicationIndex = _applicationIndex(applicationId);
    final application = _applications[applicationIndex];
    _ensurePending(application);
    final listingIndex = _listingIndex(application.listingId);
    final listing = _listings[listingIndex];
    if (!listing.isAvailable) {
      throw StateError('Tin đăng không còn nhận hồ sơ.');
    }
    if (contractNumber.trim().length < 4) {
      throw ArgumentError('Mã hợp đồng phải có ít nhất 4 ký tự.');
    }
    final signedDay = DateTime(
      contractSignedAt.year,
      contractSignedAt.month,
      contractSignedAt.day,
    );
    final effectiveDay = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    if (effectiveDay.isBefore(signedDay)) {
      throw ArgumentError('Ngày hiệu lực không được trước ngày ký hợp đồng.');
    }

    final now = _now;
    final completed = HousingApplicationModel.fromEntity(
      application.copyWith(
        status: HousingApplicationStatus.completed,
        reviewedAt: now,
        reviewedBy: completedBy.trim(),
        reviewNote: note.trim().isEmpty
            ? 'Đã xác nhận ký hợp đồng và hoàn tất giao dịch bên ngoài ứng dụng.'
            : note.trim(),
        contractNumber: contractNumber.trim().toUpperCase(),
        contractSignedAt: signedDay,
        effectiveDate: effectiveDay,
      ),
    );
    _applications[applicationIndex] = completed;

    for (var index = 0; index < _applications.length; index++) {
      final candidate = _applications[index];
      if (candidate.id != completed.id &&
          candidate.listingId == completed.listingId &&
          candidate.status == HousingApplicationStatus.pending) {
        _applications[index] = HousingApplicationModel.fromEntity(
          candidate.copyWith(
            status: HousingApplicationStatus.rejected,
            reviewedAt: now,
            reviewedBy: completedBy.trim(),
            reviewNote: 'Căn hộ đã hoàn tất giao dịch với một hồ sơ khác.',
          ),
        );
      }
    }
    _listings[listingIndex] = HousingListingModel.fromEntity(
      listing.copyWith(status: HousingListingStatus.closed),
    );
    return completed;
  }

  HousingListingModel _listingById(String listingId) {
    return _listings[_listingIndex(listingId)];
  }

  int _listingIndex(String listingId) {
    final index = _listings.indexWhere((listing) => listing.id == listingId);
    if (index < 0) throw StateError('Không tìm thấy tin đăng căn hộ.');
    return index;
  }

  int _applicationIndex(String applicationId) {
    final index = _applications.indexWhere(
      (application) => application.id == applicationId,
    );
    if (index < 0) throw StateError('Không tìm thấy hồ sơ đăng ký.');
    return index;
  }

  void _ensurePending(HousingApplication application) {
    if (!application.status.isPending) {
      throw StateError('Hồ sơ này đã được xử lý trước đó.');
    }
  }

  void _validateApplication({
    required HousingListingModel listing,
    required String applicantId,
    required String applicantFullName,
    required String applicantEmail,
    required String applicantPhone,
    required DateTime preferredStartDate,
    required DateTime? preferredEndDate,
    required String note,
  }) {
    if (applicantId.trim().isEmpty || applicantFullName.trim().length < 2) {
      throw ArgumentError('Không xác định được người nộp hồ sơ.');
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(applicantEmail.trim())) {
      throw ArgumentError('Email người đăng ký không hợp lệ.');
    }
    final normalizedPhone = applicantPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhone.length < 9 || normalizedPhone.length > 11) {
      throw ArgumentError('Số điện thoại người đăng ký không hợp lệ.');
    }

    final today = DateTime(_now.year, _now.month, _now.day);
    final startDay = DateTime(
      preferredStartDate.year,
      preferredStartDate.month,
      preferredStartDate.day,
    );
    final availableDay = DateTime(
      listing.availableFrom.year,
      listing.availableFrom.month,
      listing.availableFrom.day,
    );
    if (startDay.isBefore(today) || startDay.isBefore(availableDay)) {
      throw ArgumentError('Ngày bắt đầu phải từ ngày căn hộ sẵn sàng.');
    }
    if (listing.transactionType == HousingTransactionType.rent) {
      if (preferredEndDate == null ||
          !preferredEndDate.isAfter(preferredStartDate)) {
        throw ArgumentError('Ngày kết thúc thuê phải sau ngày bắt đầu.');
      }
    }
    if (note.trim().length > 1000) {
      throw ArgumentError('Ghi chú không được vượt quá 1000 ký tự.');
    }
  }

  static List<HousingListingModel> _seedListings() {
    return <HousingListingModel>[
      HousingListingModel(
        id: 'housing-listing-rent-001',
        apartmentId: 'apartment-002',
        apartmentCode: 'A-1002',
        buildingName: 'Tòa A',
        title: 'Căn hộ 2 phòng ngủ, nội thất cơ bản',
        description:
            'Căn hộ thoáng, gần thang máy và có thể nhận nhà ngay trong tháng.',
        transactionType: HousingTransactionType.rent,
        price: 13500000,
        deposit: 27000000,
        availableFrom: DateTime(2026, 10, 20),
        status: HousingListingStatus.available,
        createdAt: DateTime(2026, 10, 5, 9),
      ),
      HousingListingModel(
        id: 'housing-listing-purchase-001',
        apartmentId: 'apartment-004',
        apartmentCode: 'B-1501',
        buildingName: 'Tòa B',
        title: 'Căn góc 3 phòng ngủ, tầng cao',
        description:
            'Căn góc diện tích lớn, tầm nhìn thoáng và hồ sơ pháp lý đầy đủ.',
        transactionType: HousingTransactionType.purchase,
        price: 4850000000,
        availableFrom: DateTime(2026, 11, 1),
        status: HousingListingStatus.available,
        createdAt: DateTime(2026, 10, 7, 14, 30),
      ),
      HousingListingModel(
        id: 'housing-listing-rent-002',
        apartmentId: 'apartment-003',
        apartmentCode: 'B-0803',
        buildingName: 'Tòa B',
        title: 'Căn hộ 2 phòng ngủ đang trống',
        description:
            'Không gian phù hợp gia đình trẻ, bàn giao sạch sẽ và sẵn sàng ở.',
        transactionType: HousingTransactionType.rent,
        price: 11800000,
        deposit: 23600000,
        availableFrom: DateTime(2026, 10, 18),
        status: HousingListingStatus.available,
        createdAt: DateTime(2026, 10, 10, 8),
      ),
      HousingListingModel(
        id: 'housing-listing-closed-001',
        apartmentId: 'apartment-005',
        apartmentCode: 'C-0406',
        buildingName: 'Tòa C',
        title: 'Căn hộ 2 phòng ngủ',
        description: 'Tin đăng đã ngừng nhận hồ sơ do căn hộ đang bảo trì.',
        transactionType: HousingTransactionType.purchase,
        price: 3200000000,
        availableFrom: DateTime(2026, 12, 1),
        status: HousingListingStatus.closed,
        createdAt: DateTime(2026, 9, 20, 10),
      ),
    ];
  }

  static List<HousingApplicationModel> _seedApplications() {
    return <HousingApplicationModel>[
      HousingApplicationModel(
        id: 'housing-application-001',
        code: 'HS-2026-1001',
        listingId: 'housing-listing-rent-001',
        apartmentId: 'apartment-002',
        transactionType: HousingTransactionType.rent,
        applicantId: 'user-applicant-001',
        applicantFullName: 'Nguyễn Hoài Nam',
        applicantEmail: 'hoainam@example.com',
        applicantPhone: '0905111222',
        preferredStartDate: DateTime(2026, 11, 1),
        preferredEndDate: DateTime(2027, 10, 31),
        note: 'Gia đình ba người, mong muốn thuê dài hạn.',
        status: HousingApplicationStatus.pending,
        submittedAt: DateTime(2026, 10, 14, 9, 15),
      ),
      HousingApplicationModel(
        id: 'housing-application-002',
        code: 'HS-2026-1002',
        listingId: 'housing-listing-purchase-001',
        apartmentId: 'apartment-004',
        transactionType: HousingTransactionType.purchase,
        applicantId: 'user-applicant-002',
        applicantFullName: 'Phạm Ngọc Linh',
        applicantEmail: 'ngoclinh@example.com',
        applicantPhone: '0916333444',
        preferredStartDate: DateTime(2026, 12, 1),
        note: 'Đã xem căn hộ và muốn thực hiện thủ tục chuyển nhượng.',
        status: HousingApplicationStatus.pending,
        submittedAt: DateTime(2026, 10, 15, 15, 40),
      ),
      HousingApplicationModel(
        id: 'housing-application-003',
        code: 'HS-2026-1003',
        listingId: 'housing-listing-rent-002',
        apartmentId: 'apartment-003',
        transactionType: HousingTransactionType.rent,
        applicantId: 'user-applicant-003',
        applicantFullName: 'Lê Minh Khoa',
        applicantEmail: 'minhkhoa@example.com',
        applicantPhone: '0987222111',
        preferredStartDate: DateTime(2026, 10, 20),
        preferredEndDate: DateTime(2027, 4, 20),
        note: '',
        status: HousingApplicationStatus.rejected,
        submittedAt: DateTime(2026, 10, 8, 10),
        reviewedAt: DateTime(2026, 10, 10, 16),
        reviewedBy: 'Ban quản lý Homie',
        reviewNote: 'Thời hạn thuê chưa phù hợp với chính sách của chủ căn hộ.',
      ),
    ];
  }
}
