import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/notification_settings/entities.dart';
import '../common/helpers.dart';

class NotificationSettingsDto {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool testimonies;
  final bool newPrayerRequest;
  final bool newTestimony;
  final bool newForumThread;
  final bool forumCommentReplies;
  final bool forumThreadComments;
  final bool forumCommentLikes;
  final List<String> threadsFollowed;

  factory NotificationSettingsDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    return NotificationSettingsDto._(
      id: doc.id,
      dailyEngagementReminder:
          findOrDefaultTo(data, 'daily_engagement_reminder', false),
      prayers: findOrDefaultTo(data, 'prayers', false),
      newPrayerRequest: findOrDefaultTo(data, 'new_prayer_request', false),
      testimonies: findOrDefaultTo(data, 'testimonies', false),
      newTestimony: findOrDefaultTo(data, 'new_testimony', false),
      newForumThread: findOrDefaultTo(data, 'new_forum_thread', false),
      forumCommentReplies:
          findOrDefaultTo(data, 'forum_comment_replies', false),
      forumThreadComments:
          findOrDefaultTo(data, 'forum_thread_comments', false),
      forumCommentLikes: findOrDefaultTo(data, 'forum_comment_likes', false),
      threadsFollowed:
          (findOrDefaultTo(data, 'threads_followed', <String>[]) as List)
              .map((e) => e as String)
              .toList(),
    );
  }

  NotificationSettingsDto._({
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
}

extension NotificationSettingsDtoX on NotificationSettingsDto {
  NotificationSettingsEntity toDomain() {
    return NotificationSettingsEntity(
      id: this.id,
      dailyEngagementReminder: this.dailyEngagementReminder,
      prayers: this.prayers,
      newPrayerRequest: this.newPrayerRequest,
      testimonies: this.testimonies,
      newTestimony: this.newTestimony,
      newForumThread: this.newForumThread,
      forumCommentReplies: this.forumCommentReplies,
      forumThreadComments: this.forumThreadComments,
      forumCommentLikes: this.forumCommentLikes,
      threadsFollowed: this.threadsFollowed,
    );
  }
}
