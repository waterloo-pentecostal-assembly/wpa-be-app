import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/challenge_groups/entities.dart';
import 'package:wpa_app/domain/challenge_groups/exceptions.dart';
import 'package:wpa_app/domain/common/search.dart';
import 'package:wpa_app/domain/challenge_groups/rules.dart';
import 'package:wpa_app/infrastructure/challenge_groups/challenge_groups_repository.dart';

import '_support/fakes.dart';

/// Always picks alphabet index [indices] in turn, one code per entry.
class _SequenceRandom implements Random {
  _SequenceRandom(this.indices);

  final List<int> indices;
  int _calls = 0;

  @override
  int nextInt(int max) =>
      indices[(_calls++ ~/ kChallengeGroupCodeLength) % indices.length];

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

Map<String, dynamic> person(String first, String last, [String? thumb]) =>
    {'first_name': first, 'last_name': last, 'thumbnail': thumb};

/// A `challenge_groups` document in the shape written by the app.
Map<String, dynamic> groupDoc({
  String name = 'Morning Readers',
  List<String> members = const ['user-1'],
  List<String> invited = const [],
  String? thumbnail,
}) =>
    {
      'name': name,
      'created_by': members.isEmpty ? 'user-1' : members.first,
      'created_at': ts(1),
      'member_ids': members,
      'members': {
        for (final (i, m) in members.indexed)
          m: {
            ...person('First$m', 'Last', i == 0 ? thumbnail : null),
            'joined_at': ts(1 + i),
          },
      },
      'invited_ids': invited,
      'invites': {
        for (final (i, u) in invited.indexed)
          u: {
            ...person('First$u', 'Invitee'),
            'invited_by': members.first,
            'invited_by_name': 'Jane Doe',
            'invited_at': ts(10 + i),
          },
      },
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late ChallengeGroupsRepository repository;
  late List<(String, Map<String, Object?>)> calls;
  Object? callError;

  CollectionReference<Map<String, dynamic>> groups() =>
      firestore.collection('challenge_groups');

  Future<Map<String, dynamic>?> read(String id) async =>
      (await groups().doc(id).get()).data();

  ChallengeGroupsRepository build({Random? random}) =>
      ChallengeGroupsRepository(
        firestore,
        createStorageMock(),
        sessionWith(),
        random: random,
        callFunction: (name, data) async {
          calls.add((name, data));
          if (callError != null) throw callError!;
        },
      );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    calls = [];
    callError = null;
    repository = build();
  });

  group('createGroup', () {
    test('writes a group with the creator as its only member', () async {
      final id = await build(random: _SequenceRandom([0]))
          .createGroup(name: '  Readers  ');

      expect(id, 'AAAAAA');
      final data = await read(id);
      expect(without(data, ['created_at', 'members']), {
        'name': 'Readers',
        'description': '',
        'is_public': false,
        'created_by': 'user-1',
        'owner_ids': ['user-1'],
        'member_ids': ['user-1'],
        'invited_ids': <String>[],
        'invites': <String, dynamic>{},
      });
      expect(data!['created_at'], isA<Timestamp>());
      final member = data['members']['user-1'] as Map<String, dynamic>;
      expect(without(member, ['joined_at']),
          person('Jane', 'Doe', testUser.thumbnail));
      expect(member['joined_at'], isA<Timestamp>());
    });

    test('stores the description and visibility, but no search tokens',
        () async {
      final id = await build(random: _SequenceRandom([0])).createGroup(
        name: 'Night Owls',
        description: ' Late-night readers ',
        isPublic: true,
      );

      final data = (await read(id))!;
      expect(data['description'], 'Late-night readers');
      expect(data['is_public'], isTrue);
      expect(data.containsKey('search_tokens'), isFalse,
          reason: 'written by the backend');
    });

    test('picks another code when one is taken', () async {
      await groups().doc('AAAAAA').set(groupDoc(members: ['someone']));

      final id = await build(random: _SequenceRandom([0, 1]))
          .createGroup(name: 'Readers');

      expect(id, 'BBBBBB');
      expect((await read('AAAAAA'))!['member_ids'], ['someone']);
    });

    test('gives up after repeated collisions', () async {
      await groups().doc('AAAAAA').set(groupDoc(members: ['someone']));

      expect(
        build(random: _SequenceRandom([0])).createGroup(name: 'Readers'),
        throwsA(isA<ChallengeGroupException>().having((e) => e.code, 'code',
            ChallengeGroupExceptionCode.codeUnavailable)),
      );
    });
  });

  group('reading', () {
    test('maps a group document, ordering members and invites', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: ['user-1', 'u2'],
            invited: ['u3'],
            thumbnail: 'gs://thumb.jpg',
          ));

      final group = await repository.getGroup('ABC234');

      expect(
        group,
        ChallengeGroup(
          id: 'ABC234',
          name: 'Morning Readers',
          createdBy: 'user-1',
          // No owner_ids stored: the creator owns it.
          ownerIds: const ['user-1'],
          createdAt: day(1),
          members: [
            GroupMember(
              userId: 'user-1',
              firstName: 'Firstuser-1',
              lastName: 'Last',
              thumbnail: 'gs://thumb.jpg',
              thumbnailUrl: downloadUrlFor('gs://thumb.jpg'),
              joinedAt: day(1),
            ),
            GroupMember(
              userId: 'u2',
              firstName: 'Firstu2',
              lastName: 'Last',
              joinedAt: day(2),
            ),
          ],
          invites: [
            GroupInvite(
              userId: 'u3',
              firstName: 'Firstu3',
              lastName: 'Invitee',
              invitedBy: 'user-1',
              invitedByName: 'Jane Doe',
              invitedAt: day(10),
            ),
          ],
        ),
      );
    });

    test('a missing group reads as null', () async {
      expect(await repository.getGroup('NOPE22'), isNull);
      expect(await repository.watchGroup('NOPE22').first, isNull);
    });

    test('ignores map entries that are not in the id arrays', () async {
      final doc = groupDoc(members: ['user-1']);
      (doc['members'] as Map)['ghost'] = {
        ...person('Ghost', 'G'),
        'joined_at': ts(3),
      };
      await groups().doc('ABC234').set(doc);

      final group = await repository.getGroup('ABC234');
      expect(group!.members.map((m) => m.userId), ['user-1']);
    });

    test('my groups: where I am a member, by name', () async {
      await groups().doc('G1').set(groupDoc(name: 'zeta', members: ['user-1']));
      await groups()
          .doc('G2')
          .set(groupDoc(name: 'Alpha', members: ['u2', 'user-1']));
      await groups().doc('G3').set(groupDoc(name: 'Other', members: ['u2']));

      final mine = await repository.watchMyGroups().first;
      expect(mine.map((g) => g.name), ['Alpha', 'zeta']);
    });

    test('my invites: newest invite first', () async {
      await groups().doc('G1').set(groupDoc(
            name: 'Older',
            members: ['u2'],
            invited: ['user-1'],
          ));
      await groups().doc('G2').set(groupDoc(
            name: 'Newer',
            members: ['u2'],
            invited: ['u4', 'user-1'],
          ));

      final invites = await repository.watchMyInvites().first;
      expect(invites.map((g) => g.name), ['Newer', 'Older']);
    });
  });

  group('inviteMembers', () {
    test('adds new people with who invited them', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['user-1', 'u2']));

      await repository.inviteMembers('ABC234', [
        const DirectoryUser(
            id: 'u3', firstName: 'Ann', lastName: 'Lee', thumbnail: 'gs://t'),
        const DirectoryUser(id: 'u2', firstName: 'Already', lastName: 'In'),
        const DirectoryUser(id: 'user-1', firstName: 'Me', lastName: 'Me'),
      ]);

      final data = (await read('ABC234'))!;
      expect(data['invited_ids'], ['u3']);
      final invite = data['invites']['u3'] as Map<String, dynamic>;
      expect(without(invite, ['invited_at']), {
        ...person('Ann', 'Lee', 'gs://t'),
        'invited_by': 'user-1',
        'invited_by_name': 'Jane Doe',
      });
      expect(invite['invited_at'], isA<Timestamp>());
      expect(data['member_ids'], ['user-1', 'u2']);
    });

    test('skips people already invited', () async {
      await groups().doc('ABC234').set(groupDoc(invited: ['u3']));

      await repository.inviteMembers('ABC234', [buildUser('u3')]);

      final data = (await read('ABC234'))!;
      expect(data['invited_ids'], ['u3']);
      expect(data['invites']['u3']['invited_by_name'], 'Jane Doe');
    });

    test('refuses invites that would overfill the group', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: ['user-1', for (var i = 0; i < 17; i++) 'm$i'],
            invited: ['i1'],
          ));

      await expectLater(
        repository.inviteMembers('ABC234', [buildUser('x1'), buildUser('x2')]),
        throwsA(same(ChallengeGroupException.groupFull)),
      );
      await repository.inviteMembers('ABC234', [buildUser('x1')]);
      expect((await read('ABC234'))!['invited_ids'], ['i1', 'x1']);
    });

    test('only members can invite', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2']));
      expect(
        repository.inviteMembers('ABC234', [buildUser('u3')]),
        throwsA(same(ChallengeGroupException.notMember)),
      );
    });

    test('a missing group fails', () {
      expect(
        repository.inviteMembers('NOPE22', [buildUser('u3')]),
        throwsA(same(ChallengeGroupException.notFound)),
      );
    });
  });

  group('acceptInvite', () {
    test('moves me from the invites to the members', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: ['u2'],
            invited: ['user-1', 'u3'],
          ));

      await repository.acceptInvite('ABC234');

      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2', 'user-1']);
      expect(without(data['members']['user-1'], ['joined_at']),
          person('Jane', 'Doe', testUser.thumbnail));
      expect(data['invited_ids'], ['u3']);
      expect((data['invites'] as Map).keys, ['u3']);
    });

    test('fails without an invite', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2']));
      expect(repository.acceptInvite('ABC234'),
          throwsA(same(ChallengeGroupException.notInvited)));
      expect(repository.acceptInvite('NOPE22'),
          throwsA(same(ChallengeGroupException.notInvited)));
    });

    test('fails when the group filled up', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: [
              for (var i = 0; i < kMaxChallengeGroupMembers; i++) 'm$i'
            ],
            invited: ['user-1'],
          ));
      expect(repository.acceptInvite('ABC234'),
          throwsA(same(ChallengeGroupException.groupFull)));
    });
  });

  group('declineInvite', () {
    test('removes my invite', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: ['u2'],
            invited: ['user-1', 'u3'],
          ));

      await repository.declineInvite('ABC234');

      final data = (await read('ABC234'))!;
      expect(data['invited_ids'], ['u3']);
      expect((data['invites'] as Map).keys, ['u3']);
      expect(data['member_ids'], ['u2']);
    });

    test('is a no-op when the invite or group is gone', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2']));
      await repository.declineInvite('ABC234');
      await repository.declineInvite('NOPE22');
      expect((await read('ABC234'))!['member_ids'], ['u2']);
    });
  });

  group('joinWithCode', () {
    test('adds me as a member', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2']));

      expect(await repository.joinWithCode('ABC234'), 'ABC234');

      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2', 'user-1']);
      expect(without(data['members']['user-1'], ['joined_at']),
          person('Jane', 'Doe', testUser.thumbnail));
    });

    test('also clears my pending invite', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: ['u2'],
            invited: ['user-1'],
          ));

      await repository.joinWithCode('ABC234');

      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2', 'user-1']);
      expect(data['invited_ids'], isEmpty);
      expect(data['invites'], isEmpty);
    });

    test('joining a group I am in changes nothing', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['user-1']));
      await repository.joinWithCode('ABC234');
      expect((await read('ABC234'))!['member_ids'], ['user-1']);
    });

    test('rejects malformed and unknown codes', () async {
      expect(repository.joinWithCode('abc'),
          throwsA(same(ChallengeGroupException.invalidCode)));
      expect(repository.joinWithCode('ZZZ222'),
          throwsA(same(ChallengeGroupException.codeNotFound)));
    });

    test('a full group (members and invites) cannot be joined', () async {
      await groups().doc('ABC234').set(groupDoc(
            members: [for (var i = 0; i < 15; i++) 'm$i'],
            invited: [for (var i = 0; i < 5; i++) 'i$i'],
          ));
      expect(repository.joinWithCode('ABC234'),
          throwsA(same(ChallengeGroupException.groupFull)));
    });

    test('an invitee can join a group whose seats include their invite',
        () async {
      await groups().doc('ABC234').set(groupDoc(
            members: [for (var i = 0; i < 19; i++) 'm$i'],
            invited: ['user-1'],
          ));
      await repository.joinWithCode('ABC234');
      expect((await read('ABC234'))!['member_ids'], contains('user-1'));
    });
  });

  group('leaveGroup', () {
    test('removes me', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2', 'user-1']));

      await repository.leaveGroup('ABC234');

      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2']);
      expect((data['members'] as Map).keys, ['u2']);
    });

    test('the last member out deletes the group', () async {
      await groups()
          .doc('ABC234')
          .set(groupDoc(members: ['user-1'], invited: ['u3']));

      await repository.leaveGroup('ABC234');

      expect((await groups().doc('ABC234').get()).exists, isFalse);
    });

    test('is a no-op when I am not a member', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2']));
      await repository.leaveGroup('ABC234');
      await repository.leaveGroup('NOPE22');
      expect((await read('ABC234'))!['member_ids'], ['u2']);
    });
  });

  group('nudgeMember', () {
    test('calls the nudge Cloud Function', () async {
      await repository.nudgeMember(groupId: 'ABC234', memberId: 'u2');

      expect(calls, hasLength(1));
      expect(calls.single.$1, 'nudgeChallengeGroupMember');
      expect(calls.single.$2, {'groupId': 'ABC234', 'memberId': 'u2'});
    });

    test('a rate-limited nudge is an expected error', () async {
      callError = FirebaseFunctionsException(
          code: 'resource-exhausted', message: 'slow down');

      await expectLater(
        repository.nudgeMember(groupId: 'ABC234', memberId: 'u2'),
        throwsA(isA<ChallengeGroupException>()
            .having(
                (e) => e.code, 'code', ChallengeGroupExceptionCode.nudgeTooSoon)
            .having((e) => e.details, 'details', isNull)),
      );
    });

    test('a refused nudge maps to fixed copy', () async {
      callError =
          FirebaseFunctionsException(code: 'permission-denied', message: 'no');

      await expectLater(
        repository.nudgeMember(groupId: 'ABC234', memberId: 'u2'),
        throwsA(isA<ChallengeGroupException>()
            .having(
                (e) => e.code, 'code', ChallengeGroupExceptionCode.nudgeFailed)
            .having((e) => e.message, 'message', 'Unable to send nudge')),
      );
    });

    test('other errors propagate unchanged', () async {
      callError = FirebaseFunctionsException(code: 'internal', message: 'x');
      expect(
        repository.nudgeMember(groupId: 'ABC234', memberId: 'u2'),
        throwsA(same(callError)),
      );
    });
  });

  group('public groups', () {
    Future<void> addGroup(
      String id, {
      required String name,
      String description = '',
      bool isPublic = true,
      int day = 1,
    }) =>
        groups().doc(id).set({
          ...groupDoc(name: name, members: ['u9']),
          'description': description,
          'is_public': isPublic,
          'search_tokens': searchTokens('$name $description'),
          'created_at': ts(day),
        });

    setUp(() async {
      await addGroup('G1',
          name: 'Night Owls', description: 'Late readers', day: 1);
      await addGroup('G2',
          name: 'Morning Glory', description: 'Before work', day: 3);
      await addGroup('G3', name: 'Secret Owls', isPublic: false, day: 4);
      await addGroup('G4',
          name: 'Psalms at noon', description: 'Lunch break readers', day: 2);
    });

    test('browsing lists public groups, newest first', () async {
      final found = await repository.findPublicGroups();
      expect(found.map((g) => g.id), ['G2', 'G4', 'G1']);
      expect(found.first.isPublic, isTrue);
      expect(found.first.description, 'Before work');
    });

    test('search matches the start of words in the name or description',
        () async {
      expect((await repository.findPublicGroups(query: 'OWL')).map((g) => g.id),
          ['G1']);
      expect(
          (await repository.findPublicGroups(query: 'lunch')).map((g) => g.id),
          ['G4']);
      expect(
          (await repository.findPublicGroups(query: 'read')).map((g) => g.name),
          ['Night Owls', 'Psalms at noon']);
    });

    test('every query word must match', () async {
      expect(
        (await repository.findPublicGroups(query: 'late read'))
            .map((g) => g.id),
        ['G1'],
      );
      expect(await repository.findPublicGroups(query: 'late lunch'), isEmpty);
    });

    test('private groups are never found', () async {
      expect(await repository.findPublicGroups(query: 'secret'), isEmpty);
    });

    test('a one-letter query browses', () async {
      final found = await repository.findPublicGroups(query: 'o');
      expect(found, hasLength(3));
    });
  });

  group('updateGroup', () {
    test('the creator changes the details', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['user-1', 'u2']));

      await repository.updateGroup('ABC234',
          name: ' Night Owls ', description: ' Late ', isPublic: true);

      final data = (await read('ABC234'))!;
      expect(data['name'], 'Night Owls');
      expect(data['description'], 'Late');
      expect(data['is_public'], isTrue);
      expect(data.containsKey('search_tokens'), isFalse,
          reason: 'written by the backend');
      expect(data['member_ids'], ['user-1', 'u2']);
    });

    test('other members cannot', () async {
      await groups().doc('ABC234').set(groupDoc(members: ['u2', 'user-1']));
      expect(
        repository.updateGroup('ABC234',
            name: 'X', description: '', isPublic: true),
        throwsA(same(ChallengeGroupException.notOwner)),
      );
    });

    test('a creator who left cannot', () async {
      await groups().doc('ABC234').set({
        ...groupDoc(members: ['u2']),
        'created_by': 'user-1',
      });
      expect(
        repository.updateGroup('ABC234',
            name: 'X', description: '', isPublic: true),
        throwsA(same(ChallengeGroupException.notOwner)),
      );
    });
  });

  test('deleteGroup removes the group', () async {
    await groups().doc('ABC234').set(groupDoc(members: ['u2']));
    await repository.deleteGroup('ABC234');
    expect((await groups().doc('ABC234').get()).exists, isFalse);
  });

  test('older groups without the new fields read as private', () async {
    await groups().doc('ABC234').set(groupDoc());
    final group = (await repository.getGroup('ABC234'))!;
    expect(group.isPublic, isFalse);
    expect(group.description, '');
  });

  group('owners', () {
    Future<void> setGroup(List<String> members, {List<String>? owners}) =>
        groups().doc('ABC234').set({
          ...groupDoc(members: members),
          if (owners != null) 'owner_ids': owners,
        });

    test('older groups without owner_ids are owned by their creator', () async {
      await setGroup(['user-1', 'u2']);
      expect((await repository.getGroup('ABC234'))!.ownerIds, ['user-1']);
    });

    test('the last owner must name a member as the next owner', () async {
      await setGroup(['user-1', 'u2'], owners: ['user-1']);
      await expectLater(repository.leaveGroup('ABC234'),
          throwsA(same(ChallengeGroupException.successorRequired)));
      await expectLater(repository.leaveGroup('ABC234', newOwnerId: 'stranger'),
          throwsA(same(ChallengeGroupException.successorRequired)));
      expect((await read('ABC234'))!['member_ids'], ['user-1', 'u2']);

      await repository.leaveGroup('ABC234', newOwnerId: 'u2');

      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2']);
      expect(data['owner_ids'], ['u2']);
    });

    test('a legacy group hands over from its creator', () async {
      await setGroup(['user-1', 'u2']);
      await repository.leaveGroup('ABC234', newOwnerId: 'u2');
      expect((await read('ABC234'))!['owner_ids'], ['u2']);
    });

    test('an owner with co-owners just leaves', () async {
      await setGroup(['user-1', 'u2', 'u3'], owners: ['user-1', 'u3']);
      await repository.leaveGroup('ABC234', newOwnerId: 'u2');
      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2', 'u3']);
      expect(data['owner_ids'], ['u3']);
    });

    test('a member leaving leaves the owners alone', () async {
      await setGroup(['u2', 'user-1'], owners: ['u2']);
      await repository.leaveGroup('ABC234');
      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['u2']);
      expect(data['owner_ids'], ['u2']);
    });

    test('owners remove members, not other owners', () async {
      await setGroup(['user-1', 'u2', 'u3'], owners: ['user-1', 'u3']);

      await repository.removeMember('ABC234', 'u2');
      final data = (await read('ABC234'))!;
      expect(data['member_ids'], ['user-1', 'u3']);
      expect((data['members'] as Map).keys, ['user-1', 'u3']);

      expect(repository.removeMember('ABC234', 'u3'),
          throwsA(same(ChallengeGroupException.cannotRemoveOwner)));
    });

    test('non-owners cannot remove or promote', () async {
      await setGroup(['u2', 'user-1', 'u3'], owners: ['u2']);
      await expectLater(repository.removeMember('ABC234', 'u3'),
          throwsA(same(ChallengeGroupException.notOwner)));
      await expectLater(repository.makeOwner('ABC234', 'u3'),
          throwsA(same(ChallengeGroupException.notOwner)));
    });

    test('owners make members owners', () async {
      await setGroup(['user-1', 'u2']);
      await repository.makeOwner('ABC234', 'u2');
      expect((await read('ABC234'))!['owner_ids'], ['user-1', 'u2']);

      expect(repository.makeOwner('ABC234', 'stranger'),
          throwsA(same(ChallengeGroupException.notMember)));
    });

    test('a co-owner can edit the group', () async {
      await setGroup(['u2', 'user-1'], owners: ['u2', 'user-1']);
      await repository.updateGroup('ABC234',
          name: 'Renamed', description: '', isPublic: false);
      expect((await read('ABC234'))!['name'], 'Renamed');
    });
  });
}

DirectoryUser buildUser(String id) =>
    DirectoryUser(id: id, firstName: 'F$id', lastName: 'L');
