import 'package:homie/features/residents/models/membership_status.dart';
import 'package:homie/features/residents/models/membership_type.dart';

class ApartmentMembership {
  const ApartmentMembership({
    required this.id,
    required this.apartmentId,
    required this.residentId,
    required this.type,
    required this.startDate,
    required this.status,
    this.endDate,
    this.isPrimary = false,
  });

  final String id;
  final String apartmentId;
  final String residentId;
  final MembershipType type;
  final DateTime startDate;
  final DateTime? endDate;
  final MembershipStatus status;
  final bool isPrimary;

  bool get isActive => isActiveAt(DateTime.now());

  bool isActiveAt(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final firstDay = DateTime(startDate.year, startDate.month, startDate.day);
    final lastDate = endDate;
    final lastDay = lastDate == null
        ? null
        : DateTime(lastDate.year, lastDate.month, lastDate.day);

    return status == MembershipStatus.active &&
        !firstDay.isAfter(day) &&
        (lastDay == null || !lastDay.isBefore(day));
  }

  ApartmentMembership copyWith({
    String? id,
    String? apartmentId,
    String? residentId,
    MembershipType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    MembershipStatus? status,
    bool? isPrimary,
  }) {
    return ApartmentMembership(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      residentId: residentId ?? this.residentId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      status: status ?? this.status,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ApartmentMembership &&
            other.id == id &&
            other.apartmentId == apartmentId &&
            other.residentId == residentId &&
            other.type == type &&
            other.startDate == startDate &&
            other.endDate == endDate &&
            other.status == status &&
            other.isPrimary == isPrimary;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      apartmentId,
      residentId,
      type,
      startDate,
      endDate,
      status,
      isPrimary,
    );
  }
}
