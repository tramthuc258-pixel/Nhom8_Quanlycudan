enum HousingInquiryStatus { newRequest, contacted, closed }

extension HousingInquiryStatusPresentation on HousingInquiryStatus {
  String get label => switch (this) {
    HousingInquiryStatus.newRequest => 'Mới',
    HousingInquiryStatus.contacted => 'Đã liên hệ',
    HousingInquiryStatus.closed => 'Đã đóng',
  };

  String get apiValue => switch (this) {
    HousingInquiryStatus.newRequest => 'NEW',
    HousingInquiryStatus.contacted => 'CONTACTED',
    HousingInquiryStatus.closed => 'CLOSED',
  };
}

class HousingInquiry {
  const HousingInquiry({
    required this.id,
    required this.code,
    required this.listingId,
    required this.apartmentCode,
    required this.buildingName,
    required this.listingTitle,
    required this.transactionType,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.email,
    this.message,
    this.staffNote,
    this.handledAt,
    this.handledBy,
  });

  final String id;
  final String code;
  final String listingId;
  final String apartmentCode;
  final String buildingName;
  final String listingTitle;
  final String transactionType;
  final String fullName;
  final String phone;
  final String? email;
  final String? message;
  final HousingInquiryStatus status;
  final String? staffNote;
  final DateTime? handledAt;
  final String? handledBy;
  final DateTime createdAt;

  factory HousingInquiry.fromMap(Map<String, Object?> map) {
    return HousingInquiry(
      id: map['id'] as String,
      code: map['code'] as String,
      listingId: map['listingId'] as String,
      apartmentCode: map['apartmentCode'] as String,
      buildingName: map['buildingName'] as String,
      listingTitle: map['listingTitle'] as String,
      transactionType: map['transactionType'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      message: map['message'] as String?,
      status: _statusFromMap(map['status']),
      staffNote: map['staffNote'] as String?,
      handledAt: _dateFromMap(map['handledAt']),
      handledBy: map['handledBy'] as String?,
      createdAt: _dateFromMap(map['createdAt']) ?? DateTime.now(),
    );
  }

  static HousingInquiryStatus _statusFromMap(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'contacted' => HousingInquiryStatus.contacted,
      'closed' => HousingInquiryStatus.closed,
      _ => HousingInquiryStatus.newRequest,
    };
  }

  static DateTime? _dateFromMap(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
