import 'package:equatable/equatable.dart';

/// Individually toggleable notification preferences.
enum NotificationSetting {
  dailyEngagementReminder,
  prayers,
  newPrayerRequest,
  testimonies,
  newTestimony,
  newForumThread,
  forumCommentReplies,
  forumThreadComments,
  forumCommentLikes,
}

class NotificationSettingsEntity extends Equatable {
  const NotificationSettingsEntity({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
    required this.newPrayerRequest,
    required this.testimonies,
    required this.newTestimony,
    required this.newForumThread,
    required this.forumCommentReplies,
    required this.forumThreadComments,
    required this.forumCommentLikes,
    required this.threadsFollowed,
  });

  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool newPrayerRequest;
  final bool testimonies;
  final bool newTestimony;
  final bool newForumThread;
  final bool forumCommentReplies;
  final bool forumThreadComments;
  final bool forumCommentLikes;
  final List<String> threadsFollowed;

  bool valueOf(NotificationSetting setting) => switch (setting) {
        NotificationSetting.dailyEngagementReminder => dailyEngagementReminder,
        NotificationSetting.prayers => prayers,
        NotificationSetting.newPrayerRequest => newPrayerRequest,
        NotificationSetting.testimonies => testimonies,
        NotificationSetting.newTestimony => newTestimony,
        NotificationSetting.newForumThread => newForumThread,
        NotificationSetting.forumCommentReplies => forumCommentReplies,
        NotificationSetting.forumThreadComments => forumThreadComments,
        NotificationSetting.forumCommentLikes => forumCommentLikes,
      };

  NotificationSettingsEntity withSetting(NotificationSetting s, bool v) =>
      copyWith(
        dailyEngagementReminder:
            s == NotificationSetting.dailyEngagementReminder ? v : null,
        prayers: s == NotificationSetting.prayers ? v : null,
        newPrayerRequest: s == NotificationSetting.newPrayerRequest ? v : null,
        testimonies: s == NotificationSetting.testimonies ? v : null,
        newTestimony: s == NotificationSetting.newTestimony ? v : null,
        newForumThread: s == NotificationSetting.newForumThread ? v : null,
        forumCommentReplies:
            s == NotificationSetting.forumCommentReplies ? v : null,
        forumThreadComments:
            s == NotificationSetting.forumThreadComments ? v : null,
        forumCommentLikes:
            s == NotificationSetting.forumCommentLikes ? v : null,
      );

  NotificationSettingsEntity copyWith({
    bool? dailyEngagementReminder,
    bool? prayers,
    bool? newPrayerRequest,
    bool? testimonies,
    bool? newTestimony,
    bool? newForumThread,
    bool? forumCommentReplies,
    bool? forumThreadComments,
    bool? forumCommentLikes,
    List<String>? threadsFollowed,
  }) {
    return NotificationSettingsEntity(
      id: id,
      dailyEngagementReminder:
          dailyEngagementReminder ?? this.dailyEngagementReminder,
      prayers: prayers ?? this.prayers,
      newPrayerRequest: newPrayerRequest ?? this.newPrayerRequest,
      testimonies: testimonies ?? this.testimonies,
      newTestimony: newTestimony ?? this.newTestimony,
      newForumThread: newForumThread ?? this.newForumThread,
      forumCommentReplies: forumCommentReplies ?? this.forumCommentReplies,
      forumThreadComments: forumThreadComments ?? this.forumThreadComments,
      forumCommentLikes: forumCommentLikes ?? this.forumCommentLikes,
      threadsFollowed: threadsFollowed ?? this.threadsFollowed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dailyEngagementReminder,
        prayers,
        newPrayerRequest,
        testimonies,
        newTestimony,
        newForumThread,
        forumCommentReplies,
        forumThreadComments,
        forumCommentLikes,
        threadsFollowed,
      ];
}
