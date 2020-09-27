import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/navigation_bar/navigation_bar_bloc.dart';
import '../../injection.dart';
import 'common/interfaces.dart';
import 'engage/pages/engage_page.dart';
import 'give/give_page.dart';
import 'home/home_page.dart';
import 'notifications/notifications_page.dart';
import 'profile/profile_page.dart';

class IndexPage extends StatelessWidget {
  final List<IIndexedPage> indexedPages = [
    HomePage(navigatorKey: GlobalKey()),
    EngagePage(navigatorKey: GlobalKey()),
    GivePage(navigatorKey: GlobalKey()),
    NotificationsPage(navigatorKey: GlobalKey()),
    ProfilePage(navigatorKey: GlobalKey()),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBarBloc, NavigationBarState>(
      builder: (BuildContext context, NavigationBarState state) {
        if (state.route != null) {
          NavigatorState routeNavigatorState =
              indexedPages[state.tab.index].navigatorKey.currentState;

          if (routeNavigatorState.canPop()) {
            // clear navigation stack before going to new route
            routeNavigatorState.popUntil((route) => route.isFirst);
          }

          indexedPages[state.tab.index]
              .navigatorKey
              .currentState
              .pushNamed(state.route);
        }

        return _IndexPage(
          tabIndex: state.tab.index,
          indexedPages: indexedPages,
        );
      },
    );
  }
}

class _IndexPage extends StatelessWidget {
  final int tabIndex;
  final List<IIndexedPage> indexedPages;

  const _IndexPage({Key key, this.tabIndex, this.indexedPages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        NavigatorState currentNavigatorState =
            indexedPages[tabIndex].navigatorKey.currentState;

        if (currentNavigatorState.canPop()) {
          !await currentNavigatorState.maybePop();
        } else {
          // return true;
          // TODO: return true to exit the app. Return false for testing
          return false;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: tabIndex,
            children: <Widget>[
              indexedPages[0],
              indexedPages[1],
              indexedPages[2],
              indexedPages[3],
              indexedPages[4],
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
              indexedPages[index]
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
              icon: Icon(Icons.favorite),
              title: Text(
                "GIVE",
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
              icon: Icon(Icons.person),
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
