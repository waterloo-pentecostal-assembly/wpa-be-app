import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/injection.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/notification_settings/entities.dart';
import '../../domain/notification_settings/exceptions.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_messaging_service.dart';
import 'notification_settings_dto.dart';

class NotificationSettingsService implements INotificationSettingsService {
  // ignore: unused_field
  final FirebaseMessagingService _firebaseMessagingService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseFirestore _firestore;
  String notificationSettingsId;

  NotificationSettingsService(this._firebaseMessagingService, this._firestore,
      this._firebaseFirestoreService);

  @override
  Future<void> subscribeToDailyEngagementReminder() async {
    _setNotificationSetting({"daily_engagement_reminder": true});
  }

  @override
  Future<void> unsubscribeFromDailyEngagementReminder() async {
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

  Future<void> _setNotificationSetting(
      Map<String, dynamic> notificationSetting) async {
    final LocalUser user = getIt<LocalUser>();

    // Should always be available.  This is just a fail-safe
    String _notificationSettingsId =
        notificationSettingsId ?? _getNotificationSettingsId();

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
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
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
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
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
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
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
