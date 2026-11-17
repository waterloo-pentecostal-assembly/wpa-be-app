import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/infrastructure/forum/forum_repository.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '_support/fakes.dart';

const forumId = 'forum-1';

Map<String, dynamic> threadDoc({
  required int day,
  String title = 'Thread',
  int commentCount = 0,
  bool isHidden = false,
}) =>
    {
      'title': title,
      'author_id': 'author-1',
      'author_name': 'Author One',
      'author_image_url': 'https://img/a.jpg',
      'created_at': ts(day),
      'updated_at': ts(day, 13),
      'comment_count': commentCount,
      'is_frozen': false,
      'is_hidden': isHidden,
    };

Map<String, dynamic> commentDoc({
  required int day,
  String body = 'Hello',
  List<String> likedBy = const [],
  int reportCount = 0,
  String? parentId,
}) =>
    {
      'thread_id': 'th1',
      'body': body,
      'author_id': 'author-2',
      'author_name': 'Author Two',
      'author_image_url': null,
      'created_at': ts(day),
      'updated_at': ts(day),
      'parent_id': parentId,
      'is_hidden': false,
      'is_deleted': false,
      'liked_by': likedBy,
      'report_count': reportCount,
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late ForumRepository repository;

  DocumentReference<Map<String, dynamic>> forum() =>
      firestore.collection('forums').doc(forumId);
  CollectionReference<Map<String, dynamic>> threads() =>
      forum().collection('threads');
  CollectionReference<Map<String, dynamic>> comments(String threadId) =>
      threads().doc(threadId).collection('comments');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ForumRepository(firestore, const FirebaseFirestoreService());
  });

  group('reading', () {
    test('watchForum maps the forum document (empty when missing)', () async {
      expect(await repository.watchForum(forumId).first, const Forum.empty());

      await forum()
          .set({'title': 'General', 'is_frozen': true, 'is_read_only': false});
      expect(
        await repository.watchForum(forumId).first,
        const Forum(
            id: forumId, title: 'General', isFrozen: true, isReadOnly: false),
      );
    });

    test('watchThreads returns threads newest first, including hidden ones',
        () async {
      await threads().doc('old').set(threadDoc(day: 1, title: 'Old'));
      await threads().doc('new').set(
          threadDoc(day: 2, title: 'New', commentCount: 3, isHidden: true));

      final result = await repository.watchThreads(forumId).first;

      expect(result, [
        ForumThread(
          id: 'new',
          forumId: forumId,
          title: 'New',
          authorId: 'author-1',
          authorName: 'Author One',
          authorImageUrl: 'https://img/a.jpg',
          createdAt: day(2),
          updatedAt: day(2, 13),
          commentCount: 3,
          isFrozen: false,
          isHidden: true,
        ),
        ForumThread(
          id: 'old',
          forumId: forumId,
          title: 'Old',
          authorId: 'author-1',
          authorName: 'Author One',
          authorImageUrl: 'https://img/a.jpg',
          createdAt: day(1),
          updatedAt: day(1, 13),
          commentCount: 0,
          isFrozen: false,
          isHidden: false,
        ),
      ]);
    });

    test('watchThread emits null for a missing thread', () async {
      expect(await repository.watchThread('nope', forumId).first, isNull);
    });

    test('watchComments returns comments oldest first', () async {
      await comments('th1').doc('c2').set(commentDoc(
          day: 2,
          body: 'Second',
          likedBy: ['u1', 'u2'],
          reportCount: 1,
          parentId: 'c1'));
      await comments('th1').doc('c1').set(commentDoc(day: 1, body: 'First'));

      final result = await repository.watchComments('th1', forumId).first;

      expect(result.map((c) => c.id), ['c1', 'c2']);
      expect(
        result.last,
        Comment(
          id: 'c2',
          threadId: 'th1',
          body: 'Second',
          authorId: 'author-2',
          authorName: 'Author Two',
          createdAt: day(2),
          updatedAt: day(2),
          parentId: 'c1',
          isHidden: false,
          isDeleted: false,
          likedBy: const ['u1', 'u2'],
          reportCount: 1,
        ),
      );
      expect(result.last.isReply, isTrue);
      expect(result.last.likeCount, 2);
    });
  });

  group('writing', () {
    test('createThread writes the exact pre-refactor thread document',
        () async {
      final id = await repository.createThread(const NewThread(
        forumId: forumId,
        title: 'Prayer week',
        authorId: 'user-1',
        authorName: 'Jane Doe',
        authorImageUrl: 'https://img/jane.jpg',
      ));

      final data = (await threads().doc(id).get()).data();
      expect(without(data, ['created_at', 'updated_at']), {
        'title': 'Prayer week',
        'author_id': 'user-1',
        'author_name': 'Jane Doe',
        'author_image_url': 'https://img/jane.jpg',
        'comment_count': 0,
        'is_frozen': false,
        'is_hidden': false,
      });
      expect(data!['created_at'], isA<Timestamp>());
      expect(data['updated_at'], isA<Timestamp>());
    });

    test('addComment writes the exact comment and increments comment_count',
        () async {
      await threads().doc('th1').set(threadDoc(day: 1, commentCount: 2));

      await repository.addComment(
        const NewComment(
          threadId: 'th1',
          body: 'Amen',
          authorId: 'user-1',
          authorName: 'Jane Doe',
          parentId: 'c0',
        ),
        forumId,
      );

      final stored = await comments('th1').get();
      expect(stored.docs, hasLength(1));
      final data = stored.docs.single.data();
      expect(without(data, ['created_at', 'updated_at']), {
        'thread_id': 'th1',
        'body': 'Amen',
        'author_id': 'user-1',
        'author_name': 'Jane Doe',
        'author_image_url': null,
        'parent_id': 'c0',
        'is_hidden': false,
        'is_deleted': false,
        'liked_by': <dynamic>[],
        'report_count': 0,
      });
      expect(data['created_at'], isA<Timestamp>());
      expect(data['updated_at'], isA<Timestamp>());
      expect((await threads().doc('th1').get()).data(),
          threadDoc(day: 1, commentCount: 3));
    });

    test('addComment on a missing thread throws and writes nothing', () async {
      await expectLater(
        repository.addComment(
          const NewComment(
              threadId: 'missing', body: 'x', authorId: 'u', authorName: 'U'),
          forumId,
        ),
        throwsA(isA<ApplicationException>()),
      );
      expect((await comments('missing').get()).docs, isEmpty);
    });

    test('thread moderation updates the expected fields only', () async {
      final original = threadDoc(day: 1);
      await threads().doc('th1').set(original);

      await repository.freezeThread('th1', forumId, true);
      await repository.hideThread('th1', forumId, true);
      expect((await threads().doc('th1').get()).data(),
          {...original, 'is_frozen': true, 'is_hidden': true});

      await repository.updateThread('th1', forumId, 'Renamed');
      final data = (await threads().doc('th1').get()).data()!;
      expect(without(data, ['updated_at']), {
        ...without(original, ['updated_at']),
        'is_frozen': true,
        'is_hidden': true,
        'title': 'Renamed',
      });
      expect(data['updated_at'], isA<Timestamp>());
      expect(data['updated_at'], isNot(original['updated_at']));
    });

    test('comment like / unlike / report / delete / edit', () async {
      final original = commentDoc(day: 1, likedBy: ['other']);
      await comments('th1').doc('c1').set(original);

      await repository.likeComment('c1', 'th1', forumId, 'user-1');
      await repository.likeComment('c1', 'th1', forumId, 'user-1');
      expect((await comments('th1').doc('c1').get()).data()!['liked_by'],
          ['other', 'user-1']);

      await repository.unlikeComment('c1', 'th1', forumId, 'other');
      await repository.reportComment('c1', 'th1', forumId, 'spam');
      await repository.reportComment('c1', 'th1', forumId, 'spam');
      await repository.deleteComment('c1', 'th1', forumId);
      expect((await comments('th1').doc('c1').get()).data(), {
        ...original,
        'liked_by': ['user-1'],
        'report_count': 2,
        'is_deleted': true,
      });

      await repository.updateComment('c1', 'th1', forumId, 'Edited');
      final data = (await comments('th1').doc('c1').get()).data()!;
      expect(data['body'], 'Edited');
      expect(data['updated_at'], isA<Timestamp>());
      expect(data['created_at'], original['created_at']);
    });
  });
}
