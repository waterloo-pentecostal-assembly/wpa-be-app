// Interaction tests of the Community tab screens with real cubits and fake
// repositories.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/application/challenge_groups/challenge_group_cubit.dart';
import 'package:wpa_app/application/challenge_groups/community_cubit.dart';
import 'package:wpa_app/application/challenge_groups/invite_members_cubit.dart';
import 'package:wpa_app/domain/achievements/entities.dart';
import 'package:wpa_app/domain/challenge_groups/exceptions.dart';
import 'package:wpa_app/presentation/design_system/theme.dart';
import 'package:wpa_app/presentation/features/community/challenge_group_page.dart';
import 'package:wpa_app/presentation/features/community/community_page.dart';
import 'package:wpa_app/presentation/features/community/group_widgets.dart';
import 'package:wpa_app/presentation/features/community/invite_members_page.dart';
import 'package:wpa_app/presentation/foundation/navigation/app_navigator.dart';

import '../helpers/fakes.dart';

class _MockNavigator extends Mock implements AppNavigator {}

/// Pumps long enough for routes, sheets and dialogs to finish animating
/// (`pumpAndSettle` never settles while a loading spinner spins).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late _MockNavigator navigator;
  late FakeChallengeGroupsRepository groups;
  late FakeAnalytics analytics;
  late FakeSession session;

  setUp(() {
    navigator = _MockNavigator();
    groups = FakeChallengeGroupsRepository();
    analytics = FakeAnalytics();
    session = FakeSession(buildUser(id: 'user-1', firstName: 'Jane'));
  });

  /// Pumps [screen] as the second route, so popping it is observable.
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<AppNavigator>.value(
        value: navigator,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => screen)),
                  child: const Text('previous screen'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('previous screen'));
    await settle(tester);
  }

  group('community page', () {
    Future<void> pumpCommunity(WidgetTester tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => CommunityCubit(
            challengeGroupsRepository: groups,
            analytics: analytics,
            session: session,
          )..load(),
          child: const CommunityPage(),
        ),
      );
    }

    testWidgets('empty state, then groups that open on tap', (tester) async {
      await pumpCommunity(tester);
      groups.myGroups.add([]);
      await tester.pump();
      expect(find.textContaining("You're not in a challenge group yet"),
          findsOneWidget);

      groups.myGroups.add([
        buildGroup(memberIds: ['user-1', 'u2'])
      ]);
      await tester.pump();
      expect(find.text('Morning Readers'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);

      await tester.tap(find.byType(GroupCard));
      verify(() => navigator.openChallengeGroup('ABC234')).called(1);
    });

    testWidgets('create a group: validates, creates and opens it',
        (tester) async {
      await pumpCommunity(tester);

      await tester.tap(find.text('Create group'));
      await settle(tester);
      final create = find.widgetWithText(FilledButton, 'Create');
      expect(tester.widget<FilledButton>(create).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('group-name')), 'Night Owls');
      await tester.enterText(
          find.byKey(const Key('group-description')), 'Late readers');
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(
          find.textContaining('Anyone can find and join it'), findsOneWidget);
      await tester.tap(create);
      await settle(tester);

      expect(groups.created.single,
          (name: 'Night Owls', description: 'Late readers', isPublic: true));
      expect(find.text('Create a challenge group'), findsNothing);
      verify(() => navigator.openChallengeGroup('NEW234')).called(1);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('join with a code: shows errors in the sheet', (tester) async {
      groups.failOn('joinWithCode', ChallengeGroupException.codeNotFound);
      await pumpCommunity(tester);

      await tester.tap(find.text('Join with code'));
      await settle(tester);
      final codeField = find.descendant(
          of: find.byType(BottomSheet), matching: find.byType(TextField));
      await tester.enterText(codeField, 'abc230');
      await tester.pump();
      expect(
          find.text('Group codes are 6 letters and numbers'), findsOneWidget);

      await tester.enterText(codeField, 'abc234');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await settle(tester);

      expect(groups.joinedCodes, isEmpty);
      expect(find.text(ChallengeGroupException.codeNotFound.message),
          findsOneWidget);
      expect(find.text('Join a challenge group'), findsOneWidget);
      verifyNever(() => navigator.openChallengeGroup(any()));

      groups.succeedOn('joinWithCode');
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await settle(tester);
      expect(groups.joinedCodes, ['ABC234']);
      verify(() => navigator.openChallengeGroup('ABC234')).called(1);
    });

    testWidgets('find a group: browse, search and join', (tester) async {
      groups.publicGroups[''] = [
        buildGroup(
          id: 'MOR234',
          name: 'Morning Glory',
          description: 'Before work',
          isPublic: true,
          memberIds: ['u2'],
        ),
        buildGroup(id: 'MIN234', name: 'Mine', isPublic: true),
      ];
      groups.publicGroups['owl'] = [
        buildGroup(
          id: 'OWL234',
          name: 'Night Owls',
          isPublic: true,
          memberIds: ['u3'],
        ),
      ];
      await pumpCommunity(tester);

      expect(find.text('Find a group'), findsOneWidget);
      expect(find.text('Before work'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Open'), findsOneWidget,
          reason: 'already a member of Mine');

      await tester.enterText(find.byKey(const Key('find-group-search')), 'owl');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(groups.publicQueries.last, 'owl');
      expect(find.text('Night Owls'), findsOneWidget);
      expect(find.text('Morning Glory'), findsNothing);

      final join = find.widgetWithText(FilledButton, 'Join');
      await tester.ensureVisible(join);
      await tester.tap(join);
      await settle(tester);
      expect(groups.joinedCodes, ['OWL234']);
      verify(() => navigator.openChallengeGroup('OWL234')).called(1);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('admins can delete a public group', (tester) async {
      session = FakeSession(buildUser(id: 'user-1', isAdmin: true));
      groups.publicGroups[''] = [
        buildGroup(
            id: 'BAD234', name: 'Spam', isPublic: true, memberIds: ['u2']),
      ];
      await pumpCommunity(tester);

      final delete = find.byTooltip('Delete group');
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await settle(tester);

      expect(groups.deleted, ['BAD234']);
      expect(find.text('Spam'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('accept and decline invites', (tester) async {
      await pumpCommunity(tester);
      final a = buildGroup(
          id: 'AAA222',
          name: 'Alpha',
          memberIds: ['u2'],
          invitedIds: ['user-1']);
      final b = buildGroup(
          id: 'BBB222',
          name: 'Beta',
          memberIds: ['u2'],
          invitedIds: ['user-1']);
      groups.myInvites.add([a, b]);
      await tester.pump();
      expect(find.text('Jane Doe invited you · 1 member'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(FilledButton, 'Accept').first);
      await tester.pump();
      expect(groups.accepted, ['AAA222']);
      expect(find.text('Alpha'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'Decline'));
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await settle(tester);
      expect(groups.declined, ['BBB222']);
      expect(find.byType(InviteCard), findsNothing);
      // Let the toasts expire.
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('challenge group page', () {
    late FakeAchievementsRepository achievements;
    late FakeBibleSeriesRepository series;

    setUp(() {
      achievements = FakeAchievementsRepository();
      series = FakeBibleSeriesRepository()
        ..hasActive = true
        ..seriesList = [
          buildSeries(days: [
            for (var d = -2; d <= 2; d++) DateTime.now().add(Duration(days: d)),
          ]),
        ];
    });

    Future<void> pumpGroup(WidgetTester tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => ChallengeGroupCubit(
            groupId: 'ABC234',
            challengeGroupsRepository: groups,
            achievementsRepository: achievements,
            bibleSeriesRepository: series,
            analytics: analytics,
            session: session,
          )..load(),
          child: const ChallengeGroupPage(),
        ),
      );
      groups.group.add(buildGroup(memberIds: ['user-1', 'u2']));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows progress and nudges a member', (tester) async {
      await pumpGroup(tester);
      achievements.userController('u2').add(
            const Achievements(seriesProgress: 30),
          );
      await tester.pump();
      await tester.pump();

      expect(find.text('user-1 Member (You)'), findsOneWidget);
      expect(find.textContaining('30% complete'), findsOneWidget);
      expect(find.byType(GroupProgressBar), findsNWidgets(2));
      expect(find.byTooltip('Nudge user-1'), findsNothing);

      await tester.tap(find.byTooltip('Nudge u2'));
      await tester.pump();
      await tester.pump();
      expect(groups.nudged, [('ABC234', 'u2')]);
      expect(find.byTooltip('Nudge u2'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('without an active series, no progress is shown',
        (tester) async {
      series.hasActive = false;
      await pumpGroup(tester);

      expect(find.textContaining('No Bible series is running right now'),
          findsOneWidget);
      expect(find.text('user-1 Member (You)'), findsOneWidget);
      expect(find.byType(GroupProgressBar), findsNothing);
      expect(find.textContaining('% complete'), findsNothing);
      expect(find.text('Progress unavailable'), findsNothing);
      // Nudging still works.
      expect(find.byTooltip('Nudge u2'), findsOneWidget);
    });

    testWidgets('shows the description and lets the creator edit',
        (tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => ChallengeGroupCubit(
            groupId: 'ABC234',
            challengeGroupsRepository: groups,
            achievementsRepository: achievements,
            bibleSeriesRepository: series,
            analytics: analytics,
            session: session,
          )..load(),
          child: const ChallengeGroupPage(),
        ),
      );
      groups.group.add(buildGroup(
        memberIds: ['user-1', 'u2'],
        description: 'Before work',
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text('Before work'), findsOneWidget);
      expect(find.textContaining('Private: join by invite'), findsOneWidget);

      await tester.tap(find.byTooltip('Group options'));
      await settle(tester);
      await tester.tap(find.text('Edit group'));
      await settle(tester);
      expect(find.widgetWithText(TextField, 'Morning Readers'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('group-description')), 'Early birds');
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      expect(groups.updated.single, (
        id: 'ABC234',
        name: 'Morning Readers',
        description: 'Early birds',
        isPublic: true,
      ));
      expect(find.text('Edit group'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('invite opens the invite screen', (tester) async {
      await pumpGroup(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Invite'));
      verify(() => navigator.openInviteMembers('ABC234')).called(1);
    });

    testWidgets('the last owner chooses the next owner before leaving',
        (tester) async {
      await pumpGroup(tester);

      await tester.tap(find.byTooltip('Group options'));
      await settle(tester);
      await tester.tap(find.text('Leave group'));
      await settle(tester);
      expect(find.text('Choose the next owner'), findsOneWidget);
      final leave = find.widgetWithText(FilledButton, 'Leave group');
      expect(tester.widget<FilledButton>(leave).onPressed, isNull);

      await tester.tap(find.descendant(
          of: find.byType(ChooseNextOwnerSheet),
          matching: find.text('u2 Member')));
      await tester.pump();
      await tester.tap(leave);
      await settle(tester);

      expect(groups.leftNewOwners, ['u2']);
      expect(find.text('previous screen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('owners see badges and can remove or promote members',
        (tester) async {
      await pumpGroup(tester);
      groups.group.add(buildGroup(memberIds: ['user-1', 'u2', 'u3']));
      await tester.pump();
      await tester.pump();
      expect(find.text('Owner'), findsOneWidget);

      await tester.tap(find.byTooltip('Options for u2'));
      await settle(tester);
      await tester.tap(find.text('Remove from group'));
      await settle(tester);
      expect(find.textContaining('Remove u2 Member from Morning Readers?'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await settle(tester);
      expect(groups.removedMembers, ['u2']);

      await tester.tap(find.byTooltip('Options for u3'));
      await settle(tester);
      await tester.tap(find.text('Make owner'));
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await settle(tester);
      expect(groups.madeOwners, ['u3']);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a member leaves after confirming', (tester) async {
      await pumpGroup(tester);
      groups.group.add(buildGroup(
        memberIds: ['user-1', 'u2'],
        ownerIds: ['u2'],
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byTooltip('Options for u2'), findsNothing);

      await tester.tap(find.byTooltip('Group options'));
      await settle(tester);
      await tester.tap(find.text('Leave group'));
      await settle(tester);
      expect(find.textContaining('Leave Morning Readers?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await settle(tester);

      expect(groups.left, ['ABC234']);
      expect(find.text('previous screen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('an owner deletes the group after confirming', (tester) async {
      await pumpGroup(tester);

      await tester.tap(find.byTooltip('Group options'));
      await settle(tester);
      await tester.tap(find.text('Delete group'));
      await settle(tester);
      expect(
        find.text('Delete Morning Readers for everyone? 1 other member will '
            'lose access, and pending invites are cancelled. This cannot be '
            'undone.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await settle(tester);

      expect(groups.deleted, ['ABC234']);
      expect(find.text('previous screen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('members do not see Delete group', (tester) async {
      await pumpGroup(tester);
      groups.group.add(buildGroup(
        memberIds: ['user-1', 'u2'],
        ownerIds: ['u2'],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('Group options'));
      await settle(tester);
      expect(find.text('Leave group'), findsOneWidget);
      expect(find.text('Delete group'), findsNothing);
    });
  });

  group('invite members page', () {
    testWidgets('search, pick and invite', (tester) async {
      groups.storedGroup = buildGroup(memberIds: ['user-1', 'u2']);
      final directory = FakeUserDirectoryRepository()
        ..results['ma'] = [
          buildDirectoryUser('u2', firstName: 'Mary'),
          buildDirectoryUser('u7', firstName: 'Mark'),
        ];
      await pump(
        tester,
        BlocProvider(
          create: (_) => InviteMembersCubit(
            groupId: 'ABC234',
            challengeGroupsRepository: groups,
            userDirectoryRepository: directory,
            analytics: analytics,
            debounce: Duration.zero,
          )..load(),
          child: const InviteMembersPage(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ma');
      await tester.pump();
      await tester.pump();

      // A member can't be picked.
      await tester.tap(find.text('Mary Person'));
      await tester.pump();
      await tester.tap(find.text('Mark Person'));
      await tester.pump();
      expect(find.text('Invite (1)'), findsOneWidget);
      expect(find.byType(InputChip), findsOneWidget);

      await tester.tap(find.text('Invite (1)'));
      await settle(tester);

      expect(groups.invited.single.$2.map((u) => u.id), ['u7']);
      expect(find.text('previous screen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
