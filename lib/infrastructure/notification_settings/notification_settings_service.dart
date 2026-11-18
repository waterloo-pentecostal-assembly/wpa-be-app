import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/notification_settings/entities.dart';
import '../../domain/notification_settings/exceptions.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../common/firestore_data.dart';

/// Firestore field name for each [NotificationSetting].
const Map<NotificationSetting, String> kNotificationSettingFields = {
  NotificationSetting.dailyEngagementReminder: 'daily_engagement_reminder',
  NotificationSetting.prayers: 'prayers',
  NotificationSetting.newPrayerRequest: 'new_prayer_request',
  NotificationSetting.testimonies: 'testimonies',
  NotificationSetting.newTestimony: 'new_testimony',
  NotificationSetting.newForumThread: 'new_forum_thread',
  NotificationSetting.forumCommentReplies: 'forum_comment_replies',
  NotificationSetting.forumThreadComments: 'forum_thread_comments',
  NotificationSetting.forumCommentLikes: 'forum_comment_likes',
};

/// Stateless: the settings document id is looked up for each write.
class NotificationSettingsService implements INotificationSettingsService {
  NotificationSettingsService(this._firestore, this._session);

  final FirebaseFirestore _firestore;
  final ISession _session;

  CollectionReference<Map<String, dynamic>> _settings() => _firestore
      .collection('users')
      .doc(_session.requireUser().id)
      .collection('notification_settings');

  Future<DocumentSnapshot<Map<String, dynamic>>> _settingsDoc() async {
    final settings = _settings();
    final snapshot = await settings.get();
    if (snapshot.docs.isEmpty) {
      throw const NotificationSettingsException(
        code: NotificationSettingsExceptionCode.noNotificationSettings,
        message: 'No notification settings exist',
      );
    }
    return snapshot.docs.first;
  }

  /// A plain update (no transaction needed: nothing is read first), so it
  /// also queues while offline.
  Future<void> _update(Map<String, dynamic> data) async {
    final doc = await _settingsDoc();
    await doc.reference.update(data);
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async {
    final doc = await _settingsDoc();
    final data = dataOf(doc);
    bool flag(NotificationSetting s) =>
        data.optional(kNotificationSettingFields[s]!, false);
    return NotificationSettingsEntity(
      id: doc.id,
      dailyEngagementReminder:
          flag(NotificationSetting.dailyEngagementReminder),
      prayers: flag(NotificationSetting.prayers),
      newPrayerRequest: flag(NotificationSetting.newPrayerRequest),
      testimonies: flag(NotificationSetting.testimonies),
      newTestimony: flag(NotificationSetting.newTestimony),
      newForumThread: flag(NotificationSetting.newForumThread),
      forumCommentReplies: flag(NotificationSetting.forumCommentReplies),
      forumThreadComments: flag(NotificationSetting.forumThreadComments),
      forumCommentLikes: flag(NotificationSetting.forumCommentLikes),
      threadsFollowed: data.stringList('threads_followed'),
    );
  }

  // FCM topic (un)subscription is done by Cloud Functions reacting to these
  // flags (the Dart SDK cannot manage topics across a user's devices).
  @override
  Future<void> setSetting(NotificationSetting setting, bool enabled) async =>
      _update({kNotificationSettingFields[setting]!: enabled});

  @override
  Future<void> followThread(String threadId) async => _update({
        'threads_followed': FieldValue.arrayUnion([threadId]),
      });

  @override
  Future<void> unfollowThread(String threadId) async => _update({
        'threads_followed': FieldValue.arrayRemove([threadId]),
      });
}
