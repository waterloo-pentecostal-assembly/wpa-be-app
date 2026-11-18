import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/forum/entities.dart';
import '../../domain/forum/exceptions.dart';
import '../../domain/forum/interfaces.dart';
import '../common/firestore_errors.dart';
import 'forum_dto.dart';

class ForumRepository implements IForumRepository {
  ForumRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _forum(String forumId) =>
      _firestore.collection('forums').doc(forumId);

  CollectionReference<Map<String, dynamic>> _threads(String forumId) =>
      _forum(forumId).collection('threads');

  DocumentReference<Map<String, dynamic>> _thread(
    String threadId,
    String forumId,
  ) =>
      _threads(forumId).doc(threadId);

  DocumentReference<Map<String, dynamic>> _comment(
    String commentId,
    String threadId,
    String forumId,
  ) =>
      _thread(threadId, forumId).collection('comments').doc(commentId);

  @override
  Stream<Forum> watchForum(String forumId) =>
      _forum(forumId).snapshots().map(forumFromFirestore).mapFirestoreErrors();

  @override
  Stream<List<ForumThread>> watchThreads(String forumId,
      {bool isAdmin = false}) {
    // Hidden threads are not filtered out for non-admins (unchanged behaviour;
    // the filter was disabled before the refactor).
    return _threads(forumId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => threadFromFirestore(forumId, doc.id, doc.data()))
            .toList())
        .mapFirestoreErrors();
  }

  @override
  Stream<ForumThread?> watchThread(String threadId, String forumId) =>
      _thread(threadId, forumId)
          .snapshots()
          .map((doc) => doc.exists && doc.data() != null
              ? threadFromFirestore(forumId, doc.id, doc.data()!)
              : null)
          .mapFirestoreErrors();

  @override
  Future<String> createThread(NewThread thread) async {
    final ref = _threads(thread.forumId).doc();
    await guardFirestore(() => ref.set(newThreadDocument(thread)));
    return ref.id;
  }

  @override
  Future<void> freezeThread(String threadId, String forumId, bool isFrozen) =>
      guardFirestore(
          () => _thread(threadId, forumId).update({'is_frozen': isFrozen}));

  @override
  Future<void> hideThread(String threadId, String forumId, bool isHidden) =>
      guardFirestore(
          () => _thread(threadId, forumId).update({'is_hidden': isHidden}));

  @override
  Future<void> updateThread(String threadId, String forumId, String newTitle) =>
      guardFirestore(() => _thread(threadId, forumId).update({
            'title': newTitle,
            'updated_at': FieldValue.serverTimestamp(),
          }));

  @override
  Stream<List<Comment>> watchComments(String threadId, String forumId) =>
      _thread(threadId, forumId)
          .collection('comments')
          .orderBy('created_at', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => commentFromFirestore(threadId, doc.id, doc.data()))
              .toList())
          .mapFirestoreErrors();

  @override
  Future<void> addComment(NewComment comment, String forumId) {
    return guardFirestore(() async {
      final threadRef = _thread(comment.threadId, forumId);
      await _firestore.runTransaction((transaction) async {
        final threadSnapshot = await transaction.get(threadRef);
        if (!threadSnapshot.exists) {
          throw const ForumException(
            code: ForumExceptionCode.threadNotFound,
            message: 'This thread no longer exists',
          );
        }
        transaction.set(
          threadRef.collection('comments').doc(),
          newCommentDocument(comment),
        );
        transaction
            .update(threadRef, {'comment_count': FieldValue.increment(1)});
      });
    });
  }

  @override
  Future<void> deleteComment(
          String commentId, String threadId, String forumId) =>
      guardFirestore(() =>
          _comment(commentId, threadId, forumId).update({'is_deleted': true}));

  @override
  Future<void> reportComment(
    String commentId,
    String threadId,
    String forumId,
    String reason,
  ) =>
      guardFirestore(() => _comment(commentId, threadId, forumId)
          .update({'report_count': FieldValue.increment(1)}));

  @override
  Future<void> likeComment(
    String commentId,
    String threadId,
    String forumId,
    String userId,
  ) =>
      guardFirestore(() => _comment(commentId, threadId, forumId).update({
            'liked_by': FieldValue.arrayUnion([userId]),
          }));

  @override
  Future<void> unlikeComment(
    String commentId,
    String threadId,
    String forumId,
    String userId,
  ) =>
      guardFirestore(() => _comment(commentId, threadId, forumId).update({
            'liked_by': FieldValue.arrayRemove([userId]),
          }));

  @override
  Future<void> updateComment(
    String commentId,
    String threadId,
    String forumId,
    String newBody,
  ) =>
      guardFirestore(() => _comment(commentId, threadId, forumId).update({
            'body': newBody,
            'updated_at': FieldValue.serverTimestamp(),
          }));
}
