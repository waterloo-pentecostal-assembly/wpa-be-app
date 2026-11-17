import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/authentication/authentication_cubit.dart';
import '../../presentation/features/shell/app_shell.dart';
import '../constants.dart';
import 'redirect_policy.dart';
import 'routes.dart';
import 'screen_registry.dart';

/// Screens per route, so tests can substitute stubs.
class RouteScreens {
  const RouteScreens({
    this.splash = ScreenRegistry.splash,
    this.signIn = ScreenRegistry.signIn,
    this.signUp = ScreenRegistry.signUp,
    this.passwordReset = ScreenRegistry.passwordReset,
    this.engageHome = ScreenRegistry.engageHome,
    this.allBibleSeries = ScreenRegistry.allBibleSeries,
    this.bibleSeriesDetail = ScreenRegistry.bibleSeriesDetail,
    this.contentDetail = ScreenRegistry.contentDetail,
    this.forum = ScreenRegistry.forum,
    this.threadDetail = ScreenRegistry.threadDetail,
    this.prayerRequests = ScreenRegistry.prayerRequests,
    this.testimonies = ScreenRegistry.testimonies,
    this.profile = ScreenRegistry.profile,
    this.notificationSettings = ScreenRegistry.notificationSettings,
    this.adminHome = ScreenRegistry.adminHome,
    this.userVerification = ScreenRegistry.userVerification,
    this.prayerRequestApproval = ScreenRegistry.prayerRequestApproval,
    this.testimonyApproval = ScreenRegistry.testimonyApproval,
    this.shell = _defaultShell,
  });

  final Widget Function() splash;
  final Widget Function() signIn;
  final Widget Function() signUp;
  final Widget Function() passwordReset;
  final Widget Function() engageHome;
  final Widget Function() allBibleSeries;
  final Widget Function(BibleSeriesRoute) bibleSeriesDetail;
  final Widget Function(ContentRoute) contentDetail;
  final Widget Function(ForumRoute) forum;
  final Widget Function(ThreadDetailRoute) threadDetail;
  final Widget Function(PrayerRequestsRoute) prayerRequests;
  final Widget Function(TestimoniesRoute) testimonies;
  final Widget Function() profile;
  final Widget Function() notificationSettings;
  final Widget Function() adminHome;
  final Widget Function() userVerification;
  final Widget Function() prayerRequestApproval;
  final Widget Function() testimonyApproval;
  final Widget Function(
    BuildContext context,
    StatefulNavigationShell shell,
    bool isAdmin,
  ) shell;

  static Widget _defaultShell(
    BuildContext context,
    StatefulNavigationShell shell,
    bool isAdmin,
  ) =>
      AppShell(
        currentBranch: shell.currentIndex,
        onSelectBranch: (branch, reselected) =>
            shell.goBranch(branch, initialLocation: reselected),
        isAdmin: isAdmin,
        fallbackGiveUrl: kWpaGiveUrl,
        child: shell,
      );
}

/// Builds the app's [GoRouter]: auth redirects, the tab shell (Engage,
/// Profile, Admin) and every route.
GoRouter buildAppRouter({
  required AuthenticationCubit auth,
  RouteScreens screens = const RouteScreens(),
  RedirectPolicy? policy,
  String initialLocation = Paths.splash,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final redirectPolicy = policy ?? RedirectPolicy();

  GoRoute leaf(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, builder: (_, state) => build(state));

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    refreshListenable: StreamListenable(auth.stream),
    // Unknown locations fall back to the Engage root (the redirect policy
    // still applies), as unknown route names did before go_router.
    onException: (_, __, router) => router.go(Paths.engage),
    redirect: (_, state) => redirectPolicy.redirect(
      status: auth.state.status,
      isAdmin: auth.state.isAdmin,
      location: state.uri.toString(),
    ),
    routes: [
      leaf(Paths.splash, (_) => screens.splash()),
      leaf(Paths.signIn, (_) => screens.signIn()),
      leaf(Paths.signUp, (_) => screens.signUp()),
      leaf(Paths.passwordReset, (_) => screens.passwordReset()),
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) =>
            BlocBuilder<AuthenticationCubit, AuthenticationState>(
          bloc: auth,
          buildWhen: (a, b) => a.isAdmin != b.isAdmin,
          builder: (context, state) =>
              screens.shell(context, shell, state.isAdmin),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.engage,
                builder: (_, __) => screens.engageHome(),
                routes: [
                  leaf(Paths.allSeries, (_) => screens.allBibleSeries()),
                  leaf(
                    Paths.seriesDetail,
                    (s) => screens.bibleSeriesDetail(
                      BibleSeriesRoute.parse(s.pathParameters),
                    ),
                  ),
                  leaf(
                    Paths.content,
                    (s) => screens.contentDetail(
                      ContentRoute.parse(
                        s.pathParameters,
                        s.uri.queryParameters,
                      ),
                    ),
                  ),
                  leaf(
                    Paths.forum,
                    (s) => screens.forum(ForumRoute.parse(s.pathParameters)),
                  ),
                  leaf(
                    Paths.thread,
                    (s) => screens.threadDetail(
                      ThreadDetailRoute.parse(
                        s.pathParameters,
                        s.uri.queryParameters,
                      ),
                    ),
                  ),
                  leaf(
                    Paths.prayerRequests,
                    (s) => screens.prayerRequests(
                      PrayerRequestsRoute.parse(s.uri.queryParameters),
                    ),
                  ),
                  leaf(
                    Paths.testimonies,
                    (s) => screens.testimonies(
                      TestimoniesRoute.parse(s.uri.queryParameters),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.profile,
                builder: (_, __) => screens.profile(),
                routes: [
                  leaf(
                    Paths.notificationSettings,
                    (_) => screens.notificationSettings(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.admin,
                builder: (_, __) => screens.adminHome(),
                routes: [
                  leaf(Paths.userVerification,
                      (_) => screens.userVerification()),
                  leaf(
                    Paths.prayerRequestApproval,
                    (_) => screens.prayerRequestApproval(),
                  ),
                  leaf(
                    Paths.testimonyApproval,
                    (_) => screens.testimonyApproval(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Notifies listeners on every stream event (router refresh).
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
