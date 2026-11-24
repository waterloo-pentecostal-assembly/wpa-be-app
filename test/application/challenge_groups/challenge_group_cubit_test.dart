import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/challenge_groups/challenge_group_cubit.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/domain/achievements/entities.dart';
import 'package:wpa_app/domain/challenge_groups/exceptions.dart';
import 'package:wpa_app/domain/challenge_groups/policies.dart';
import 'package:wpa_app/domain/common/analytics.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeChallengeGroupsRepository groups;
  late FakeAchievementsRepository achievements;
  late FakeBibleSeriesRepository series;
  late FakeAnalytics analytics;
  // Day 5 of a 10-day series.
  final now = DateTime(2024, 3, 5, 9);

  setUp(() {
    groups = FakeChallengeGroupsRepository();
    achievements = FakeAchievementsRepository();
    series = FakeBibleSeriesRepository()
      ..hasActive = true
      ..seriesList = [
        buildSeries(days: [for (var d = 1; d <= 10; d++) DateTime(2024, 3, d)]),
      ];
    analytics = FakeAnalytics();
  });

  ChallengeGroupCubit build() {
    final cubit = ChallengeGroupCubit(
      groupId: 'ABC234',
      challengeGroupsRepository: groups,
      achievementsRepository: achievements,
      bibleSeriesRepository: series,
      analytics: analytics,
      session: FakeSession(buildUser(id: 'user-1')),
      clock: () => now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void progress(String userId, int value) =>
      achievements.userController(userId).add(
            Achievements(seriesProgress: value),
          );

  final threeMembers = buildGroup(memberIds: ['user-1', 'u2', 'u3']);

  Future<ChallengeGroupCubit> loaded() async {
    final cubit = build();
    unawaited(cubit.load());
    await settle();
    groups.group.add(threeMembers);
    await settle();
    return cubit;
  }

  group('load', () {
    test('shows the group and the series target', () async {
      final cubit = await loaded();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.group, threeMembers);
      expect(
        cubit.state.target,
        const SeriesTarget(
            seriesTitle: 'Series series-1', totalDays: 10, startedDays: 5),
      );
    });

    test('watches every member and ranks them by progress', () async {
      final cubit = await loaded();
      expect(achievements.watchedUserIds, {'user-1', 'u2', 'u3'});

      progress('user-1', 40);
      progress('u2', 60);
      await settle();

      final rows = cubit.state.rows;
      expect(rows.map((r) => r.member.userId), ['u2', 'user-1', 'u3']);
      expect(rows[0].pace, MemberPace.onTrack);
      expect(rows[1].isMe, isTrue);
      expect(rows[1].canNudge, isFalse, reason: 'cannot nudge yourself');
      expect(rows[2].progress, isNull, reason: 'unknown until it loads');
      expect(rows[2].pace, isNull);
      expect(rows[2].canNudge, isTrue);
    });

    test('marks members who missed days as behind', () async {
      final cubit = await loaded();
      progress('u2', 20); // 2 of 10 days, 5 started.
      await settle();
      final row = cubit.state.rows.firstWhere((r) => r.member.userId == 'u2');
      expect(row.pace, MemberPace.behind);
      expect(row.daysBehind, 2);
    });

    test('follows members joining and leaving', () async {
      final cubit = await loaded();
      progress('u3', 50);
      await settle();

      groups.group.add(buildGroup(memberIds: ['user-1', 'u2', 'u4']));
      await settle();

      expect(achievements.watchedUserIds, {'user-1', 'u2', 'u4'});
      expect(cubit.state.progress.containsKey('u3'), isFalse);
    });

    test('a progress error leaves that member unknown', () async {
      final cubit = await loaded();
      achievements.userController('u2').addError(kFakeError);
      progress('u3', 30);
      await settle();
      expect(cubit.state.progress, {'u3': 30});
      expect(cubit.state.status, LoadStatus.success);
    });

    test('without an active series no progress is read or shown', () async {
      series.hasActive = false;
      final cubit = await loaded();

      expect(cubit.state.activeSeries, ActiveSeries.none);
      expect(cubit.state.showsProgress, isFalse);
      expect(cubit.state.target, isNull);
      expect(achievements.watchedUserIds, isEmpty);
      expect(achievements.calls.contains('watchUserAchievements'), isFalse);
      final rows = cubit.state.rows;
      expect(rows.every((r) => r.progress == null && r.pace == null), isTrue);
      // Ordered by name only.
      expect(rows.map((r) => r.member.userId), ['u2', 'u3', 'user-1']);
    });

    test('if the series cannot be loaded, progress shows without a target',
        () async {
      series.failOn('hasActiveBibleSeries');
      final cubit = await loaded();
      progress('u2', 20);
      await settle();

      expect(cubit.state.activeSeries, ActiveSeries.unknown);
      expect(cubit.state.target, isNull);
      final row = cubit.state.rows.firstWhere((r) => r.member.userId == 'u2');
      expect(row.progress, 20);
      expect(row.pace, isNull);
    });

    test('progress is read only once the series is known', () async {
      final cubit = build();
      expect(cubit.state.activeSeries, ActiveSeries.loading);
      expect(cubit.state.showsProgress, isFalse);
      unawaited(cubit.load());
      await settle();
      groups.group.add(threeMembers);
      await settle();
      expect(cubit.state.activeSeries, ActiveSeries.active);
      expect(achievements.watchedUserIds, {'user-1', 'u2', 'u3'});
    });

    test('a deleted group shows an error', () async {
      final cubit = await loaded();
      groups.group.add(null);
      await settle();
      expect(cubit.state.status, LoadStatus.failure);
      expect(
          cubit.state.errorMessage, ChallengeGroupException.notFound.message);
      expect(achievements.watchedUserIds, isEmpty);
    });

    test('a group I am not in shows an error', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.add(buildGroup(memberIds: ['u2']));
      await settle();
      expect(cubit.state.status, LoadStatus.failure);
      expect(
          cubit.state.errorMessage, ChallengeGroupException.notMember.message);
    });

    test('a stream error fails the screen', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.addError(kFakeError);
      await settle();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'Fake failure');
    });
  });

  group('nudge', () {
    test('sends the nudge once and confirms it', () async {
      final cubit = await loaded();
      groups.nudgeGate = Completer<void>();

      final pending = cubit.nudge('u2');
      await settle();
      var row = cubit.state.rows.firstWhere((r) => r.member.userId == 'u2');
      expect(row.isNudging, isTrue);
      expect(row.canNudge, isFalse);

      groups.nudgeGate!.complete();
      await pending;

      row = cubit.state.rows.firstWhere((r) => r.member.userId == 'u2');
      expect(groups.nudged, [('ABC234', 'u2')]);
      expect(row.wasNudged, isTrue);
      expect(row.canNudge, isFalse);
      expect(cubit.state.message, 'Nudge sent to u2');
      expect(analytics.names, [AnalyticsEvents.challengeGroupMemberNudged]);

      await cubit.nudge('u2');
      expect(groups.callCount('nudgeMember'), 1);
    });

    test('cannot nudge yourself or non-members', () async {
      final cubit = await loaded();
      await cubit.nudge('user-1');
      await cubit.nudge('stranger');
      expect(groups.calls.contains('nudgeMember'), isFalse);
    });

    test('a failure shows the error and allows a retry', () async {
      groups.failOn('nudgeMember');
      final cubit = await loaded();

      await cubit.nudge('u2');

      expect(cubit.state.messageKind, ChallengeGroupMessageKind.error);
      expect(cubit.state.message, 'Fake failure');
      final row = cubit.state.rows.firstWhere((r) => r.member.userId == 'u2');
      expect(row.canNudge, isTrue);
      expect(analytics.names, isEmpty);
    });
  });

  group('leave', () {
    test('the last owner hands the group over and leaves', () async {
      final cubit = await loaded();
      expect(cubit.state.needsSuccessor, isTrue);
      expect(
          cubit.state.successorCandidates.map((m) => m.userId), ['u2', 'u3']);

      await cubit.leave(newOwnerId: 'u2');

      expect(groups.left, ['ABC234']);
      expect(groups.leftNewOwners, ['u2']);
      expect(cubit.state.leftEffectId, isNot(0));
      expect(cubit.state.message, 'You left Morning Readers');
      expect(analytics.names, [AnalyticsEvents.challengeGroupLeft]);
      expect(achievements.watchedUserIds, isEmpty);

      // The group update that follows does not flash an error.
      groups.group.add(null);
      await settle();
      expect(cubit.state.status, LoadStatus.success);
    });

    test('the last owner cannot leave without choosing the next owner',
        () async {
      final cubit = await loaded();
      await cubit.leave();
      await cubit.leave(newOwnerId: 'stranger');
      expect(groups.left, isEmpty);
      expect(cubit.state.message,
          ChallengeGroupException.successorRequired.message);
      expect(cubit.state.isLeaving, isFalse);
    });

    test('members and owners with co-owners just leave', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.add(buildGroup(
        memberIds: ['user-1', 'u2'],
        ownerIds: ['user-1', 'u2'],
      ));
      await settle();
      expect(cubit.state.needsSuccessor, isFalse);

      await cubit.leave(newOwnerId: 'u2');

      expect(groups.leftNewOwners, [null]);
    });

    test('a failure keeps the user in the group', () async {
      groups.failOn('leaveGroup');
      final cubit = await loaded();

      await cubit.leave(newOwnerId: 'u2');

      expect(cubit.state.isLeaving, isFalse);
      expect(cubit.state.leftEffectId, 0);
      expect(cubit.state.messageKind, ChallengeGroupMessageKind.error);
    });
  });

  group('delete', () {
    test('an owner deletes the group and the screen closes', () async {
      final cubit = await loaded();
      expect(cubit.state.canDelete, isTrue);

      await cubit.delete();

      expect(groups.deleted, ['ABC234']);
      expect(cubit.state.leftEffectId, isNot(0));
      expect(cubit.state.message, 'Deleted Morning Readers');
      expect(analytics.names, [AnalyticsEvents.challengeGroupDeletedByOwner]);
      expect(achievements.watchedUserIds, isEmpty);

      // The group disappearing does not flash an error.
      groups.group.add(null);
      await settle();
      expect(cubit.state.status, LoadStatus.success);
    });

    test('any owner can delete, members cannot', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.add(buildGroup(
        memberIds: ['u2', 'user-1', 'u3'],
        ownerIds: ['u2'],
      ));
      await settle();
      expect(cubit.state.canDelete, isFalse);
      await cubit.delete();
      expect(groups.deleted, isEmpty);

      groups.group.add(buildGroup(
        memberIds: ['u2', 'user-1', 'u3'],
        ownerIds: ['u2', 'user-1'],
      ));
      await settle();
      expect(cubit.state.canDelete, isTrue);
    });

    test('a failure keeps the group and shows the error', () async {
      groups.failOn('deleteGroup');
      final cubit = await loaded();

      await cubit.delete();

      expect(cubit.state.isDeleting, isFalse);
      expect(cubit.state.canDelete, isTrue);
      expect(cubit.state.leftEffectId, 0);
      expect(cubit.state.messageKind, ChallengeGroupMessageKind.error);
    });
  });

  test('canInvite reflects open seats', () async {
    final cubit = await loaded();
    expect(cubit.state.canInvite, isTrue);
    groups.group.add(buildGroup(memberIds: [
      'user-1',
      for (var i = 0; i < 19; i++) 'm$i',
    ]));
    await settle();
    expect(cubit.state.canInvite, isFalse);
  });

  group('edit', () {
    test('the creator saves new details', () async {
      final cubit = await loaded();
      expect(cubit.state.canEdit, isTrue);

      final error = await cubit.updateGroup(
        name: 'Night Owls',
        description: 'Late readers',
        isPublic: true,
      );

      expect(error, isNull);
      expect(groups.updated.single, (
        id: 'ABC234',
        name: 'Night Owls',
        description: 'Late readers',
        isPublic: true,
      ));
      expect(cubit.state.message, 'Group updated');
      expect(analytics.names, [AnalyticsEvents.challengeGroupEdited]);
    });

    test('other members cannot edit', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.add(buildGroup(memberIds: ['u2', 'user-1']));
      await settle();

      expect(cubit.state.canEdit, isFalse);
      expect(
        await cubit.updateGroup(name: 'X', description: '', isPublic: true),
        ChallengeGroupException.notOwner.message,
      );
      expect(groups.updated, isEmpty);
    });

    test('validates before saving', () async {
      final cubit = await loaded();
      expect(
        await cubit.updateGroup(name: ' ', description: '', isPublic: false),
        'Enter a group name',
      );
      expect(groups.updated, isEmpty);
    });
  });

  group('owners', () {
    test('rows show owners and what an owner may do', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.add(buildGroup(
        memberIds: ['user-1', 'u2', 'u3'],
        ownerIds: ['user-1', 'u3'],
      ));
      await settle();

      final rows = {for (final r in cubit.state.rows) r.member.userId: r};
      expect(rows['user-1']!.isOwner, isTrue);
      expect(rows['user-1']!.canRemove, isFalse, reason: 'yourself');
      expect(rows['u2']!.canRemove, isTrue);
      expect(rows['u2']!.canMakeOwner, isTrue);
      expect(rows['u3']!.isOwner, isTrue);
      expect(rows['u3']!.canRemove, isFalse, reason: 'another owner');
      expect(rows['u3']!.canMakeOwner, isFalse);
    });

    test('non-owners can do neither', () async {
      final cubit = build();
      unawaited(cubit.load());
      await settle();
      groups.group.add(buildGroup(memberIds: ['u2', 'user-1', 'u3']));
      await settle();

      expect(cubit.state.isOwner, isFalse);
      expect(
          cubit.state.rows.any((r) => r.canRemove || r.canMakeOwner), isFalse);
      await cubit.removeMember('u3');
      await cubit.makeOwner('u3');
      expect(groups.removedMembers, isEmpty);
      expect(groups.madeOwners, isEmpty);
    });

    test('remove a member', () async {
      final cubit = await loaded();

      final pending = cubit.removeMember('u2');
      final row = cubit.state.rows.firstWhere((r) => r.member.userId == 'u2');
      expect(row.isUpdating, isTrue);
      expect(row.canRemove, isFalse);
      await pending;

      expect(groups.removedMembers, ['u2']);
      expect(cubit.state.message, 'u2 was removed');
      expect(cubit.state.updatingIds, isEmpty);
      expect(analytics.names, [AnalyticsEvents.challengeGroupMemberRemoved]);
    });

    test('make an owner', () async {
      final cubit = await loaded();
      await cubit.makeOwner('u3');
      expect(groups.madeOwners, ['u3']);
      expect(cubit.state.message, 'u3 is now an owner');
      expect(analytics.names, [AnalyticsEvents.challengeGroupOwnerAdded]);
    });

    test('a failure shows the error', () async {
      groups.failOn('removeMember', ChallengeGroupException.cannotRemoveOwner);
      final cubit = await loaded();
      await cubit.removeMember('u2');
      expect(cubit.state.messageKind, ChallengeGroupMessageKind.error);
      expect(cubit.state.message, "Owners can't be removed");
    });
  });
}
