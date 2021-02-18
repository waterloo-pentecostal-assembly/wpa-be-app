import 'package:flutter/material.dart';

import '../../app/injection.dart';
import '../common/interfaces.dart';
import '../common/text_factory.dart';

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
                default:
                  return NotificationsPageRoot();
              }
            },
          );
        },
      ),
    );
  }
}

class NoNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: getIt<TextFactory>().lite('No Notifications'),
    );
  }
}

class NotificationsPageRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: ListView(
          children: <Widget>[
            HeaderWidget(),
            SizedBox(height: 12),
            NoNotifications(),
            // RaisedButton(
            //   child: Text('Example Notification'),
            //   onPressed: () {
            //     Navigator.pushNamed(context, '/notification_detail');
            //   },
            // ),
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

class HeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: getIt<TextFactory>().heading('Notifications'),
      ),
    );
  }
}
