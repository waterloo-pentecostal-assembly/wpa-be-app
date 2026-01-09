import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/injection.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/notification_settings/entities.dart';
import '../../domain/notification_settings/exceptions.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import 'notification_settings_dto.dart';

class NotificationSettingsService implements INotificationSettingsService {
  late final FirebaseFirestoreService _firebaseFirestoreService;
  late final FirebaseFirestore _firestore;
  late String? notificationSettingsId;

  NotificationSettingsService(this._firestore, this._firebaseFirestoreService);

  @override
  Future<void> subscribeToDailyEngagementReminder() async {
    // FCM topic subscription handled by Firebase Functions
    // This is done to handle multiple device tokens which is not
    // possible with the dart SDK.
    _setNotificationSetting({"daily_engagement_reminder": true});
  }

  @override
  Future<void> unsubscribeFromDailyEngagementReminder() async {
    // FCM topic unsubscription handled by Firebase Functions
    // This is done to handle multiple device tokens which is not
    // possible with the dart SDK.
    _setNotificationSetting({"daily_engagement_reminder": false});
  }

  @override
  Future<void> subscribeToPrayerNotifications() async {
    _setNotificationSetting({"prayers": true});
  }

  @override
  Future<void> unsubscribeFromPrayerNotifications() async {
    _setNotificationSetting({"prayers": false});
  }

  @override
  Future<void> subscribeToTestimonyNotifications() async {
    _setNotificationSetting({"testimonies": true});
  }

  @override
  Future<void> unsubscribeFromTestimonyNotifications() async {
    _setNotificationSetting({"testimonies": false});
  }

  @override
  Future<void> subscribeToForumThreads() async {
    _setNotificationSetting({"forum_threads": true});
  }

  @override
  Future<void> unsubscribeFromForumThreads() async {
    _setNotificationSetting({"forum_threads": false});
  }

  @override
  Future<void> subscribeToForumCommentReplies() async {
    _setNotificationSetting({"forum_comment_replies": true});
  }

  @override
  Future<void> unsubscribeFromForumCommentReplies() async {
    _setNotificationSetting({"forum_comment_replies": false});
  }

  @override
  Future<void> subscribeToForumThreadComments() async {
    _setNotificationSetting({"forum_thread_comments": true});
  }

  @override
  Future<void> unsubscribeFromForumThreadComments() async {
    _setNotificationSetting({"forum_thread_comments": false});
  }

  @override
  Future<void> subscribeToForumCommentLikes() async {
    _setNotificationSetting({"forum_comment_likes": true});
  }

  @override
  Future<void> unsubscribeFromForumCommentLikes() async {
    _setNotificationSetting({"forum_comment_likes": false});
  }

  @override
  Future<void> followThread(String threadId) async {
    _setNotificationSetting({
      "threads_followed": FieldValue.arrayUnion([threadId])
    });
  }

  @override
  Future<void> unfollowThread(String threadId) async {
    _setNotificationSetting({
      "threads_followed": FieldValue.arrayRemove([threadId])
    });
  }

  Future<void> _setNotificationSetting(
      Map<String, dynamic> notificationSetting) async {
    final LocalUser user = getIt<LocalUser>();

    // Should always be available.  This is just a fail-safe
    String _notificationSettingsId =
        notificationSettingsId ?? await _getNotificationSettingsId();

    try {
      // Update flag in users/<user-doc>/notification_settings/<single-notification-settings-doc>
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _firestore
            .collection("users")
            .doc(user.id)
            .collection("notification_settings")
            .doc(_notificationSettingsId);
        transaction.update(documentReference, notificationSetting);
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;
    try {
      querySnapshot = await _firestore
          .collection("users")
          .doc(user.id)
          .collection("notification_settings")
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length > 0) {
      DocumentSnapshot notificationSettingsDoc = querySnapshot.docs[0];

      // Set notificationSettingsId
      notificationSettingsId = notificationSettingsDoc.id;

      return NotificationSettingsDto.fromFirestore(notificationSettingsDoc)
          .toDomain();
    }
    throw NotificationSettingsException(
      code: NotificationSettingsExceptionCode.NO_NOTIFICATION_SETTINGS,
      message: "No notification settings exist",
    );
  }

  Future<String> _getNotificationSettingsId() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;
    try {
      querySnapshot = await _firestore
          .collection("users")
          .doc(user.id)
          .collection("notification_settings")
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length > 0) {
      DocumentSnapshot notificationSettingsDoc = querySnapshot.docs[0];

      // Set notificationSettingsId
      notificationSettingsId = notificationSettingsDoc.id;

      return notificationSettingsDoc.id;
    }
    throw NotificationSettingsException(
      code: NotificationSettingsExceptionCode.NO_NOTIFICATION_SETTINGS,
      message: "No notification settings exist",
    );
  }
}
