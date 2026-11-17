// Smoke tests: every feature screen renders with real cubits (mocked
// repositories) at phone and tablet widths without layout exceptions.
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/application/admin/admin_queue_cubit.dart';
import 'package:wpa_app/application/audio_player/audio_player_cubit.dart';
import 'package:wpa_app/application/audio_player/audio_player_port.dart';
import 'package:wpa_app/application/authentication/authentication_cubit.dart';
import 'package:wpa_app/application/authentication/sign_in_cubit.dart';
import 'package:wpa_app/application/bible_series/bible_series_detail_cubit.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/community_posts/post_list_cubit.dart';
import 'package:wpa_app/application/completions/content_detail_cubit.dart';
import 'package:wpa_app/application/engage/engage_home_cubit.dart';
import 'package:wpa_app/application/forum/forum_cubit.dart';
import 'package:wpa_app/application/forum/thread_cubit.dart';
import 'package:wpa_app/application/links/links_cubit.dart';
import 'package:wpa_app/application/notification_settings/notification_settings_cubit.dart';
import 'package:wpa_app/application/prayer_requests/prayer_requests_cubits.dart';
import 'package:wpa_app/application/profile/profile_cubit.dart';
import 'package:wpa_app/domain/achievements/entities.dart';
import 'package:wpa_app/domain/achievements/interfaces.dart';
import 'package:wpa_app/domain/admin/interfaces.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/bible_series/interfaces.dart';
import 'package:wpa_app/domain/common/analytics.dart';
import 'package:wpa_app/domain/common/paging.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/domain/forum/interfaces.dart';
import 'package:wpa_app/domain/links/entities.dart';
import 'package:wpa_app/domain/links/interface.dart';
import 'package:wpa_app/domain/media/entities.dart';
import 'package:wpa_app/domain/media/interfaces.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';
import 'package:wpa_app/domain/notification_settings/interfaces.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/domain/prayer_requests/interfaces.dart';
import 'package:wpa_app/domain/user_profile/entities.dart';
import 'package:wpa_app/domain/user_profile/interfaces.dart';
import 'package:wpa_app/infrastructure/session/app_session.dart';
import 'package:wpa_app/presentation/design_system/theme.dart';
import 'package:wpa_app/presentation/features/admin/admin_home_page.dart';
import 'package:wpa_app/presentation/features/admin/admin_queue_page.dart';
import 'package:wpa_app/presentation/features/auth/sign_in_page.dart';
import 'package:wpa_app/presentation/features/bible_series/bible_series_detail_page.dart';
import 'package:wpa_app/presentation/features/bible_series/content_detail_page.dart';
import 'package:wpa_app/presentation/features/community_posts/post_copy.dart';
import 'package:wpa_app/presentation/features/community_posts/posts_page.dart';
import 'package:wpa_app/presentation/features/engage/engage_home_page.dart';
import 'package:wpa_app/presentation/features/forum/forum_page.dart';
import 'package:wpa_app/presentation/features/forum/thread_detail_page.dart';
import 'package:wpa_app/presentation/features/profile/notification_settings_page.dart';
import 'package:wpa_app/presentation/features/profile/profile_page.dart';
import 'package:wpa_app/presentation/foundation/navigation/app_navigator.dart';

class _MockNavigator extends Mock implements AppNavigator {}

class _MockFacade extends Mock implements IAuthenticationFacade {}

class _MockLinks extends Mock implements ILinksRepository {}

class _MockSeries extends Mock implements IBibleSeriesRepository {}

class _MockCompletions extends Mock implements ICompletionsRepository {}

class _MockForum extends Mock implements IForumRepository {}

class _MockSettings extends Mock implements INotificationSettingsService {}

class _MockPrayers extends Mock implements IPrayerRequestsRepository {}

class _MockAdmin extends Mock implements IAdminService {}

class _MockProfile extends Mock implements IUserProfileRepository {}

class _MockMedia extends Mock implements IMediaRepository {}

class _MockAchievements extends Mock implements IAchievementsRepository {}

class _NoopAnalytics implements IAnalytics {
  @override
  Future<void> log(String name, [Map<String, Object>? params]) async {}
}

class _FakePlayer implements IAudioPlayer {
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<void> get completedStream => const Stream.empty();
  @override
  Duration get position => Duration.zero;
  @override
  Duration? get duration => null;
  @override
  Future<Duration?> setUrl(String url) async => const Duration(minutes: 3);
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> dispose() async {}
}

final _now = DateTime.now();

const _user = LocalUser(
  id: 'u1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  reports: 0,
  thumbnailUrl: null,
  thumbnail: null,
  isAdmin: true,
  isVerified: true,
);

BibleSeries _series() => BibleSeries(
      id: 's1',
      title: 'Gospel of John',
      subTitle: 'A month in John',
      imageUrl: '',
      imageGsLocation: '',
      startDate: _now.subtract(const Duration(days: 2)),
      endDate: _now.add(const Duration(days: 2)),
      isActive: true,
      isVisible: true,
      seriesContentSnippet: [
        for (var i = -2; i <= 2; i++)
          SeriesContentSnippet(
            date: _now.add(Duration(days: i)),
            availableContentTypes: const [
              AvailableContentType(seriesContentType: 'READ', contentId: 'r'),
              AvailableContentType(
                  seriesContentType: 'REFLECT', contentId: 'q'),
            ],
          ),
      ],
    );

SeriesContent _content() => SeriesContent(
      id: 'q',
      contentType: 'REFLECT',
      date: _now,
      title: 'Day 1',
      subTitle: '',
      body: const [
        TitleBody(text: 'Born again'),
        AudioBody(audioFileUrl: 'https://example.com/a.mp3', title: 'Listen'),
        TextBody(paragraphs: ['First paragraph.', 'Second paragraph.']),
        ScriptureBody(
          bibleVersion: 'NIV',
          attribution: 'Biblica',
          scriptures: [
            Scripture(
              book: 'John',
              chapter: '3',
              title: 'Jesus teaches Nicodemus',
              fullChapter: false,
              verses: {'16': 'For God so loved the world...', '17': 'For God'},
            ),
          ],
        ),
        DividerBody(),
        QuestionBody(questions: [
          Question(question: 'What stood out?', location: [5, 0]),
        ]),
        ImageInputBody(),
        LinkBody(link: 'https://example.com', title: 'More', text: 'Open'),
        EmptyBody(),
      ],
    );

PrayerRequest _prayer(String id, {bool mine = false}) => PrayerRequest(
      id: id,
      userId: mine ? 'u1' : 'u2',
      request: 'Please pray for my family ($id).',
      prayedBy: const ['u3'],
      reportedBy: const [],
      hasPrayed: false,
      hasReported: false,
      isMine: mine,
      isApproved: true,
      date: _now,
      isAnonymous: false,
      userSnippet: const UserSnippet(
        firstName: 'Grace',
        lastName: 'Hopper',
        thumbnailUrl: null,
        thumbnail: null,
      ),
      isAnswered: false,
    );

ForumThread _thread() => ForumThread(
      id: 't1',
      forumId: 's1',
      title: 'What does being born again mean?',
      authorId: 'u1',
      authorName: 'Ada Lovelace',
      createdAt: _now,
      updatedAt: _now,
      commentCount: 2,
      isFrozen: false,
      isHidden: false,
    );

Comment _comment(String id, {String? parent}) => Comment(
      id: id,
      threadId: 't1',
      body: 'Comment $id',
      authorId: 'u1',
      authorName: 'Ada Lovelace',
      createdAt: _now,
      updatedAt: _now,
      parentId: parent,
      isHidden: false,
      isDeleted: false,
      likedBy: const ['u2'],
      reportCount: 0,
    );

const _settings = NotificationSettingsEntity(
  id: 'u1',
  dailyEngagementReminder: true,
  prayers: true,
  newPrayerRequest: false,
  testimonies: true,
  newTestimony: false,
  newForumThread: true,
  forumCommentReplies: true,
  forumThreadComments: false,
  forumCommentLikes: true,
  threadsFollowed: ['t1'],
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NewThread(
      forumId: '',
      title: '',
      authorId: '',
      authorName: '',
    ));
  });

  /// Pumps [screen] with app-scope providers. Cubits must be created inside
  /// the test body (fake-async zone).
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = AppSession()..update(_user);
    final links = _MockLinks();
    when(links.getLinks).thenAnswer((_) async => const AppLinks());
    await tester.pumpWidget(
      RepositoryProvider<AppNavigator>.value(
        value: _MockNavigator(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthenticationCubit(_MockFacade(), session),
            ),
            BlocProvider(create: (_) => LinksCubit(links)..load()),
            BlocProvider(create: (_) => AudioPlayerCubit(_FakePlayer())),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: screen),
        ),
      ),
    );
    // Avoid pumpAndSettle: the loading indicator animates forever.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  for (final width in [390.0, 1024.0]) {
    final w = '${width.toInt()}px';

    testWidgets('sign in ($w)', (tester) async {
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => SignInCubit(_MockFacade()),
          child: const SignInPage(),
        ),
        width: width,
      );
      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('engage home ($w)', (tester) async {
      final series = _MockSeries();
      final media = _MockMedia();
      final achievements = _MockAchievements();
      when(series.hasActiveBibleSeries).thenAnswer((_) async => true);
      when(() => series.getBibleSeries(
            limit: any(named: 'limit'),
            isActive: any(named: 'isActive'),
          )).thenAnswer((_) async => [_series()]);
      when(media.getAvailableMedia).thenAnswer((_) async => const [
            Media(
              id: 'm',
              description: 'Sermon',
              platform: 'YouTube',
              link: 'https://youtube.com',
              thumbnailUrl: '',
              thumbnailGsLocation: '',
            ),
          ]);
      when(achievements.watchAchievements).thenAnswer(
          (_) => Stream.value(const Achievements(seriesProgress: 2)));
      when(achievements.getAchievements)
          .thenAnswer((_) async => const Achievements(seriesProgress: 2));
      final session = AppSession()..update(_user);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => EngageHomeCubit(
            bibleSeriesRepository: series,
            achievementsRepository: achievements,
            mediaRepository: media,
            session: session,
          )..load(),
          child: const EngageHomePage(),
        ),
        width: width,
      );
      expect(find.textContaining('Hello'), findsOneWidget);
    });

    testWidgets('bible series detail ($w)', (tester) async {
      final series = _MockSeries();
      final completions = _MockCompletions();
      when(() => series.getBibleSeriesDetails(bibleSeriesId: 's1'))
          .thenAnswer((_) async => _series());
      when(() => completions.getAllCompletions(bibleSeriesId: 's1'))
          .thenAnswer((_) async => {});
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => BibleSeriesDetailCubit(
            bibleSeriesId: 's1',
            bibleSeriesRepository: series,
            completionsRepository: completions,
            analytics: _NoopAnalytics(),
            events: AppEventBus(),
          )..load(),
          child: const BibleSeriesDetailPage(),
        ),
        width: width,
      );
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('READ'), findsWidgets);
    });

    testWidgets('content detail with every body type ($w)', (tester) async {
      final series = _MockSeries();
      final completions = _MockCompletions();
      when(() => series.getContentDetails(
            bibleSeriesId: 's1',
            seriesContentId: 'q',
          )).thenAnswer((_) async => _content());
      when(() => completions.getCompletionOrNull(seriesContentId: 'q'))
          .thenAnswer((_) async => null);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => ContentDetailCubit(
            bibleSeriesId: 's1',
            contentId: 'q',
            bibleSeriesRepository: series,
            completionsRepository: completions,
            analytics: _NoopAnalytics(),
            events: AppEventBus(),
            session: AppSession()..update(_user),
          )..load(),
          child: const ContentDetailPage(contentType: 'REFLECT'),
        ),
        width: width,
      );
      expect(find.text('Born again'), findsOneWidget);
      expect(find.text('John 3: 16 - 17'), findsOneWidget);
      expect(find.text('What stood out?'), findsOneWidget);
      expect(find.text('Upload Photo!'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byIcon(Icons.check_circle),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('prayer requests ($w)', (tester) async {
      final repo = _MockPrayers();
      when(() => repo.getPrayerRequests(
            limit: any(named: 'limit'),
            after: any(named: 'after'),
          )).thenAnswer((_) async => PageResult(
            items: [_prayer('p1'), _prayer('p2')],
            nextCursor: null,
          ));
      when(repo.getMyPrayerRequests)
          .thenAnswer((_) async => [_prayer('p3', mine: true)]);
      when(repo.getMyAnsweredPrayerRequests).thenAnswer((_) async => []);
      final events = AppEventBus();
      final actions = PrayerRequestActions(
        repository: repo,
        analytics: _NoopAnalytics(),
        events: events,
      );
      await pumpScreen(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<AllPostsCubit<PrayerRequest>>(
              create: (_) =>
                  AllPrayerRequestsCubit(actions: actions, events: events)
                    ..load(),
            ),
            BlocProvider<MyPostsCubit<PrayerRequest>>(
              create: (_) =>
                  MyPrayerRequestsCubit(actions: actions, events: events)
                    ..load(),
            ),
            BlocProvider<MyClosedPostsCubit<PrayerRequest>>(
              create: (_) => MyAnsweredPrayerRequestsCubit(
                actions: actions,
                events: events,
              )..load(),
            ),
          ],
          child: const PostsPage<PrayerRequest>(
            copy: PostCopy.prayerRequests,
            initialTab: PostsTab.all,
          ),
        ),
        width: width,
      );
      expect(find.textContaining('(p1)'), findsOneWidget);
      expect(find.textContaining('(p2)'), findsOneWidget);
    });

    testWidgets('forum ($w)', (tester) async {
      final forum = _MockForum();
      final settings = _MockSettings();
      when(() => forum.watchForum('s1'))
          .thenAnswer((_) => const Stream.empty());
      when(() => forum.watchThreads('s1', isAdmin: any(named: 'isAdmin')))
          .thenAnswer((_) => Stream.value([_thread()]));
      when(settings.getNotificationSettings).thenAnswer((_) async => _settings);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => ForumCubit(
            forumId: 's1',
            forumRepository: forum,
            notificationSettings: settings,
            session: AppSession()..update(_user),
            events: AppEventBus(),
          )..load(),
          child: const ForumPage(),
        ),
        width: width,
      );
      expect(find.text('Forum'), findsOneWidget);
      expect(find.text('What does being born again mean?'), findsOneWidget);
      expect(find.text('2 Comments'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('thread detail ($w)', (tester) async {
      final forum = _MockForum();
      final settings = _MockSettings();
      when(() => forum.watchThread('t1', 's1'))
          .thenAnswer((_) => Stream.value(_thread()));
      when(() => forum.watchComments('t1', 's1')).thenAnswer(
        (_) => Stream.value([_comment('c1'), _comment('c2', parent: 'c1')]),
      );
      when(settings.getNotificationSettings).thenAnswer((_) async => _settings);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => ThreadCubit(
            forumId: 's1',
            threadId: 't1',
            forumRepository: forum,
            notificationSettings: settings,
            session: AppSession()..update(_user),
            events: AppEventBus(),
          )..load(),
          child: const ThreadDetailPage(focusCommentId: 'c2'),
        ),
        width: width,
      );
      expect(find.text('Comment c1'), findsOneWidget);
      expect(find.text('Comment c2'), findsOneWidget);
      expect(find.text('Hide Replies'), findsOneWidget);
      expect(find.text('Write a comment...'), findsOneWidget);
    });

    testWidgets('profile ($w)', (tester) async {
      final session = AppSession()..update(_user);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => ProfileCubit(_MockProfile(), session),
          child: const ProfilePage(appVersion: '3.0.1'),
        ),
        width: width,
      );
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Version 3.0.1'), findsOneWidget);
    });

    testWidgets('notification settings ($w)', (tester) async {
      final settings = _MockSettings();
      when(settings.getNotificationSettings).thenAnswer((_) async => _settings);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => NotificationSettingsCubit(settings)..load(),
          child: const NotificationSettingsPage(),
        ),
        width: width,
      );
      expect(find.text('Daily Engagement Reminder'), findsOneWidget);
      expect(find.text('Comment Likes'), findsOneWidget);
    });

    testWidgets('admin home and queue ($w)', (tester) async {
      await pumpScreen(tester, const AdminHomePage(), width: width);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Testimony Approval'), findsOneWidget);

      final admin = _MockAdmin();
      when(admin.getUnverifiedUsers).thenAnswer((_) async => [_user]);
      await pumpScreen(
        tester,
        BlocProvider(
          create: (_) => UserVerificationCubit(admin)..load(),
          child: AdminQueuePage<LocalUser, UserVerificationCubit>(
            title: 'User Verification',
            itemBuilder: (_, u) => UnverifiedUserTile(user: u),
          ),
        ),
        width: width,
      );
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.byTooltip('Approve'), findsOneWidget);
    });
  }
}
