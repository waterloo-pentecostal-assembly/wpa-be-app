import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are displayed by the OS; nothing to do here. If other
  // Firebase services are needed, call `await Firebase.initializeApp()` first.
}

/// Push-notification plumbing. Routing of notification taps is done by the
/// app router's deep-link mapper (`lib/app/router/deep_links.dart`).
class FirebaseMessagingService {
  FirebaseMessagingService(this._firebaseMessaging);

  final FirebaseMessaging _firebaseMessaging;
  final _foreground = StreamController<RemoteMessage>.broadcast();
  final _opened = StreamController<RemoteMessage>.broadcast();
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  /// Messages received while the app is in the foreground.
  Stream<RemoteMessage> get foregroundMessageStream => _foreground.stream;

  /// Notifications tapped while the app was in the background.
  Stream<RemoteMessage> get openedMessageStream => _opened.stream;

  Future<String?> getToken() => _firebaseMessaging.getToken();

  /// Platform name as stored on device documents (`ios`, `android`, ...).
  /// Matches the values previously produced by `Platform.operatingSystem`.
  String getPlatform() => defaultTargetPlatform.name.toLowerCase();

  /// The notification that launched the app from a terminated state, if any.
  Future<RemoteMessage?> getInitialMessage() =>
      _firebaseMessaging.getInitialMessage();

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // iOS only: foreground notifications are shown by the in-app banner.
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen(_foreground.add);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_opened.add);
  }
}
