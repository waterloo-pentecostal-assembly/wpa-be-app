import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/navigation_bar/navigation_bar_bloc.dart';

class FirebaseMessagingService {
  late final FirebaseMessaging _firebaseMessaging;

  FirebaseMessagingService(this._firebaseMessaging);

  Future<String?> getToken() async {
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
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    // String token = await _firebaseMessaging.getToken();
    // print("FirebaseMessaging token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print('onMessage.listen: $message');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigationHandler(message.data);
    });
  }

  void navigationHandler(Map<String, dynamic> payload) async {
    if (payload['notificationType'] == 'dailyEngagementReminder') {
      getIt<FirebaseAnalytics>()
          .logEvent(name: 'daily_engagement_notification_clicked');
      getIt<NavigationBarBloc>()
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.ENGAGE,
            route: '/bible_series',
            arguments: {
              'bibleSeriesId': payload['bibleSeriesId'],
            },
          ),
        );
    } else if (payload['notificationType'] == 'prayerRequestPrayed') {
      getIt<NavigationBarBloc>()
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.ENGAGE,
            route: '/prayer_requests/mine',
          ),
        );
    } else if (payload['notificationType'] == 'userSignUp') {
      getIt<NavigationBarBloc>()
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.ADMIN,
            route: '/user_verification',
          ),
        );
    } else if (payload['notificationType'] == 'newPrayerRequest') {
      getIt<NavigationBarBloc>()
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.ADMIN,
            route: '/prayer_request_approval',
          ),
        );
    } else if (payload['notificationType'] == 'link') {
      if (await canLaunch(payload['link'])) {
        await launch(payload['link']);
      }
    }
  }
}
