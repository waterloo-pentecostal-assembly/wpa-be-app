import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wpa_app/application/links/links_bloc.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

import '../app/constants.dart';
import '../app/injection.dart';
import '../application/navigation_bar/navigation_bar_bloc.dart';
import 'admin/admin_page.dart';
import 'common/interfaces.dart';
import 'common/text_factory.dart';
import 'common/toast_message.dart';
import 'engage/main/engage.dart';
import 'give/give_page.dart';
import 'profile/profile.dart';

class IndexPage extends StatelessWidget {
  final List<IIndexedPage> indexedPages = [
    EngagePage(navigatorKey: GlobalKey()),
    GivePage(navigatorKey: GlobalKey()),
    // NotificationsPage(navigatorKey: GlobalKey()),
    ProfilePage(navigatorKey: GlobalKey()),
    AdminPage(navigatorKey: GlobalKey())
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (BuildContext context) => getIt<NavigationBarBloc>(),
        ),
        BlocProvider(
            create: (BuildContext context) =>
                getIt<LinksBloc>()..add(LinksRequested()))
      ],
      child: _IndexPage(
        indexedPages: indexedPages,
      ),
    );

    // BlocProvider(
    //   create: (BuildContext context) => getIt<NavigationBarBloc>(),
    //   child: _IndexPage(
    //     indexedPages: indexedPages,
    //   ),
    // );
  }
}

class _IndexPage extends StatelessWidget {
  final List<IIndexedPage> indexedPages;

  const _IndexPage({Key? key, required this.indexedPages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBarBloc, NavigationBarState>(
      builder: (BuildContext context, NavigationBarState state) {
        NavigatorState? routeNavigatorState =
            indexedPages[state.tab.index].navigatorKey?.currentState;

        if (routeNavigatorState?.canPop() == true) {
          // clear navigation stack before going to new route
          routeNavigatorState?.popUntil((route) => route.isFirst);
        }

        indexedPages[state.tab.index].navigatorKey?.currentState?.pushNamed(
              state.route ?? '',
              arguments: state.arguments,
            );

        return NavigationBar(
          tabIndex: state.tab.index,
          indexedPages: indexedPages,
        );
      },
    );
  }
}

class NavigationBar extends StatelessWidget {
  final int tabIndex;
  final List<IIndexedPage> indexedPages;

  const NavigationBar({Key? key, required this.tabIndex, required this.indexedPages})
      : super(key: key);

  void handleOnTap(BuildContext context, int index, String url) async {
    if (NavigationTabEnum.values[index] == NavigationTabEnum.GIVE) {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        ToastMessage.showErrorToast("Error opening page", context);
      }
    } else if (tabIndex != index) {
      BlocProvider.of<NavigationBarBloc>(context)
        ..add(
          NavigationBarEvent(
            tab: NavigationTabEnum.values[index],
          ),
        );
    } else {
      // If the user is re-selecting the tab, the common
      // behavior is to empty the stack.
      if (indexedPages[index].navigatorKey?.currentState != null) {
        indexedPages[index]
            .navigatorKey
            ?.currentState
            ?.popUntil((route) => route.isFirst);
      }
    }
  }

  List<BottomNavigationBarItem> getNavBarItems() {
    final LocalUser user = getIt<LocalUser>();
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        // icon: Icon(Icons.class_),
        // label: 'ENGAGE',
        icon: Icon(
          Icons.home,
          size: getIt<LayoutFactory>().getDimension(baseDimension: 24),
        ),
        label:
            'HOME', // Really the engage page that we are using as "HOME" in phase 1
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite,
            size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0)),
        label: 'GIVE',
      ),
      // BottomNavigationBarItem(
      //   icon: Icon(Icons.notifications),
      //   label: 'NOTIFICATIONS',
      // ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person,
            size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0)),
        label: 'PROFILE',
      )
    ];

    if (user.isAdmin) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings,
              size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0)),
          label: 'ADMIN',
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LinksBloc, LinksState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        String url = '';
        if (state is LinksLoaded) {
          url = state.linkMap['give_link'];
        }
        return PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) async {
            NavigatorState? currentNavigatorState =
                indexedPages[tabIndex].navigatorKey?.currentState;
            if (currentNavigatorState?.canPop() == true) {
              await currentNavigatorState?.maybePop();
            } else {
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: tabIndex,
              children: <Widget>[
                indexedPages[0],
                indexedPages[1],
                indexedPages[2],
                indexedPages[3],
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              selectedItemColor: kWpaBlue.withOpacity(0.6),
              unselectedItemColor: Colors.grey[500],
              selectedLabelStyle:
                  getIt<TextFactory>().regularTextStyle(fontSize: 11),
              unselectedLabelStyle:
                  getIt<TextFactory>().liteTextStyle(fontSize: 10),
              type: BottomNavigationBarType.fixed,
              currentIndex: tabIndex,
              onTap: (int index) => handleOnTap(context, index, url),
              items: getNavBarItems(),
            ),
          ),
        );
      },
    );
  }
}
