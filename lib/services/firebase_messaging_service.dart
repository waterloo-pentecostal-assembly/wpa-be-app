import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/navigation_bar/navigation_bar_bloc.dart';

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
      _firebaseMessaging
          .requestNotificationPermissions(IosNotificationSettings());
    }

    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    // String token = await _firebaseMessaging.getToken();
    // print("FirebaseMessaging token: $token");
    //Future.delayed(Duration(seconds: 1), () {
    _firebaseMessaging.configure(
      //when the app is running in the foreground and the notification is clicked
      onMessage: onMessageHanlder,

      //when clicking on a notification and the application is not running at all
      onLaunch: onLaunchHanlder,

      //when clicking on a notification and the application is running in the background
      onResume: onResumehHanlder,

      //Not needed for now, causes error
      //onBackgroundMessage: onBackgroundMessageHandler,
    );
    // });
  }

  Future onMessageHanlder(Map<String, dynamic> message) async {
    print("onMessage");
    // String _message;
    // TODO: we may need to handle the message by platform.
    // if (Platform.isIOS) {
    //   //hanle ios
    // } else {
    //   // handle android
    // }
    // GlobalKey<NavigatorState> navigatorKey = GlobalKey();
    // navigatorKey.currentState.push(
    //     MaterialPageRoute(builder: (_) => PrayerRequestsPage(tabIndex: 0)));
  }

  Future onLaunchHanlder(Map<String, dynamic> message) async {
    if (message.containsKey("data")) {
      if (message['data']['notificationType'] == 'dailyEngagementReminder') {
        getIt<NavigationBarBloc>()
          ..add(
            NavigationBarEvent(
                tab: NavigationTabEnum.ENGAGE,
                route: '/bible_series',
                argument: message['data']['bibleSeriesId']),
          );
      } else if (message['data']['notificationType'] == 'prayerRequestPrayed') {
        getIt<NavigationBarBloc>()
          ..add(
            NavigationBarEvent(
                tab: NavigationTabEnum.ENGAGE, route: '/prayer_requests/mine'),
          );
      }
    }
  }

  Future onResumehHanlder(Map<String, dynamic> message) async {
    if (message.containsKey("data")) {
      if (message['data']['notificationType'] == 'dailyEngagementReminder') {
        getIt<NavigationBarBloc>()
          ..add(
            NavigationBarEvent(
                tab: NavigationTabEnum.ENGAGE,
                route: '/bible_series',
                argument: message['data']['bibleSeriesId']),
          );
      } else if (message['data']['notificationType'] == 'prayerRequestPrayed') {
        getIt<NavigationBarBloc>()
          ..add(
            NavigationBarEvent(
                tab: NavigationTabEnum.ENGAGE, route: '/prayer_requests/mine'),
          );
      }
    }
  }

  Future onBackgroundMessageHandler(Map<String, dynamic> message) async {
    // Note: the protocol of data and notification are in line with the fields defined by a RemoteMessage.
    // https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/RemoteMessage
    print("background");
    // if (message.containsKey('data')) {
    //   // Handle data message
    //   final dynamic data = message['data'];
    //   print("backgroundMessageHandler data: $data");
    // }

    // if (message.containsKey('notification')) {
    //   // Handle notification message
    //   final dynamic notification = message['notification'];
    //   print("backgroundMessageHandler data: $notification");
    // }

    // Or do other work.
  }
}
