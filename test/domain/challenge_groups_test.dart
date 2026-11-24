import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/challenge_groups/policies.dart';
import 'package:wpa_app/domain/challenge_groups/rules.dart';

import '../helpers/fakes.dart';

void main() {
  group('validateGroupName', () {
    test('requires a non-blank name', () {
      expect(validateGroupName(''), 'Enter a group name');
      expect(validateGroupName('   '), 'Enter a group name');
    });

    test('limits the trimmed length', () {
      expect(validateGroupName('a' * kMaxChallengeGroupNameLength), '');
      expect(
        validateGroupName('  ${'a' * kMaxChallengeGroupNameLength}  '),
        '',
      );
      expect(
        validateGroupName('a' * (kMaxChallengeGroupNameLength + 1)),
        'Use at most $kMaxChallengeGroupNameLength characters',
      );
    });
  });

  group('join codes', () {
    test('normalize to upper case without spaces or dashes', () {
      expect(normalizeGroupCode(' ab-c 234 '), 'ABC234');
    });

    test('are 6 characters of the unambiguous alphabet', () {
      expect(isValidGroupCode('ABC234'), isTrue);
      expect(isValidGroupCode('ABC23'), isFalse);
      expect(isValidGroupCode('ABC2345'), isFalse);
      // 0, O, 1 and I are excluded.
      expect(isValidGroupCode('ABC230'), isFalse);
      expect(isValidGroupCode('ABCO23'), isFalse);
      expect(isValidGroupCode('ABC231'), isFalse);
      expect(isValidGroupCode('ABCI23'), isFalse);
      expect(isValidGroupCode('abc234'), isFalse);
    });

    test('generated codes are valid', () {
      final random = Random(7);
      for (var i = 0; i < 200; i++) {
        expect(isValidGroupCode(generateGroupCode(random)), isTrue);
      }
    });
  });

  group('SeriesTarget', () {
    final now = DateTime(2024, 3, 10, 9);
    BibleSeries series(int days, {required int startOffset}) =>
        buildSeries(days: [
          for (var i = 0; i < days; i++)
            DateTime(2024, 3, 10 + startOffset + i),
        ]);

    test('counts the days started by now, including today', () {
      final target = SeriesTarget.of(series(10, startOffset: -3), now);
      expect(target.totalDays, 10);
      expect(target.startedDays, 4);
      expect(target.expectedProgress, 40);
    });

    test('an empty series expects nothing', () {
      expect(
          SeriesTarget.of(series(0, startOffset: 0), now).expectedProgress, 0);
    });
  });

  group('completedDaysFor', () {
    test('inverts the server ceil(100 * days / total) for short series', () {
      for (var total = 1; total < 100; total++) {
        for (var days = 0; days <= total; days++) {
          final progress = (100 * days / total).ceil();
          expect(completedDaysFor(progress, total), days,
              reason: '$days of $total days stored as $progress%');
        }
      }
    });

    test('handles out-of-range input', () {
      expect(completedDaysFor(50, 0), 0);
      expect(completedDaysFor(150, 10), 10);
      expect(completedDaysFor(-5, 10), 0);
    });
  });

  group('pace', () {
    // Day 5 of 10 has started.
    const target =
        SeriesTarget(seriesTitle: 'John', totalDays: 10, startedDays: 5);

    test('caught up is on track', () {
      expect(daysBehind(50, target), 0);
      expect(paceFor(50, target), MemberPace.onTrack);
    });

    test("only today's reading left is on track", () {
      expect(daysBehind(40, target), 0);
      expect(paceFor(40, target), MemberPace.onTrack);
    });

    test('missing an earlier day is behind', () {
      expect(daysBehind(30, target), 1);
      expect(paceFor(30, target), MemberPace.behind);
      expect(daysBehind(0, target), 4);
    });

    test('ahead of the target is on track', () {
      expect(daysBehind(100, target), 0);
      expect(paceFor(100, target), MemberPace.onTrack);
    });
  });

  group('group description', () {
    test('is optional and limited after trimming', () {
      expect(validateGroupDescription(''), '');
      expect(validateGroupDescription('  ${'a' * 200}  '), '');
      expect(validateGroupDescription('a' * 201), 'Use at most 200 characters');
    });
  });

  group('ChallengeGroup permissions', () {
    test('canJoin counts invites, except your own', () {
      expect(buildGroup(memberIds: ['u2']).canJoin('me'), isTrue);
      expect(buildGroup(memberIds: ['me']).canJoin('me'), isFalse);
      final fullWithMyInvite = buildGroup(
        memberIds: [for (var i = 0; i < 19; i++) 'm$i'],
        invitedIds: ['me'],
      );
      expect(fullWithMyInvite.canJoin('me'), isTrue);
      expect(fullWithMyInvite.canJoin('other'), isFalse);
    });

    test('owners who are still members can edit', () {
      expect(buildGroup(memberIds: ['me', 'u2']).canEdit('me'), isTrue);
      expect(buildGroup(memberIds: ['me', 'u2']).canEdit('u2'), isFalse);
      expect(
          buildGroup(memberIds: ['me', 'u2'], ownerIds: ['me', 'u2'])
              .canEdit('u2'),
          isTrue);
      expect(buildGroup(createdBy: 'me', memberIds: ['u2']).canEdit('me'),
          isFalse);
    });

    test('any owner who is still a member can delete', () {
      final group =
          buildGroup(memberIds: ['me', 'u2', 'u3'], ownerIds: ['me', 'u3']);
      expect(group.canDelete('me'), isTrue);
      expect(group.canDelete('u3'), isTrue);
      expect(group.canDelete('u2'), isFalse);
      expect(group.canDelete('stranger'), isFalse);
      expect(buildGroup(memberIds: ['u2'], ownerIds: ['me']).canDelete('me'),
          isFalse);
    });

    test('owners remove and promote members, not other owners', () {
      final group =
          buildGroup(memberIds: ['me', 'u2', 'u3'], ownerIds: ['me', 'u3']);
      expect(group.canRemove('me', 'u2'), isTrue);
      expect(group.canRemove('me', 'u3'), isFalse);
      expect(group.canRemove('me', 'me'), isFalse);
      expect(group.canRemove('u2', 'me'), isFalse);
      expect(group.canRemove('me', 'stranger'), isFalse);
      expect(group.canMakeOwner('me', 'u2'), isTrue);
      expect(group.canMakeOwner('me', 'u3'), isFalse);
      expect(group.canMakeOwner('u2', 'me'), isFalse);
    });

    test('only a sole owner with others in the group needs a successor', () {
      expect(buildGroup(memberIds: ['me', 'u2']).needsSuccessor('me'), isTrue);
      expect(buildGroup(memberIds: ['me']).needsSuccessor('me'), isFalse);
      expect(
          buildGroup(memberIds: ['me', 'u2'], ownerIds: ['me', 'u2'])
              .needsSuccessor('me'),
          isFalse);
      expect(buildGroup(memberIds: ['me', 'u2']).needsSuccessor('u2'), isFalse);
      // An owner id of someone who already left doesn't count.
      expect(
          buildGroup(memberIds: ['me', 'u2'], ownerIds: ['me', 'gone'])
              .needsSuccessor('me'),
          isTrue);
    });
  });
}
