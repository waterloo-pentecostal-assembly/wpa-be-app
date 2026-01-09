import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/notification_settings/entities.dart';
import '../common/helpers.dart';

class NotificationSettingsDto {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool testimonies;
  final bool forumThreads;
  final bool forumCommentReplies;
  final bool forumThreadComments;
  final bool forumLikes;
  final List<String> threadsFollowed;

  factory NotificationSettingsDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    return NotificationSettingsDto._(
      id: doc.id,
      dailyEngagementReminder:
          findOrDefaultTo(data, 'daily_engagement_reminder', false),
      prayers: findOrDefaultTo(data, 'prayers', false),
      testimonies: findOrDefaultTo(data, 'testimonies', false),
      forumThreads: findOrDefaultTo(data, 'forum_threads', false),
      forumCommentReplies:
          findOrDefaultTo(data, 'forum_comment_replies', false),
      forumThreadComments:
          findOrDefaultTo(data, 'forum_thread_comments', false),
      forumLikes: findOrDefaultTo(data, 'forum_likes', false),
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
    required this.testimonies,
    required this.forumThreads,
    required this.forumCommentReplies,
    required this.forumThreadComments,
    required this.forumLikes,
    required this.threadsFollowed,
  });
}

extension NotificationSettingsDtoX on NotificationSettingsDto {
  NotificationSettingsEntity toDomain() {
    return NotificationSettingsEntity(
      id: this.id,
      dailyEngagementReminder: this.dailyEngagementReminder,
      prayers: this.prayers,
      testimonies: this.testimonies,
      forumThreads: this.forumThreads,
      forumCommentReplies: this.forumCommentReplies,
      forumThreadComments: this.forumThreadComments,
      forumLikes: this.forumLikes,
      threadsFollowed: this.threadsFollowed,
    );
  }
}
