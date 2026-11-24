import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/authentication/form_status.dart';
import 'package:wpa_app/application/challenge_groups/invite_members_cubit.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/domain/challenge_groups/exceptions.dart';
import 'package:wpa_app/domain/challenge_groups/rules.dart';
import 'package:wpa_app/domain/common/analytics.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeChallengeGroupsRepository groups;
  late FakeUserDirectoryRepository directory;
  late FakeAnalytics analytics;

  setUp(() {
    groups = FakeChallengeGroupsRepository()
      ..storedGroup =
          buildGroup(memberIds: ['user-1', 'u2'], invitedIds: ['u3']);
    directory = FakeUserDirectoryRepository();
    analytics = FakeAnalytics();
  });

  InviteMembersCubit build({Duration debounce = Duration.zero}) {
    final cubit = InviteMembersCubit(
      groupId: 'ABC234',
      challengeGroupsRepository: groups,
      userDirectoryRepository: directory,
      analytics: analytics,
      debounce: debounce,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('load reads the group', () async {
    final cubit = build();
    await cubit.load();
    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.group, groups.storedGroup);
    expect(cubit.state.openSeats, kMaxChallengeGroupMembers - 3);
  });

  test('a missing group fails', () async {
    groups.storedGroup = null;
    final cubit = build();
    await cubit.load();
    expect(cubit.state.status, LoadStatus.failure);
    expect(cubit.state.errorMessage, ChallengeGroupException.notFound.message);
  });

  group('search', () {
    test('waits for two letters', () async {
      final cubit = build();
      cubit.queryChanged('m');
      await settle();
      expect(cubit.state.searchStatus, LoadStatus.initial);
      expect(cubit.state.isSearchable, isFalse);
      expect(directory.queries, isEmpty);
    });

    test('debounces keystrokes and searches the last query', () async {
      directory.results['mar'] = [buildDirectoryUser('u9')];
      final cubit = build(debounce: const Duration(milliseconds: 40));
      cubit.queryChanged('ma');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cubit.queryChanged('mar');
      expect(cubit.state.searchStatus, LoadStatus.loading);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(directory.queries, ['mar']);
      expect(cubit.state.searchStatus, LoadStatus.success);
      expect(cubit.state.results, [buildDirectoryUser('u9')]);
    });

    test('shortening the query clears the results', () async {
      directory.results['mar'] = [buildDirectoryUser('u9')];
      final cubit = build();
      cubit.queryChanged('mar');
      await settle();
      await settle();
      expect(cubit.state.results, hasLength(1));

      cubit.queryChanged('m');
      expect(cubit.state.results, isEmpty);
      expect(cubit.state.searchStatus, LoadStatus.initial);
    });

    test('a failure shows an error', () async {
      directory.failOn('search');
      final cubit = build();
      cubit.queryChanged('mar');
      await settle();
      await settle();
      expect(cubit.state.searchStatus, LoadStatus.failure);
      expect(cubit.state.searchError, 'Fake failure');
    });
  });

  group('selection', () {
    test('members and invitees cannot be picked', () async {
      final cubit = build();
      await cubit.load();
      final member = buildDirectoryUser('u2');
      final invitee = buildDirectoryUser('u3');
      final other = buildDirectoryUser('u4');

      expect(cubit.state.statusOf(member), InviteCandidateStatus.member);
      expect(cubit.state.statusOf(invitee), InviteCandidateStatus.invited);
      cubit
        ..toggle(member)
        ..toggle(invitee)
        ..toggle(other);
      expect(cubit.state.selected, [other]);
      expect(cubit.state.statusOf(other), InviteCandidateStatus.selected);

      cubit.toggle(other);
      expect(cubit.state.selected, isEmpty);
    });

    test('stops at the open seats', () async {
      groups.storedGroup = buildGroup(memberIds: [
        'user-1',
        for (var i = 0; i < kMaxChallengeGroupMembers - 2; i++) 'm$i',
      ]);
      final cubit = build();
      await cubit.load();

      cubit
        ..toggle(buildDirectoryUser('a'))
        ..toggle(buildDirectoryUser('b'));
      expect(cubit.state.openSeats, 0);
      expect(cubit.state.selected, hasLength(1));
      expect(cubit.state.message, 'This group is full');
    });
  });

  group('submit', () {
    test('invites the selected people', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.canSubmit, isFalse);
      final a = buildDirectoryUser('a');
      final b = buildDirectoryUser('b');
      cubit
        ..toggle(a)
        ..toggle(b);

      await cubit.submit();

      expect(groups.invited.single.$1, 'ABC234');
      expect(groups.invited.single.$2, [a, b]);
      expect(cubit.state.submitStatus, FormStatus.success);
      expect(analytics.events.single.name,
          AnalyticsEvents.challengeGroupInvitesSent);
      expect(analytics.events.single.params, {'count': 2});
    });

    test('a failure keeps the selection and shows an error', () async {
      groups.failOn('inviteMembers', ChallengeGroupException.groupFull);
      final cubit = build();
      await cubit.load();
      cubit.toggle(buildDirectoryUser('a'));

      await cubit.submit();

      expect(cubit.state.submitStatus, FormStatus.failure);
      expect(cubit.state.selected, hasLength(1));
      expect(cubit.state.message, 'This group is full');
      expect(cubit.state.canSubmit, isTrue);
    });
  });
}
