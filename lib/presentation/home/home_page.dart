import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_config.dart';
import '../../app/injection.dart';
import '../../application/bible_series/bible_series_bloc.dart';
import '../../application/navigation_bar/navigation_bar_bloc.dart';
import '../../domain/authentication/entities.dart';
import '../common/interfaces.dart';

class HomePage extends IIndexedPage {
  @override
  final GlobalKey<NavigatorState>? navigatorKey;

  const HomePage({Key? key, this.navigatorKey}) : super(key: key);

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
                  default:
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
  const HomeIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // bottomNavigationBar: BottomNavigation(currentIndex: 0,),
        body: Column(
          children: <Widget>[
            Container(
              child: Text(getIt.isRegistered<LocalUser>()
                  ? getIt<LocalUser>().toString()
                  : 'unregistered'),
            ),
            Container(
              child: const Text('HOME'),
            ),
            ElevatedButton(
              child: const Text('Engage'),
              onPressed: () {
                BlocProvider.of<NavigationBarBloc>(context)
                  ..add(
                    NavigationBarEvent(
                      tab: NavigationTabEnum.ENGAGE,
                    ),
                  );
              },
            ),
            // RaisedButton(
            //   child: Text('Example Notification Detail'),
            //   onPressed: () {
            //     BlocProvider.of<NavigationBarBloc>(context)
            //       ..add(
            //         NavigationBarEvent(
            //             tab: NavigationTabEnum.NOTIFICATIONS,
            //             route: '/notification_detail'),
            //       );
            //   },
            // ),
            Container(
              child: Text(getIt<AppConfig>().appEnvironment.toString()),
            )
          ],
        ),
      ),
    );
  }
}
