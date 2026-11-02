enum AppNotificationType {
  invoice,
  maintenance,
  housing,
  amenity,
  service,
  system,
}

extension AppNotificationTypeX on AppNotificationType {
  String get displayName => switch (this) {
    AppNotificationType.invoice => 'Hóa đơn',
    AppNotificationType.maintenance => 'Bảo trì',
    AppNotificationType.housing => 'Thuê / mua',
    AppNotificationType.amenity => 'Tiện ích',
    AppNotificationType.service => 'Dịch vụ',
    AppNotificationType.system => 'Hệ thống',
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
    this.readAt,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final AppNotificationType type;
  final DateTime createdAt;
  final String? referenceType;
  final String? referenceId;
  final DateTime? readAt;
  final bool isRead;

  factory AppNotification.fromMap(Map<String, Object?> map) {
    final rawType = map['type']?.toString().toLowerCase() ?? 'system';
    final type = AppNotificationType.values.firstWhere(
      (item) => item.name == rawType,
      orElse: () => AppNotificationType.system,
    );
    return AppNotification(
      id: map['id']! as String,
      userId: map['userId']! as String,
      title: map['title']! as String,
      message: map['message']! as String,
      type: type,
      createdAt: DateTime.parse(map['createdAt']! as String).toLocal(),
      referenceType: _optionalText(map['referenceType']),
      referenceId: _optionalText(map['referenceId']),
      readAt: _optionalDateTime(map['readAt']),
      isRead: map['isRead'] == true,
    );
  }

  AppNotification copyWith({bool? isRead, DateTime? readAt}) => AppNotification(
    id: id,
    userId: userId,
    title: title,
    message: message,
    type: type,
    createdAt: createdAt,
    referenceType: referenceType,
    referenceId: referenceId,
    readAt: readAt ?? this.readAt,
    isRead: isRead ?? this.isRead,
  );

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _optionalDateTime(Object? value) {
    final text = _optionalText(value);
    return text == null ? null : DateTime.tryParse(text)?.toLocal();
  }
}
