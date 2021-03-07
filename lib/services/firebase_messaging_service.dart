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
      _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings());
    }

    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    // String token = await _firebaseMessaging.getToken();
    // print("FirebaseMessaging token: $token");
    
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
  }

  Future onMessageHanlder(Map<String, dynamic> message) async {
    print("onMessage: $message");
    /*
      We would have to handle ios and android differently here. For exampple:
      if(message.isNotEmpty) {
          var messageData;
          bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
          if(isIOS) { //ios
            messageData = message;
          } else { //android
            messageData = message['data'];
          }
          processClickOnNotification(messageData);
        }
     */
  }

  Future onLaunchHanlder(Map<String, dynamic> message) async {
    print("onLaunch: $message");
    navigationHandler(message);
  }

  Future onResumehHanlder(Map<String, dynamic> message) async {
    print("onResume: $message");
    navigationHandler(message);
  }

  Future onBackgroundMessageHandler(Map<String, dynamic> message) async {
    // Note: the protocol of data and notification are in line with the fields defined by a RemoteMessage.
    // https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/RemoteMessage
    print("onBackgroundMessageHandler: $message");
  }

  void navigationHandler(Map<String, dynamic> payload) {
    if (payload['notificationType'] == 'dailyEngagementReminder') {
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
      }
  }
}
