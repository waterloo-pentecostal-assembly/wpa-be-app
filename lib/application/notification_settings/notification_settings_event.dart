part of 'notification_settings_bloc.dart';

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object> get props => [];
}

class NotificationSettingsRequested extends NotificationSettingsEvent {
  NotificationSettingsRequested();

  @override
  List<Object> get props => [];
}

class SubscribedToDailyEngagementReminder extends NotificationSettingsEvent {
  SubscribedToDailyEngagementReminder();

  @override
  List<Object> get props => [];
}

class UnsubscribedFromDailyEngagementReminder
    extends NotificationSettingsEvent {
  UnsubscribedFromDailyEngagementReminder();

  @override
  List<Object> get props => [];
}

class SubscribedToPrayerNotifications extends NotificationSettingsEvent {
  SubscribedToPrayerNotifications();

  @override
  List<Object> get props => [];
}

class UnsubscribedFromPrayerNotifications extends NotificationSettingsEvent {
  UnsubscribedFromPrayerNotifications();

  @override
  List<Object> get props => [];
}

class SubscribedToNewPrayerRequests extends NotificationSettingsEvent {
  SubscribedToNewPrayerRequests();
  @override
  List<Object> get props => [];
}

class UnsubscribedFromNewPrayerRequests extends NotificationSettingsEvent {
  UnsubscribedFromNewPrayerRequests();
  @override
  List<Object> get props => [];
}

class SubscribedToTestimonyNotifications extends NotificationSettingsEvent {
  SubscribedToTestimonyNotifications();

  @override
  List<Object> get props => [];
}

class UnsubscribedFromTestimonyNotifications extends NotificationSettingsEvent {
  UnsubscribedFromTestimonyNotifications();

  @override
  List<Object> get props => [];
}

class SubscribedToNewTestimonies extends NotificationSettingsEvent {
  SubscribedToNewTestimonies();
  @override
  List<Object> get props => [];
}

class UnsubscribedFromNewTestimonies extends NotificationSettingsEvent {
  UnsubscribedFromNewTestimonies();
  @override
  List<Object> get props => [];
}

class SubscribedToNewForumThreads extends NotificationSettingsEvent {
  SubscribedToNewForumThreads();
  @override
  List<Object> get props => [];
}

class UnsubscribedFromNewForumThreads extends NotificationSettingsEvent {
  UnsubscribedFromNewForumThreads();
  @override
  List<Object> get props => [];
}

class SubscribedToForumCommentReplies extends NotificationSettingsEvent {
  SubscribedToForumCommentReplies();
  @override
  List<Object> get props => [];
}

class UnsubscribedFromForumCommentReplies extends NotificationSettingsEvent {
  UnsubscribedFromForumCommentReplies();
  @override
  List<Object> get props => [];
}

class SubscribedToForumCommentLikes extends NotificationSettingsEvent {
  SubscribedToForumCommentLikes();
  @override
  List<Object> get props => [];
}

class UnsubscribedFromForumCommentLikes extends NotificationSettingsEvent {
  UnsubscribedFromForumCommentLikes();
  @override
  List<Object> get props => [];
}

class SubscribedToForumThreadComments extends NotificationSettingsEvent {
  SubscribedToForumThreadComments();
  @override
  List<Object> get props => [];
}

class UnsubscribedFromForumThreadComments extends NotificationSettingsEvent {
  UnsubscribedFromForumThreadComments();
  @override
  List<Object> get props => [];
}

class ThreadFollowed extends NotificationSettingsEvent {
  final String threadId;
  ThreadFollowed(this.threadId);
  @override
  List<Object> get props => [threadId];
}

class ThreadUnfollowed extends NotificationSettingsEvent {
  final String threadId;
  ThreadUnfollowed(this.threadId);
  @override
  List<Object> get props => [threadId];
}
