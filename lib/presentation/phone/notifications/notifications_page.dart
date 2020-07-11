import 'package:flutter/material.dart';
import '../common/interfaces.dart';

// class NotificationsPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
//           child: Text('Notifications Page'),
//         ),
//       ),
//     );
//   }
// }


class NotificationsPage extends IIndexedPage {

  final GlobalKey<NavigatorState> navigatorKey;

  const NotificationsPage({Key key, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (BuildContext context) {
              switch (settings.name) {
                case '/':
                  return NotificationsPageRoot();
                case '/notification_detail':
                  return NotificationDetail();
              }
            },
          );
        },
      ),
    );
  }
}

class NotificationsPageRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('Example Notification'),
              onPressed: () {
                Navigator.pushNamed(context, '/notification_detail');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            Text('Example notification details'),
            RaisedButton(
              child: Text('Back'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}
