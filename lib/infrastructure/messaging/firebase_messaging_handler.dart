import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

//takes in messages and handles errors resends them to the appropriate bloc/class
class FireBaseMessagingHandler {
  final FirebaseMessaging _fcm = FirebaseMessaging();

  static final FireBaseMessagingHandler _instance =
      FireBaseMessagingHandler._internal();

  factory FireBaseMessagingHandler() {
    return _instance;
  }

  FireBaseMessagingHandler._internal() {
    initialise();
  }

  Future initialise() async {
    if (Platform.isIOS) {
      _fcm.requestNotificationPermissions(IosNotificationSettings());
    }

    //todo:remove this as this is used to retrieve the RTC token for firebase.
    _fcm.getToken().then((token) {
      print(token);
    });

    _fcm.configure(
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
// this code for the most part was sourced from:
// https://www.filledstacks.com/post/push-notifications-in-flutter-using-firebase/
