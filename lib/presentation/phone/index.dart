import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/navigation_bar/navigation_bar_bloc.dart';
import '../../injection.dart';
import 'common/interfaces.dart';
import 'engage/engage_page.dart';
import 'home/home_page.dart';
import 'notifications/notifications_page.dart';
import 'profile/profile_page.dart';

List<IIndexedPage> _indexedPages = [
  HomePage(navigatorKey: GlobalKey()),
  EngagePage(navigatorKey: GlobalKey()),
  NotificationsPage(navigatorKey: GlobalKey()),
  ProfilePage(navigatorKey: GlobalKey()),
];

class IndexPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBarBloc, NavigationBarState>(
      builder: (BuildContext context, NavigationBarState state) {
        if (state.route != null) {
          NavigatorState routeNavigatorState =
              _indexedPages[state.tab.index].navigatorKey.currentState;

          if (routeNavigatorState.canPop()) {
            // clear navigation stack before going to new route
            routeNavigatorState
                .popUntil((route) => route.isFirst);
          }

          _indexedPages[state.tab.index]
              .navigatorKey
              .currentState
              .pushNamed(state.route);
        }

        return _IndexPage(
          tabIndex: state.tab.index,
        );
      },
    );
  }
}

class _IndexPage extends StatelessWidget {
  final int tabIndex;

  const _IndexPage({Key key, this.tabIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        NavigatorState currentNavigatorState =
            _indexedPages[tabIndex].navigatorKey.currentState;

        if (currentNavigatorState.canPop()) {
          !await currentNavigatorState.maybePop();
        } else {
          // return true;
          // TODO return true to exit the app. Return false for testing
          return false;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: tabIndex,
            children: <Widget>[
              _indexedPages[0],
              _indexedPages[1],
              _indexedPages[2],
              _indexedPages[3],
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[500],
          type: BottomNavigationBarType.fixed,
          currentIndex: tabIndex,
          onTap: (int index) {
            if (tabIndex != index) {
              getIt<NavigationBarBloc>()
                ..add(
                  NavigationBarEvent(
                    tab: NavigationTabEnum.values[index],
                  ),
                );
            } else {
              // If the user is re-selecting the tab, the common
              // behavior is to empty the stack.
              _indexedPages[index]
                  .navigatorKey
                  .currentState
                  .popUntil((route) => route.isFirst);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text(
                "HOME",
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.class_),
              title: Text(
                "ENGAGE",
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              title: Text(
                "NOTIFICATIONS",
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.perm_identity),
              title: Text(
                "PROFILE",
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
