import 'entities.dart';

abstract class INotificationSettingsService {
  // Future<void> unsubscribeFromDailyEngagementReminder(String notificationSettingsId);
  // Future<void> subscribeToDailyEngagementReminder(String notificationSettingsId);
  Future<void> subscribeToDailyEngagementReminder();
  Future<void> unsubscribeFromDailyEngagementReminder();
  Future<void> subscribeToPrayerNotifications();
  Future<void> unsubscribeFromPrayerNotifications();
  Future<void> subscribeToNewPrayerRequests();
  Future<void> unsubscribeFromNewPrayerRequests();
  Future<void> subscribeToTestimonyNotifications();
  Future<void> unsubscribeFromTestimonyNotifications();
  Future<void> subscribeToNewTestimonies();
  Future<void> unsubscribeFromNewTestimonies();
  Future<void> subscribeToNewForumThreads();
  Future<void> unsubscribeFromNewForumThreads();
  Future<void> subscribeToForumCommentReplies();
  Future<void> unsubscribeFromForumCommentReplies();
  Future<void> subscribeToForumThreadComments();
  Future<void> unsubscribeFromForumThreadComments();
  Future<void> subscribeToForumCommentLikes();
  Future<void> unsubscribeFromForumCommentLikes();
  Future<void> followThread(String threadId);
  Future<void> unfollowThread(String threadId);
  Future<NotificationSettingsEntity> getNotificationSettings();
}
