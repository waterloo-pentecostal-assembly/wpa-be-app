import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/domain/testimonies/exceptions.dart';
import 'package:wpa_app/domain/user_profile/entities.dart';
import 'package:wpa_app/infrastructure/testimonies/testimonies_repository.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '_support/fakes.dart';

/// A `testimonies` document in the shape written by the app.
Map<String, dynamic> testimonyDoc({
  required int day,
  String userId = 'other-user',
  bool isApproved = true,
  bool isArchived = false,
  List<String>? praisedBy,
  List<String>? reportedBy,
}) =>
    {
      'date': ts(day),
      'is_anonymous': false,
      'is_approved': isApproved,
      'is_archived': isArchived,
      'request': 'God is good',
      'user_id': userId,
      'user_snippet': {
        'first_name': 'John',
        'last_name': 'Smith',
        'thumbnail': null,
      },
      if (praisedBy != null) 'praised_by': praisedBy,
      if (reportedBy != null) 'reported_by': reportedBy,
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late TestimoniesRepository repository;

  CollectionReference<Map<String, dynamic>> collection() =>
      firestore.collection('testimonies');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = TestimoniesRepository(
      firestore,
      createStorageMock(),
      const FirebaseFirestoreService(),
      sessionWith(),
    );
  });

  group('reading', () {
    test('maps a stored document to a Testimony', () async {
      await collection().doc('t1').set(testimonyDoc(
            day: 2,
            praisedBy: [testUser.id],
            reportedBy: [testUser.id],
          ));

      final page = await repository.getTestimonies(limit: 10);

      expect(page.items, [
        Testimony(
          id: 't1',
          userId: 'other-user',
          request: 'God is good',
          praisedBy: const ['user-1'],
          reportedBy: const ['user-1'],
          hasPraised: true,
          hasReported: true,
          isMine: false,
          isApproved: true,
          date: day(2),
          isAnonymous: false,
          userSnippet: const UserSnippet(
            firstName: 'John',
            lastName: 'Smith',
            thumbnailUrl: null,
            thumbnail: null,
          ),
          isArchived: false,
        ),
      ]);
      expect(page.isEnd, isTrue);
    });

    test('my testimonies are split by is_archived', () async {
      await collection()
          .doc('open')
          .set(testimonyDoc(day: 1, userId: testUser.id));
      await collection()
          .doc('archived')
          .set(testimonyDoc(day: 2, userId: testUser.id, isArchived: true));
      await collection().doc('theirs').set(testimonyDoc(day: 3));

      expect((await repository.getMyTestimonies()).map((t) => t.id), ['open']);
      final archived = await repository.getMyArchivedTestimonies();
      expect(archived.map((t) => t.id), ['archived']);
      expect(archived.single.isArchived, isTrue);
    });
  });

  group('paging', () {
    test('pages approved, non-archived posts newest first', () async {
      for (var d = 1; d <= 3; d++) {
        await collection().doc('t$d').set(testimonyDoc(day: d));
      }
      await collection()
          .doc('hidden')
          .set(testimonyDoc(day: 9, isApproved: false));
      await collection()
          .doc('archived')
          .set(testimonyDoc(day: 8, isArchived: true));

      final first = await repository.getTestimonies(limit: 2);
      expect(first.items.map((t) => t.id), ['t3', 't2']);
      expect(first.isEnd, isFalse);

      final second =
          await repository.getTestimonies(limit: 2, after: first.nextCursor);
      expect(second.items.map((t) => t.id), ['t1']);
      expect(second.isEnd, isTrue);
    });
  });

  group('writing', () {
    test('createTestimony writes the exact pre-refactor document', () async {
      final created = await repository.createTestimony(
          request: 'He answered', isAnonymous: false);

      final stored = await collection().doc(created.id).get();
      expect(without(stored.data(), ['date']), {
        'is_anonymous': false,
        'is_approved': false,
        'is_archived': false,
        'request': 'He answered',
        'user_id': 'user-1',
        'user_snippet': {
          'first_name': 'Jane',
          'last_name': 'Doe',
          'thumbnail': 'gs://bucket/users/user-1/thumb.jpg',
        },
      });
      expect(stored.data()!['date'], isA<Timestamp>());
      expect(created.isMine, isTrue);
    });

    test('closeTestimony sets only is_archived', () async {
      final original = testimonyDoc(day: 1, userId: testUser.id);
      await collection().doc('t1').set(original);

      final closed = await repository.closeTestimony(id: 't1');

      expect(closed.isArchived, isTrue);
      expect((await collection().doc('t1').get()).data(),
          {...original, 'is_archived': true});
    });

    test('praiseTestimony appends the user to praised_by', () async {
      final original = testimonyDoc(day: 1, praisedBy: ['a']);
      await collection().doc('t1').set(original);

      await repository.praiseTestimony(id: 't1');

      expect((await collection().doc('t1').get()).data(), {
        ...original,
        'praised_by': ['a', 'user-1'],
      });
    });

    test('praiseTestimony on a missing post throws notFound', () async {
      await expectLater(
        repository.praiseTestimony(id: 'missing'),
        throwsA(isA<TestimoniesException>().having(
            (e) => e.code, 'code', TestimoniesExceptionCode.testimonyNotFound)),
      );
    });

    test('reportTestimony appends reporter and resets is_approved', () async {
      final original = testimonyDoc(day: 1);
      await collection().doc('t1').set(original);

      await repository.reportTestimony(id: 't1');

      expect((await collection().doc('t1').get()).data(), {
        ...original,
        'reported_by': ['user-1'],
        'is_approved': false,
      });

      await expectLater(
        repository.reportTestimony(id: 't1'),
        throwsA(isA<TestimoniesException>().having(
            (e) => e.code, 'code', TestimoniesExceptionCode.alreadyReported)),
      );
    });

    test('deleteTestimony removes the document', () async {
      await collection().doc('t1').set(testimonyDoc(day: 1));
      await repository.deleteTestimony(id: 't1');
      expect((await collection().doc('t1').get()).exists, isFalse);
    });
  });
}
