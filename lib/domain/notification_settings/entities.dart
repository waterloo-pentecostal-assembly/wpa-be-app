class NotificationSettingsEntity {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool testimonies;
  final bool forumThreads;
  final bool forumComments;
  final bool forumLikes;

  NotificationSettingsEntity({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
    required this.testimonies,
    required this.forumThreads,
    required this.forumComments,
    required this.forumLikes,
  });
}
