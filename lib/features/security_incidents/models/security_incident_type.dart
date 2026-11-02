enum SecurityIncidentType {
  noise,
  disorder,
  suspiciousPerson,
  propertyDamage,
  fireSafety,
  dispute,
  lostAndFound,
  other;

  String get label => switch (this) {
    noise => 'Tiếng ồn',
    disorder => 'Mất trật tự',
    suspiciousPerson => 'Người khả nghi',
    propertyDamage => 'Hư hại tài sản',
    fireSafety => 'An toàn PCCC',
    dispute => 'Tranh chấp',
    lostAndFound => 'Thất lạc đồ',
    other => 'Khác',
  };
}
