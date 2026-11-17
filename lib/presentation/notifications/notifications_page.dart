import 'package:material_ui/material_ui.dart';

import '../../app/injection.dart';
import '../common/interfaces.dart';
import '../common/text_factory.dart';

class NotificationsPage extends IIndexedPage {
  @override
  final GlobalKey<NavigatorState>? navigatorKey;

  const NotificationsPage({Key? key, this.navigatorKey}) : super(key: key);

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
  const NoNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: getIt<TextFactory>().lite('No Notifications'),
    );
  }
}

class NotificationsPageRoot extends StatelessWidget {
  const NotificationsPageRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: ListView(
          children: <Widget>[
            HeaderWidget(),
            const SizedBox(height: 12),
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
  const NotificationDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            const Text('Example notification details'),
            ElevatedButton(
              child: const Text('Back'),
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
  const HeaderWidget({super.key});

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
