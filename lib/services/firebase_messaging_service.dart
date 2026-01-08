import 'dart:async';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/navigation_bar/navigation_bar_bloc.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `await Firebase.initializeApp();` here.
  print("Handling a background message: ${message.messageId}");
}

class FirebaseMessagingService {
  late final FirebaseMessaging _firebaseMessaging;
  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get foregroundMessageStream =>
      _foregroundMessageController.stream;

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

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    String? token = await _firebaseMessaging.getToken();
    print("FirebaseMessaging token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _foregroundMessageController.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigationHandler(message.data);
    });
  }

  static void navigationHandler(Map<String, dynamic> payload) async {
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
    } else if (payload['notificationType'] == 'testimonyPraised') {
      getIt<NavigationBarBloc>()
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.ENGAGE,
            route: '/testimonies/mine',
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
    } else if (['newThread', 'newComment', 'likeComment']
        .contains(payload['notificationType'])) {
      getIt<FirebaseAnalytics>().logEvent(
          name: '${payload['notificationType']}_notification_clicked');
      getIt<NavigationBarBloc>()
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.ENGAGE,
            route: '/thread_detail',
            arguments: {
              'threadId': payload['threadId'],
              'forumId': payload['forumId'],
              'title': payload['title'] ?? 'Thread',
              'focusCommentId': payload['commentId'],
            },
          ),
        );
    } else if (payload['notificationType'] == 'link') {
      Uri uri = Uri.parse(payload['link']);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
