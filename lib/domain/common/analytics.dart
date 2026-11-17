/// Analytics sink. The Firebase implementation lives in infrastructure.
abstract class IAnalytics {
  Future<void> log(String name, [Map<String, Object>? params]);
}

/// Every analytics event name the app emits. These names are a contract with
/// the analytics dashboards and must not be renamed.
abstract final class AnalyticsEvents {
  static const amenTestimony = 'amen_testimony';
  static const bibleSeriesViewed = 'bible_series_viewed';
  static const dailyEngagementNotificationClicked =
      'daily_engagement_notification_clicked';
  static const engagementCompleted = 'engagement_completed';
  static const engagementViewed = 'engagement_viewed';
  static const prayerRequestAnswered = 'prayer_request_answered';
  static const prayerRequestCreated = 'prayer_request_created';
  static const prayerRequestDeleted = 'prayer_request_deleted';
  static const prayerRequestPrayed = 'prayer_request_prayed';
  static const prayerRequestReported = 'prayer_request_reported';
  static const testimonyAnswered = 'testimony_answered';
  static const testimonyCreated = 'testimony_created';
  static const testimonyDeleted = 'testimony_deleted';
  static const testimonyReported = 'testimony_reported';

  /// `<notificationType>_notification_clicked` for forum notifications.
  static String notificationClicked(String notificationType) =>
      '${notificationType}_notification_clicked';
}
