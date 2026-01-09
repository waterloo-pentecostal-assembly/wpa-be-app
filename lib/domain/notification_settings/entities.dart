class NotificationSettingsEntity {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool testimonies;
  final bool forumThreads;
  final bool forumCommentReplies;
  final bool forumThreadComments;
  final bool forumCommentLikes;
  final List<String> threadsFollowed;

  NotificationSettingsEntity({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
    required this.testimonies,
    required this.forumThreads,
    required this.forumCommentReplies,
    required this.forumThreadComments,
    required this.forumCommentLikes,
    required this.threadsFollowed,
  });
  NotificationSettingsEntity copyWith({
    String? id,
    bool? dailyEngagementReminder,
    bool? prayers,
    bool? testimonies,
    bool? forumThreads,
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
      testimonies: testimonies ?? this.testimonies,
      forumThreads: forumThreads ?? this.forumThreads,
      forumCommentReplies: forumCommentReplies ?? this.forumCommentReplies,
      forumThreadComments: forumThreadComments ?? this.forumThreadComments,
      forumCommentLikes: forumCommentLikes ?? this.forumCommentLikes,
      threadsFollowed: threadsFollowed ?? this.threadsFollowed,
    );
  }
}
