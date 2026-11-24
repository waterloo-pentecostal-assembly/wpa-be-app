/// Analytics sink. The Firebase implementation lives in infrastructure.
abstract class IAnalytics {
  Future<void> log(String name, [Map<String, Object>? params]);
}

/// Every analytics event name the app emits. These names are a contract with
/// the analytics dashboards and must not be renamed.
abstract final class AnalyticsEvents {
  static const amenTestimony = 'amen_testimony';
  static const bibleSeriesViewed = 'bible_series_viewed';
  static const challengeGroupCreated = 'challenge_group_created';
  static const challengeGroupDeletedByAdmin =
      'challenge_group_deleted_by_admin';
  static const challengeGroupDeletedByOwner =
      'challenge_group_deleted_by_owner';
  static const challengeGroupEdited = 'challenge_group_edited';
  static const challengeGroupInviteAccepted = 'challenge_group_invite_accepted';
  static const challengeGroupInviteDeclined = 'challenge_group_invite_declined';
  static const challengeGroupInvitesSent = 'challenge_group_invites_sent';
  static const challengeGroupJoinedPublic = 'challenge_group_joined_public';
  static const challengeGroupJoinedWithCode =
      'challenge_group_joined_with_code';
  static const challengeGroupLeft = 'challenge_group_left';
  static const challengeGroupMemberNudged = 'challenge_group_member_nudged';
  static const challengeGroupMemberRemoved = 'challenge_group_member_removed';
  static const challengeGroupOwnerAdded = 'challenge_group_owner_added';
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
