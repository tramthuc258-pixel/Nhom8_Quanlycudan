class UnbilledServiceCharge {
  const UnbilledServiceCharge({
    required this.id,
    required this.code,
    required this.apartmentId,
    required this.requestedById,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.completedAt,
  });

  final String id;
  final String code;
  final String apartmentId;
  final String requestedById;
  final String serviceName;
  final double quantity;
  final double unitPrice;
  final DateTime completedAt;

  double get amount => quantity * unitPrice;

  factory UnbilledServiceCharge.fromMap(Map<String, Object?> map) =>
      UnbilledServiceCharge(
        id: map['id']! as String,
        code: map['code']! as String,
        apartmentId: map['apartmentId']! as String,
        requestedById: map['requestedById']! as String,
        serviceName: map['serviceName']! as String,
        quantity: (map['quantity']! as num).toDouble(),
        unitPrice: (map['unitPrice']! as num).toDouble(),
        completedAt: DateTime.parse(map['completedAt']! as String).toLocal(),
      );
}
