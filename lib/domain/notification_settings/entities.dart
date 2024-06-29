class NotificationSettingsEntity {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool testimonies;

  NotificationSettingsEntity({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
    required this.testimonies,
  });
}
