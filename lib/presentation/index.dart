import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wpa_app/services/firebase_messaging_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wpa_app/application/links/links_bloc.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/utils/LazyLoadIndexedStack.dart';

import '../app/constants.dart';
import '../app/injection.dart';
import '../application/navigation_bar/navigation_bar_bloc.dart';
import 'admin/admin_page.dart';
import 'common/in_app_notification_banner.dart';
import 'common/interfaces.dart';
import 'common/text_factory.dart';
import 'common/toast_message.dart';
import 'engage/main/engage.dart';
import 'profile/profile.dart';

class EmptyPage extends IIndexedPage {
  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}

class IndexPage extends StatelessWidget {
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
      child: _IndexPage(),
    );
  }
}

class _IndexPage extends StatefulWidget {
  const _IndexPage({Key? key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<_IndexPage> {
  late List<IIndexedPage> indexedPages;
  StreamSubscription? _foregroundMessageSubscription;

  @override
  void initState() {
    super.initState();
    indexedPages = [
      EngagePage(navigatorKey: GlobalKey()),
      EmptyPage(),
      ProfilePage(navigatorKey: GlobalKey()),
      AdminPage(navigatorKey: GlobalKey())
    ];

    // Handle initial deep link if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = BlocProvider.of<NavigationBarBloc>(context).state;
      if (state.route != null) {
        _handleNavigation(state);
      }
    });

    // Listen for foreground messages
    _foregroundMessageSubscription = getIt<FirebaseMessagingService>()
        .foregroundMessageStream
        .listen((message) {
      String title = message.notification?.title ?? 'Notification';
      String body = message.notification?.body ?? 'New notification received';

      // Fallback to payload data if notification object is empty
      if (message.notification == null) {
        if (message.data.containsKey('title')) {
          title = message.data['title'];
        }
      }

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: InAppNotificationBanner(
                title: title,
                body: body,
                onDismiss: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                onView: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  FirebaseMessagingService.navigationHandler(message.data);
                },
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    super.dispose();
  }

  void _handleNavigation(NavigationBarState state) {
    if (state.route != null) {
      if (indexedPages[state.tab.index].navigatorKey?.currentState != null) {
        NavigatorState? routeNavigatorState =
            indexedPages[state.tab.index].navigatorKey?.currentState;

        if (routeNavigatorState?.canPop() == true) {
          routeNavigatorState?.popUntil((route) => route.isFirst);
        }

        routeNavigatorState?.pushNamed(
          state.route ?? '',
          arguments: state.arguments,
        );

        // Reset the route state to allow subsequent identical navigations
        BlocProvider.of<NavigationBarBloc>(context).add(
          NavigationBarEvent(
            tab: state.tab,
            route: null,
            arguments: null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NavigationBarBloc, NavigationBarState>(
      listener: (context, state) {
        // Schedule navigation after build to ensure Navigator is mounted
        if (state.route != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNavigation(state);
          });
        }
      },
      builder: (BuildContext context, NavigationBarState state) {
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

  const NavigationBar(
      {Key? key, required this.tabIndex, required this.indexedPages})
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
    return BlocBuilder<LinksBloc, LinksState>(
      builder: (context, state) {
        String url = '';
        if (state is LinksLoaded) {
          url = state.linkMap['give_link'];
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            if (didPop) {
              return;
            }
            NavigatorState? currentNavigatorState =
                indexedPages[tabIndex].navigatorKey?.currentState;
            if (currentNavigatorState?.canPop() == true) {
              await currentNavigatorState?.maybePop();
            }
          },
          child: Scaffold(
            body: LazyLoadIndexedStack(
              index: tabIndex,
              children: <Widget>[
                indexedPages[0],
                indexedPages[1],
                indexedPages[2],
                indexedPages[3],
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              selectedItemColor: kWpaBlue.withValues(alpha: 0.6),
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
