import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/bible_series/bible_series_bloc.dart';
import '../../../application/navigation_bar/navigation_bar_bloc.dart';
import '../../../injection.dart';
import '../common/interfaces.dart';

class HomePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const HomePage({Key key, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
          create: (BuildContext context) => getIt<BibleSeriesBloc>(),
          // e.g. Use to get current study for home page
        ),
      ],
      // child: TestWidget(),
      child: Scaffold(
        body: Navigator(
          key: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (BuildContext context) {
                switch (settings.name) {
                  case '/':
                    return HomeIndex();
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class HomeIndex extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // bottomNavigationBar: BottomNavigation(currentIndex: 0,),
        body: Column(
          children: <Widget>[
            Container(
              child: Text('HOME!'),
            ),
            RaisedButton(
              child: Text('Engage'),
              onPressed: () {
                getIt<NavigationBarBloc>()
                  ..add(
                    NavigationBarEvent(
                      tab: NavigationTabEnum.engage,
                    ),
                  );
              },
            ),
            RaisedButton(
              child: Text('Example Notification Detail'),
              onPressed: () {
                getIt<NavigationBarBloc>()
                  ..add(
                    NavigationBarEvent(
                        tab: NavigationTabEnum.notifications,
                        route: '/notification_detail'),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}
