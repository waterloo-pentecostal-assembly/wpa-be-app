class NotificationSettingsEntity {
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

  NotificationSettingsEntity({
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

  NotificationSettingsEntity copyWith({
    String? id,
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
      id: id ?? this.id,
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
}
