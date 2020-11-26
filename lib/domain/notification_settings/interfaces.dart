import 'entities.dart';

abstract class INotificationSettingsService {
  Future<void> subscribeToDailyEngagementReminder(String notificationSettingsId);
  Future<void> unsubscribeFromDailyEngagementReminder(String notificationSettingsId);
  Future<NotificationSettingsEntity> getNotificationSettings();
}
