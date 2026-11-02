import 'package:homie/features/residents/models/resident.dart';

class ResidentModel extends Resident {
  const ResidentModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.email,
  });

  factory ResidentModel.fromMap(Map<String, Object?> map) {
    return ResidentModel(
      id: map['id']! as String,
      fullName: map['fullName']! as String,
      phone: map['phone']! as String,
      email: map['email']! as String,
    );
  }

  factory ResidentModel.fromEntity(Resident resident) {
    return ResidentModel(
      id: resident.id,
      fullName: resident.fullName,
      phone: resident.phone,
      email: resident.email,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
    };
  }
}
