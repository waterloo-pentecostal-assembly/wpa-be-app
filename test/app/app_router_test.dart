import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/app/router/app_router.dart';
import 'package:wpa_app/app/router/deep_links.dart';
import 'package:wpa_app/application/audio_player/audio_player_cubit.dart';
import 'package:wpa_app/application/authentication/authentication_cubit.dart';
import 'package:wpa_app/application/links/links_cubit.dart';
import 'package:wpa_app/application/notifications/notifications_cubit.dart';
import 'package:wpa_app/domain/audio/entities.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';
import 'package:wpa_app/domain/links/interface.dart';
import 'package:wpa_app/domain/notifications/entities.dart';
import 'package:wpa_app/infrastructure/session/app_session.dart';
import 'package:wpa_app/presentation/features/audio/mini_player.dart';
import 'package:wpa_app/presentation/features/shell/app_shell.dart';
import 'package:wpa_app/presentation/foundation/navigation/app_navigator.dart';

import '../helpers/fakes.dart' show FakeAudioPlayer;

class _MockFacade extends Mock implements IAuthenticationFacade {}

class _MockLinks extends Mock implements ILinksRepository {}

class _MockNavigator extends Mock implements AppNavigator {}

LocalUser _user({bool admin = false}) => LocalUser(
      id: 'u1',
      firstName: 'Ada',
      lastName: 'L',
      email: 'ada@example.com',
      reports: 0,
      thumbnailUrl: null,
      thumbnail: null,
      isAdmin: admin,
      isVerified: true,
    );

Widget _stub(String name, {List<(String, String)> links = const []}) => Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            Text(name),
            for (final (label, location) in links)
              TextButton(
                onPressed: () => GoRouter.of(context).push(location),
                child: Text(label),
              ),
          ],
        ),
      ),
    );

RouteScreens _stubScreens() => RouteScreens(
      splash: () => _stub('splash'),
      signIn: () => _stub('sign in'),
      signUp: () => _stub('sign up'),
      passwordReset: () => _stub('reset'),
      engageHome: () =>
          _stub('engage home', links: [('open series', '/engage/series')]),
      allBibleSeries: () => _stub('all series'),
      bibleSeriesDetail: (r) => _stub('series ${r.seriesId}'),
      contentDetail: (r) => _stub('content ${r.contentId}'),
      forum: (r) => _stub('forum ${r.forumId}'),
      threadDetail: (r) =>
          _stub('thread ${r.threadId} focus ${r.focusCommentId}'),
      prayerRequests: (r) => _stub('prayer requests ${r.tab.name}'),
      testimonies: (r) => _stub('testimonies ${r.tab.name}'),
      profile: () => _stub('profile', links: [
        ('settings', '/profile/notification-settings'),
        ('notes', '/profile/bible-notes'),
      ]),
      notificationSettings: () => _stub('notification settings'),
      bibleNotes: () => _stub('bible notes',
          links: [('open reading', '/engage/series/s1/content/c1')]),
      adminHome: () => _stub('admin home'),
      userVerification: () => _stub('user verification'),
      prayerRequestApproval: () => _stub('prayer approval'),
      testimonyApproval: () => _stub('testimony approval'),
    );

void main() {
  late AppSession session;
  late _MockFacade facade;
  late AuthenticationCubit auth;
  late GoRouter router;
  late AudioPlayerCubit audio;

  // Created inside each test so stream events run in the test's fake-async
  // zone.
  void createApp() {
    session = AppSession();
    facade = _MockFacade();
    auth = AuthenticationCubit(facade, session);
    router = buildAppRouter(auth: auth, screens: _stubScreens());
    audio = AudioPlayerCubit(FakeAudioPlayer());
    addTearDown(() {
      router.dispose();
      auth.close();
      audio.close();
    });
  }

  Future<void> pumpApp(WidgetTester tester,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    createApp();
    final links = _MockLinks();
    when(links.getLinks).thenThrow(Exception('offline'));
    await tester.pumpWidget(
      RepositoryProvider<AppNavigator>.value(
        value: _MockNavigator(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider(create: (_) => LinksCubit(links)),
            BlocProvider.value(value: audio),
            BlocProvider(
              create: (_) =>
                  NotificationsCubit(const Stream<PushNotification>.empty()),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, {bool admin = false}) async {
    session.update(_user(admin: admin));
    await tester.pumpAndSettle();
  }

  testWidgets('splash -> sign in when unauthenticated', (tester) async {
    await pumpApp(tester);
    when(facade.getSignedInUser).thenThrow(Exception('none'));
    expect(find.text('splash'), findsOneWidget);
    await auth.checkAuthentication();
    await tester.pumpAndSettle();
    expect(find.text('sign in'), findsOneWidget);
  });

  testWidgets('signing in shows the Engage tab; non-admins have no ADMIN',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    expect(find.text('engage home'), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('ADMIN'), findsNothing);
    expect(find.text('GIVE'), findsOneWidget);
  });

  testWidgets('the mini player shows on every tab, not over the keyboard',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester, admin: true);
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.text('Sermon'), findsNothing);

    await audio.play(const AudioTrack(id: 't', url: 'u', title: 'Sermon'));
    await tester.pumpAndSettle();
    expect(find.text('Sermon'), findsOneWidget);

    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();
    expect(find.text('Sermon'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(MiniPlayer), findsNothing);
  });

  testWidgets('an unknown location falls back to the Engage root',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    router.go('/no-such-page');
    await tester.pumpAndSettle();
    expect(find.text('engage home'), findsOneWidget);
  });

  testWidgets('tab switching keeps each branch stack; re-tap returns to root',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester, admin: true);

    await tester.tap(find.text('open series'));
    await tester.pumpAndSettle();
    expect(find.text('all series'), findsOneWidget);

    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();
    expect(find.text('profile'), findsOneWidget);

    // Switching back restores the Engage stack.
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    expect(find.text('all series'), findsOneWidget);

    // Re-tapping the active tab returns to its root.
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    expect(find.text('engage home'), findsOneWidget);

    await tester.tap(find.text('ADMIN'));
    await tester.pumpAndSettle();
    expect(find.text('admin home'), findsOneWidget);
  });

  testWidgets('bible notes open from profile and link to a reading',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester);

    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('notes'));
    await tester.pumpAndSettle();
    expect(find.text('bible notes'), findsOneWidget);

    await tester.tap(find.text('open reading'));
    await tester.pumpAndSettle();
    expect(find.text('content c1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('bible notes'), findsOneWidget);
  });

  testWidgets('signing out returns to sign in', (tester) async {
    await pumpApp(tester);
    when(facade.signOut).thenAnswer((_) async {});
    await signIn(tester);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('sign in'), findsOneWidget);
  });

  testWidgets('deep links open their screen', (tester) async {
    await pumpApp(tester);
    await signIn(tester, admin: true);

    router.go(locationForNotification({
      'notificationType': 'newForumComment',
      'forumId': 'f1',
      'threadId': 't1',
      'commentId': 'c9',
    })!
        .toString());
    await tester.pumpAndSettle();
    expect(find.text('thread t1 focus c9'), findsOneWidget);

    router.go(
        locationForNotification({'notificationType': 'prayerRequestPrayed'})!
            .toString());
    await tester.pumpAndSettle();
    expect(find.text('prayer requests mine'), findsOneWidget);

    router.go(locationForNotification({'notificationType': 'userSignUp'})!
        .toString());
    await tester.pumpAndSettle();
    expect(find.text('user verification'), findsOneWidget);
  });

  testWidgets('admin deep links fall back to Engage for non-admins',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    router.go(locationForNotification(
            {'notificationType': 'newTestimonyForApproval'})!
        .toString());
    await tester.pumpAndSettle();
    expect(find.text('engage home'), findsOneWidget);
  });

  testWidgets('a cold-start deep link is opened after authentication',
      (tester) async {
    await pumpApp(tester);
    router.go('/engage/series/s7');
    await tester.pumpAndSettle();
    expect(find.text('splash'), findsOneWidget);
    await signIn(tester);
    expect(find.text('series s7'), findsOneWidget);
  });

  testWidgets('wide windows use a navigation rail', (tester) async {
    await pumpApp(tester, size: const Size(1024, 768));
    await signIn(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
