import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/notification_settings/entities.dart';
import '../../domain/notification_settings/exceptions.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../common/helpers.dart';

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
  NotificationSettingsService(
    this._firestore,
    this._firebaseFirestoreService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final ISession _session;

  CollectionReference<Map<String, dynamic>> _settings() => _firestore
      .collection('users')
      .doc(_session.requireUser().id)
      .collection('notification_settings');

  Future<DocumentSnapshot<Map<String, dynamic>>> _settingsDoc() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _settings().get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (snapshot.docs.isEmpty) {
      throw const NotificationSettingsException(
        code: NotificationSettingsExceptionCode.noNotificationSettings,
        message: 'No notification settings exist',
      );
    }
    return snapshot.docs.first;
  }

  Future<void> _update(Map<String, dynamic> data) async {
    final doc = await _settingsDoc();
    try {
      await _firestore.runTransaction((transaction) async {
        transaction.update(doc.reference, data);
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async {
    final doc = await _settingsDoc();
    final data = doc.data() ?? {};
    bool flag(NotificationSetting s) =>
        findOrDefaultTo(data, kNotificationSettingFields[s], false);
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
      threadsFollowed: toStringList(data['threads_followed']),
    );
  }

  // FCM topic (un)subscription is done by Cloud Functions reacting to these
  // flags (the Dart SDK cannot manage topics across a user's devices).
  @override
  Future<void> setSetting(NotificationSetting setting, bool enabled) =>
      _update({kNotificationSettingFields[setting]!: enabled});

  @override
  Future<void> followThread(String threadId) => _update({
        'threads_followed': FieldValue.arrayUnion([threadId]),
      });

  @override
  Future<void> unfollowThread(String threadId) => _update({
        'threads_followed': FieldValue.arrayRemove([threadId]),
      });
}
