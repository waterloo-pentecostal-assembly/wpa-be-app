import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging;

  FirebaseMessagingService(this._firebaseMessaging);

  Future<String> getToken() async {
    return _firebaseMessaging.getToken();
  }

  String getPlatform() {
    return Platform.operatingSystem;
  }

  Future<void> subscribeToTopic(topic) {
    return _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(topic) {
    return _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<void> initialize() async {
    if (Platform.isIOS) {
      _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings());
    }

    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    // https://console.firebase.google.com/project/YOUR_PROJECT_ID/notification/compose
    String token = await _firebaseMessaging.getToken();
    print("FirebaseMessaging token: $token");

    _firebaseMessaging.configure(
      //when the app is running in the foreground and the notification is clicked
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      //when clicking on a notification and the application is not running at all
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      //when clicking on a notification and the application is running in the background
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
  }
}