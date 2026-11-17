import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/domain/prayer_requests/exceptions.dart';
import 'package:wpa_app/domain/user_profile/entities.dart';
import 'package:wpa_app/infrastructure/prayer_requests/prayer_requests_repository.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '_support/fakes.dart';

/// A `prayer_requests` document in the shape written by the app.
Map<String, dynamic> prayerDoc({
  required int day,
  String userId = 'other-user',
  String request = 'Please pray',
  bool isApproved = true,
  bool isAnswered = false,
  bool isAnonymous = false,
  List<String>? prayedBy,
  List<String>? reportedBy,
  String? thumbnail,
}) =>
    {
      'date': ts(day),
      'is_anonymous': isAnonymous,
      'is_approved': isApproved,
      'is_answered': isAnswered,
      'request': request,
      'user_id': userId,
      'user_snippet': {
        'first_name': 'John',
        'last_name': 'Smith',
        'thumbnail': thumbnail,
      },
      if (prayedBy != null) 'prayed_by': prayedBy,
      if (reportedBy != null) 'reported_by': reportedBy,
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late PrayerRequestsRepository repository;

  CollectionReference<Map<String, dynamic>> collection() =>
      firestore.collection('prayer_requests');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = PrayerRequestsRepository(
      firestore,
      createStorageMock(),
      const FirebaseFirestoreService(),
      sessionWith(),
    );
  });

  group('reading', () {
    test('maps a stored document to a PrayerRequest', () async {
      await collection().doc('p1').set(prayerDoc(
            day: 5,
            prayedBy: ['a', testUser.id],
            reportedBy: ['b'],
            thumbnail: 'gs://bucket/thumb.jpg',
          ));

      final page = await repository.getPrayerRequests(limit: 10);

      expect(page.items, [
        PrayerRequest(
          id: 'p1',
          userId: 'other-user',
          request: 'Please pray',
          prayedBy: const ['a', 'user-1'],
          reportedBy: const ['b'],
          hasPrayed: true,
          hasReported: false,
          isMine: false,
          isApproved: true,
          date: day(5),
          isAnonymous: false,
          userSnippet: UserSnippet(
            firstName: 'John',
            lastName: 'Smith',
            thumbnailUrl: downloadUrlFor('gs://bucket/thumb.jpg'),
            thumbnail: 'gs://bucket/thumb.jpg',
          ),
          isAnswered: false,
        ),
      ]);
    });

    test('missing optional fields fall back to defaults', () async {
      await collection().doc('p1').set({
        'date': ts(1),
        'is_anonymous': true,
        'is_answered': false,
        'request': 'r',
        'user_id': testUser.id,
        'user_snippet': {'first_name': 'J', 'last_name': 'D'},
      });

      final post = (await repository.getMyPrayerRequests()).single;

      expect(post.prayedBy, isEmpty);
      expect(post.reportedBy, isEmpty);
      expect(post.isApproved, isFalse);
      expect(post.isMine, isTrue);
      expect(post.isAnonymous, isTrue);
      expect(post.userSnippet.thumbnail, isNull);
      expect(post.userSnippet.thumbnailUrl, isNull);
    });

    test(
        'getMyPrayerRequests / getMyAnsweredPrayerRequests split by '
        'is_answered and only return my posts, newest first', () async {
      await collection()
          .doc('mine-old')
          .set(prayerDoc(day: 1, userId: testUser.id, isApproved: false));
      await collection()
          .doc('mine-new')
          .set(prayerDoc(day: 3, userId: testUser.id));
      await collection()
          .doc('mine-answered')
          .set(prayerDoc(day: 2, userId: testUser.id, isAnswered: true));
      await collection().doc('theirs').set(prayerDoc(day: 4));

      final open = await repository.getMyPrayerRequests();
      final answered = await repository.getMyAnsweredPrayerRequests();

      expect(open.map((p) => p.id), ['mine-new', 'mine-old']);
      expect(open.every((p) => p.isMine), isTrue);
      expect(answered.map((p) => p.id), ['mine-answered']);
      expect(answered.single.isAnswered, isTrue);
    });

    test('canAddPrayerRequest counts approved posts against the limit',
        () async {
      for (var i = 1; i <= 9; i++) {
        await collection().add(prayerDoc(day: i, userId: testUser.id));
      }
      expect(await repository.canAddPrayerRequest(), isTrue);
      await collection().add(prayerDoc(day: 10, userId: testUser.id));
      expect(await repository.canAddPrayerRequest(), isFalse);
    });

    test('a malformed document throws the missing-key ApplicationException',
        () async {
      await collection().doc('bad').set({
        'date': ts(1),
        'is_approved': true,
        'is_answered': false,
        'user_id': 'x',
        'is_anonymous': false,
        'user_snippet': {'first_name': 'J', 'last_name': 'D'},
      });

      await expectLater(
        repository.getPrayerRequests(limit: 5),
        throwsA(isA<ApplicationException>().having(
            (e) => e.code, 'code', ApplicationExceptionCode.missingKey)),
      );
    });
  });

  group('paging', () {
    setUp(() async {
      // Five visible posts (days 1..5) plus hidden ones that must be skipped.
      for (var d = 1; d <= 5; d++) {
        await collection().doc('p$d').set(prayerDoc(day: d));
      }
      await collection()
          .doc('unapproved')
          .set(prayerDoc(day: 6, isApproved: false));
      await collection()
          .doc('answered')
          .set(prayerDoc(day: 7, isAnswered: true));
    });

    test('pages newest first and continues after the cursor', () async {
      final first = await repository.getPrayerRequests(limit: 2);
      expect(first.items.map((p) => p.id), ['p5', 'p4']);
      expect(first.isEnd, isFalse);

      final second =
          await repository.getPrayerRequests(limit: 2, after: first.nextCursor);
      expect(second.items.map((p) => p.id), ['p3', 'p2']);
      expect(second.isEnd, isFalse);

      final third = await repository.getPrayerRequests(
          limit: 2, after: second.nextCursor);
      expect(third.items.map((p) => p.id), ['p1']);
      expect(third.isEnd, isTrue);
      expect(third.nextCursor, isNull);
    });

    test('an exactly full last page is followed by an empty end page',
        () async {
      final first = await repository.getPrayerRequests(limit: 5);
      expect(first.items, hasLength(5));
      expect(first.isEnd, isFalse);

      final next =
          await repository.getPrayerRequests(limit: 5, after: first.nextCursor);
      expect(next.items, isEmpty);
      expect(next.isEnd, isTrue);
    });
  });

  group('writing', () {
    test('createPrayerRequest writes the exact pre-refactor document',
        () async {
      final created = await repository.createPrayerRequest(
          request: 'Pray for my exams', isAnonymous: true);

      final stored = await collection().doc(created.id).get();
      expect(without(stored.data(), ['date']), {
        'is_anonymous': true,
        'is_approved': false,
        'is_answered': false,
        'request': 'Pray for my exams',
        'user_id': 'user-1',
        'user_snippet': {
          'first_name': 'Jane',
          'last_name': 'Doe',
          'thumbnail': 'gs://bucket/users/user-1/thumb.jpg',
        },
      });
      expect(stored.data()!['date'], isA<Timestamp>());

      expect(created.isMine, isTrue);
      expect(created.isApproved, isFalse);
      expect(created.request, 'Pray for my exams');
      expect(created.prayedBy, isEmpty);
    });

    test('createPrayerRequest requires a signed-in user', () async {
      repository = PrayerRequestsRepository(
        firestore,
        createStorageMock(),
        const FirebaseFirestoreService(),
        sessionWith(null),
      );
      await expectLater(
        repository.createPrayerRequest(request: 'x', isAnonymous: false),
        throwsA(isA<BaseApplicationException>()),
      );
      expect((await collection().get()).docs, isEmpty);
    });

    test('closePrayerRequest sets only is_answered', () async {
      final original = prayerDoc(day: 1, userId: testUser.id);
      await collection().doc('p1').set(original);

      final closed = await repository.closePrayerRequest(id: 'p1');

      expect(closed.isAnswered, isTrue);
      expect((await collection().doc('p1').get()).data(),
          {...original, 'is_answered': true});
    });

    test('prayForPrayerRequest appends the user to prayed_by', () async {
      final original = prayerDoc(day: 1, prayedBy: ['a']);
      await collection().doc('p1').set(original);

      await repository.prayForPrayerRequest(id: 'p1');

      expect((await collection().doc('p1').get()).data(), {
        ...original,
        'prayed_by': ['a', 'user-1'],
      });
    });

    test('prayForPrayerRequest creates prayed_by when missing', () async {
      final original = prayerDoc(day: 1);
      await collection().doc('p1').set(original);

      await repository.prayForPrayerRequest(id: 'p1');

      expect((await collection().doc('p1').get()).data(), {
        ...original,
        'prayed_by': ['user-1'],
      });
    });

    test('prayForPrayerRequest on a missing post throws notFound', () async {
      await expectLater(
        repository.prayForPrayerRequest(id: 'missing'),
        throwsA(isA<PrayerRequestsException>().having((e) => e.code, 'code',
            PrayerRequestsExceptionCode.prayerRequestNotFound)),
      );
    });

    test('reportPrayerRequest appends reporter and resets is_approved',
        () async {
      final original = prayerDoc(day: 1, reportedBy: ['x']);
      await collection().doc('p1').set(original);

      await repository.reportPrayerRequest(id: 'p1');

      expect((await collection().doc('p1').get()).data(), {
        ...original,
        'reported_by': ['x', 'user-1'],
        'is_approved': false,
      });
    });

    test('reporting twice throws alreadyReported and writes nothing', () async {
      final original = prayerDoc(day: 1, reportedBy: [testUser.id]);
      await collection().doc('p1').set(original);

      await expectLater(
        repository.reportPrayerRequest(id: 'p1'),
        throwsA(isA<PrayerRequestsException>().having((e) => e.code, 'code',
            PrayerRequestsExceptionCode.alreadyReported)),
      );
      expect((await collection().doc('p1').get()).data(), original);
    });

    test('deletePrayerRequest removes the document', () async {
      await collection().doc('p1').set(prayerDoc(day: 1));
      await repository.deletePrayerRequest(id: 'p1');
      expect((await collection().doc('p1').get()).exists, isFalse);
    });
  });
}
