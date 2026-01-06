import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/notification_settings/entities.dart';
import '../common/helpers.dart';

class NotificationSettingsDto {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;
  final bool testimonies;
  final bool forumThreads;
  final bool forumComments;
  final bool forumLikes;

  factory NotificationSettingsDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    return NotificationSettingsDto._(
      id: doc.id,
      dailyEngagementReminder:
          findOrDefaultTo(data, 'daily_engagement_reminder', false),
      prayers: findOrDefaultTo(data, 'prayers', false),
      testimonies: findOrDefaultTo(data, 'testimonies', false),
      forumThreads: findOrDefaultTo(data, 'forum_threads', false),
      forumComments: findOrDefaultTo(data, 'forum_comments', false),
      forumLikes: findOrDefaultTo(data, 'forum_likes', false),
    );
  }

  NotificationSettingsDto._({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
    required this.testimonies,
    required this.forumThreads,
    required this.forumComments,
    required this.forumLikes,
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
      forumComments: this.forumComments,
      forumLikes: this.forumLikes,
    );
  }
}
