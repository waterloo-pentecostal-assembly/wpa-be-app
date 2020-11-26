import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '../../constants.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/notification_settings/entities.dart';
import '../../domain/notification_settings/exceptions.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../../injection.dart';
import '../common/helpers.dart';
import '../../services/firebase_messaging_service.dart';
import 'notification_settings_dto.dart';

class NotificationSettingsService implements INotificationSettingsService {
  final FirebaseMessagingService _firebaseMessagingService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseFirestore _firestore;

  NotificationSettingsService(this._firebaseMessagingService, this._firestore, this._firebaseFirestoreService);

  @override
  Future<void> subscribeToDailyEngagementReminder(String notificationSettingsId) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      // Add subscription to FirebaseMessaging
      await _firebaseMessagingService.subscribeToTopic(kDailyEngagementReminderTopic);
    } catch (e) {
      throw NotificationSettingsException(
        code: NotificationSettingsExceptionCode.UNABLE_TO_SUBSCRIBE,
        message: "Unable to subscribe to daily engagement reminders",
        details: e,
      );
    }

    try {
      // Update flag in users/<user-doc>/notification_settings/<single-notification-settings-doc>
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference =
            _firestore.collection("users").doc(user.id).collection("notification_settings").doc(notificationSettingsId);
        transaction.update(documentReference, {"daily_engagement_reminder": true});
      });
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> unsubscribeFromDailyEngagementReminder(String notificationSettingsId) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();

    try {
      // Remove subscription from FirebaseMessaging
      await _firebaseMessagingService.unsubscribeFromTopic(kDailyEngagementReminderTopic);
    } catch (e) {
      throw NotificationSettingsException(
        code: NotificationSettingsExceptionCode.UNABLE_TO_UNSUBSCRIBE,
        message: "Unable to unsubscribe from daily engagement reminders",
        details: e,
      );
    }

    try {
      // Update flag in users/<user-doc>/notification_settings/<single-notification-settings-doc>
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference =
            _firestore.collection("users").doc(user.id).collection("notification_settings").doc(notificationSettingsId);
        transaction.update(documentReference, {"daily_engagement_reminder": false});
      });
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    QuerySnapshot querySnapshot;
    try {
      querySnapshot = await _firestore.collection("users").doc(user.id).collection("notification_settings").get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length > 0) {
      DocumentSnapshot notificationSettingsDoc = querySnapshot.docs[0];
      return NotificationSettingsDto.fromFirestore(notificationSettingsDoc).toDomain();
    }
    throw NotificationSettingsException(
      code: NotificationSettingsExceptionCode.NO_NOTIFICATION_SETTINGS,
      message: "No notification settings exist",
    );
  }
}
