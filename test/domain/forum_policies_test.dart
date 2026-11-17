import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/domain/forum/policies.dart';

LocalUser user(String id, {bool admin = false}) => LocalUser(
      id: id,
      firstName: 'F',
      lastName: 'L',
      email: '$id@example.com',
      reports: 0,
      thumbnailUrl: null,
      thumbnail: null,
      isAdmin: admin,
      isVerified: true,
    );

Comment comment(
  String id, {
  String author = 'author',
  String? parent,
  bool deleted = false,
  DateTime? createdAt,
}) =>
    Comment(
      id: id,
      threadId: 't',
      body: 'body',
      authorId: author,
      authorName: 'Author',
      createdAt: createdAt ?? DateTime(2026),
      updatedAt: createdAt ?? DateTime(2026),
      parentId: parent,
      isHidden: false,
      isDeleted: deleted,
      likedBy: const [],
      reportCount: 0,
    );

void main() {
  final created = DateTime(2026, 1, 1, 12);
  final thread = ForumThread(
    id: 't',
    forumId: 'f',
    title: 'Thread',
    authorId: 'author',
    authorName: 'Author',
    createdAt: created,
    updatedAt: created,
    commentCount: 0,
    isFrozen: false,
    isHidden: false,
  );

  group('canEditThread', () {
    test('author within the 15 minute window', () {
      expect(
        canEditThread(
          thread: thread,
          user: user('author'),
          now: created.add(const Duration(minutes: 14)),
        ),
        isTrue,
      );
    });

    test('not after the window, not other users, not signed out', () {
      final later = created.add(const Duration(minutes: 15));
      expect(
        canEditThread(thread: thread, user: user('author'), now: later),
        isFalse,
      );
      expect(
        canEditThread(thread: thread, user: user('other'), now: created),
        isFalse,
      );
      expect(canEditThread(thread: thread, user: null, now: created), isFalse);
    });
  });

  test('only admins moderate', () {
    expect(canModerateThreads(user('a', admin: true)), isTrue);
    expect(canModerateThreads(user('a')), isFalse);
    expect(canModerateThreads(null), isFalse);
  });

  group('comments', () {
    test('authors delete their non-deleted comments', () {
      expect(
        canDeleteComment(comment: comment('c'), user: user('author')),
        isTrue,
      );
      expect(
        canDeleteComment(comment: comment('c'), user: user('other')),
        isFalse,
      );
      expect(
        canDeleteComment(
          comment: comment('c', deleted: true),
          user: user('author'),
        ),
        isFalse,
      );
    });

    test('authors edit within the window', () {
      final c = comment('c', createdAt: created);
      expect(
        canEditComment(
          comment: c,
          user: user('author'),
          now: created.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
      expect(
        canEditComment(
          comment: c,
          user: user('author'),
          now: created.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
    });

    test('only top-level, non-deleted comments can be replied to', () {
      expect(canReplyTo(comment('c')), isTrue);
      expect(canReplyTo(comment('r', parent: 'c')), isFalse);
      expect(canReplyTo(comment('d', deleted: true)), isFalse);
    });

    test('frozen threads are read-only', () {
      expect(canComment(thread), isTrue);
      expect(
        canComment(ForumThread(
          id: 't',
          forumId: 'f',
          title: 'x',
          authorId: 'a',
          authorName: 'A',
          createdAt: created,
          updatedAt: created,
          commentCount: 0,
          isFrozen: true,
          isHidden: false,
        )),
        isFalse,
      );
    });

    test('threadedComments weaves replies, collapses and de-duplicates', () {
      final comments = [
        comment('p1'),
        comment('p2'),
        comment('r1', parent: 'p1'),
        comment('r2', parent: 'p2'),
        comment('r1', parent: 'p1'),
      ];
      expect(
        threadedComments(comments).map((c) => c.id),
        ['p1', 'r1', 'p2', 'r2'],
      );
      expect(
        threadedComments(comments, collapsed: {'p1'}).map((c) => c.id),
        ['p1', 'p2', 'r2'],
      );
      expect(hasReplies(comments, 'p1'), isTrue);
      expect(hasReplies(comments, 'r1'), isFalse);
    });
  });
}
