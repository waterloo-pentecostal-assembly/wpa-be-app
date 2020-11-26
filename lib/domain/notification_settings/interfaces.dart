import 'entities.dart';

abstract class INotificationSettingsService {
  // Future<void> unsubscribeFromDailyEngagementReminder(String notificationSettingsId);
  // Future<void> subscribeToDailyEngagementReminder(String notificationSettingsId);
  Future<void> subscribeToDailyEngagementReminder();
  Future<void> unsubscribeFromDailyEngagementReminder();
  Future<void> subscribeToPrayerNotifications();
  Future<void> unsubscribeFromPrayerNotifications();
  Future<NotificationSettingsEntity> getNotificationSettings();
}
