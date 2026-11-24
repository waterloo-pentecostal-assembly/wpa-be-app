import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/challenge_groups/community_cubit.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/domain/challenge_groups/exceptions.dart';
import 'package:wpa_app/domain/common/analytics.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeChallengeGroupsRepository repository;
  late FakeAnalytics analytics;

  setUp(() {
    repository = FakeChallengeGroupsRepository();
    analytics = FakeAnalytics();
  });

  CommunityCubit build() {
    final cubit = CommunityCubit(
      challengeGroupsRepository: repository,
      analytics: analytics,
      session: FakeSession(buildUser(id: 'user-1')),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('load', () {
    test('streams my groups and invites', () async {
      final cubit = build();
      unawaited(cubit.load());
      expect(cubit.state.status, LoadStatus.loading);
      await settle();

      final group = buildGroup();
      final invited =
          buildGroup(id: 'INV234', memberIds: ['u2'], invitedIds: ['user-1']);
      repository.myGroups.add([group]);
      repository.myInvites.add([invited]);
      await settle();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.groups, [group]);
      expect(cubit.state.invites, [invited]);
      expect(cubit.state.inviteFor(invited)?.invitedByName, 'Jane Doe');
    });

    test('a groups error fails the screen; an invites error does not',
        () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      repository.myInvites.addError(kFakeError);
      await settle();
      expect(cubit.state.status, LoadStatus.loading);

      repository.myGroups.addError(kFakeError);
      await settle();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'Fake failure');
    });
  });

  group('createGroup', () {
    test('creates the group and opens it', () async {
      final cubit = build();
      final error = await cubit.createGroup(name: '  Readers ');

      expect(error, isNull);
      expect(repository.createdNames, ['Readers']);
      expect(cubit.state.openGroupId, 'NEW234');
      expect(cubit.state.openGroupEffectId, isNot(0));
      expect(cubit.state.message, 'Group created');
      expect(analytics.names, [AnalyticsEvents.challengeGroupCreated]);
      expect(repository.created.single,
          (name: 'Readers', description: '', isPublic: false));
    });

    test('a public group with a description refreshes Find a group', () async {
      final cubit = build();
      expect(
        await cubit.createGroup(
          name: 'Readers',
          description: ' Early birds ',
          isPublic: true,
        ),
        isNull,
      );
      await settle();
      expect(repository.created.single,
          (name: 'Readers', description: 'Early birds', isPublic: true));
      expect(analytics.events.single.params, {'is_public': 1});
      expect(repository.callCount('findPublicGroups'), 1);
    });

    test('validates the name and description first', () async {
      final cubit = build();
      expect(await cubit.createGroup(name: '  '), 'Enter a group name');
      expect(
        await cubit.createGroup(name: 'Readers', description: 'x' * 201),
        'Use at most 200 characters',
      );
      expect(repository.calls, isEmpty);
    });

    test('returns the failure for the form', () async {
      repository.failOn('createGroup');
      final cubit = build();
      expect(await cubit.createGroup(name: 'Readers'), 'Fake failure');
      expect(cubit.state.openGroupId, isNull);
    });
  });

  group('joinWithCode', () {
    test('normalizes the code, joins and opens the group', () async {
      final cubit = build();
      expect(await cubit.joinWithCode(' abc-234 '), isNull);
      expect(repository.joinedCodes, ['ABC234']);
      expect(cubit.state.openGroupId, 'ABC234');
      expect(analytics.names, [AnalyticsEvents.challengeGroupJoinedWithCode]);
    });

    test('rejects malformed codes without a call', () async {
      final cubit = build();
      expect(await cubit.joinWithCode('abc'),
          'Group codes are 6 letters and numbers');
      expect(repository.calls, isEmpty);
    });

    test('shows the repository message for unknown codes', () async {
      repository.failOn('joinWithCode', ChallengeGroupException.codeNotFound);
      final cubit = build();
      expect(await cubit.joinWithCode('ZZZ222'),
          ChallengeGroupException.codeNotFound.message);
    });
  });

  group('code validation helpers', () {
    test('incomplete codes are not errors yet', () {
      expect(CommunityCubit.codeError('AB'), '');
      expect(CommunityCubit.isCompleteCode('AB'), isFalse);
    });

    test('complete codes are checked against the alphabet', () {
      expect(CommunityCubit.codeError('ABC230'), isNotEmpty);
      expect(CommunityCubit.codeError('abc 234'), '');
      expect(CommunityCubit.isCompleteCode('abc 234'), isTrue);
    });
  });

  group('invites', () {
    final invited =
        buildGroup(id: 'INV234', memberIds: ['u2'], invitedIds: ['user-1']);

    test('accepting joins the group and drops the invite', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      repository.myInvites.add([invited]);
      await settle();

      final pending = cubit.acceptInvite(invited);
      expect(cubit.state.pendingInviteIds, {'INV234'});
      await pending;

      expect(repository.accepted, ['INV234']);
      expect(cubit.state.invites, isEmpty);
      expect(cubit.state.pendingInviteIds, isEmpty);
      expect(cubit.state.message, 'You joined Morning Readers');
      expect(cubit.state.messageKind, CommunityMessageKind.info);
      expect(analytics.names, [AnalyticsEvents.challengeGroupInviteAccepted]);
    });

    test('declining removes the invite', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      repository.myInvites.add([invited]);
      await settle();

      await cubit.declineInvite(invited);

      expect(repository.declined, ['INV234']);
      expect(cubit.state.invites, isEmpty);
      expect(cubit.state.message, 'Invite declined');
      expect(analytics.names, [AnalyticsEvents.challengeGroupInviteDeclined]);
    });

    test('a failure keeps the invite and shows an error', () async {
      repository.failOn('acceptInvite', ChallengeGroupException.groupFull);
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      repository.myInvites.add([invited]);
      await settle();

      await cubit.acceptInvite(invited);

      expect(cubit.state.invites, [invited]);
      expect(cubit.state.pendingInviteIds, isEmpty);
      expect(cubit.state.message, 'This group is full');
      expect(cubit.state.messageKind, CommunityMessageKind.error);
      expect(analytics.names, isEmpty);
    });

    test('a second tap while pending is ignored', () async {
      final cubit = build();
      final first = cubit.acceptInvite(invited);
      await cubit.acceptInvite(invited);
      await first;
      expect(repository.callCount('acceptInvite'), 1);
    });
  });

  group('find a group', () {
    final public = buildGroup(
      id: 'PUB234',
      name: 'Night Owls',
      isPublic: true,
      memberIds: ['u2'],
    );

    test('load lists public groups', () async {
      repository.publicGroups[''] = [public];
      final cubit = build();
      await cubit.load();
      expect(cubit.state.discoverStatus, LoadStatus.success);
      expect(cubit.state.publicGroups, [public]);
      expect(cubit.state.statusOf(public), PublicGroupStatus.joinable);
    });

    test('searching waits for typing to pause and keeps the last query',
        () async {
      repository.publicGroups['owl'] = [public];
      final cubit = CommunityCubit(
        challengeGroupsRepository: repository,
        analytics: analytics,
        session: FakeSession(buildUser(id: 'user-1')),
        searchDebounce: const Duration(milliseconds: 30),
      );
      addTearDown(cubit.close);

      cubit.discoverQueryChanged('ow');
      cubit.discoverQueryChanged('owl');
      expect(cubit.state.discoverStatus, LoadStatus.loading);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(repository.publicQueries, ['owl']);
      expect(cubit.state.publicGroups, [public]);
    });

    test('a search failure shows an error', () async {
      repository.failOn('findPublicGroups');
      final cubit = build();
      await cubit.load();
      expect(cubit.state.discoverStatus, LoadStatus.failure);
      expect(cubit.state.discoverError, 'Fake failure');
    });

    test('joining opens the group and refreshes the list', () async {
      repository.publicGroups[''] = [public];
      final cubit = build();
      await cubit.load();

      final pending = cubit.joinPublicGroup(public);
      expect(cubit.state.statusOf(public), PublicGroupStatus.joining);
      await pending;
      await settle();

      expect(repository.joinedCodes, ['PUB234']);
      expect(cubit.state.openGroupId, 'PUB234');
      expect(cubit.state.message, 'You joined Night Owls');
      expect(analytics.names, [AnalyticsEvents.challengeGroupJoinedPublic]);
      expect(repository.callCount('findPublicGroups'), 2);
      expect(cubit.state.joiningIds, isEmpty);
    });

    test('joined and full groups cannot be joined', () async {
      final cubit = build();
      final mine = buildGroup(isPublic: true, memberIds: ['user-1']);
      final full = buildGroup(
        id: 'FUL234',
        isPublic: true,
        memberIds: [for (var i = 0; i < 20; i++) 'm$i'],
      );
      expect(cubit.state.statusOf(mine), PublicGroupStatus.joined);
      expect(cubit.state.statusOf(full), PublicGroupStatus.full);
      await cubit.joinPublicGroup(mine);
      await cubit.joinPublicGroup(full);
      expect(repository.joinedCodes, isEmpty);
    });

    test('admins can delete a public group; others cannot', () async {
      repository.publicGroups[''] = [public];
      final member = build();
      await member.joinPublicGroup(public);
      await member.deletePublicGroup(public);
      expect(repository.deleted, isEmpty);

      final admin = CommunityCubit(
        challengeGroupsRepository: repository,
        analytics: analytics,
        session: FakeSession(buildUser(id: 'admin', isAdmin: true)),
      );
      addTearDown(admin.close);
      await admin.load();
      await admin.deletePublicGroup(public);

      expect(repository.deleted, ['PUB234']);
      expect(admin.state.publicGroups, isEmpty);
      expect(admin.state.message, 'Group deleted');
    });
  });
}
