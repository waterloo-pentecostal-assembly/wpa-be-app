import 'entities.dart';

/// Notification preferences of the current user, stored in
/// `users/{uid}/notification_settings/{id}`. FCM topic (un)subscription is
/// performed by Cloud Functions reacting to these flags.
abstract class INotificationSettingsService {
  Future<NotificationSettingsEntity> getNotificationSettings();

  /// Sets one preference flag.
  Future<void> setSetting(NotificationSetting setting, bool enabled);

  Future<void> followThread(String threadId);
  Future<void> unfollowThread(String threadId);
}
