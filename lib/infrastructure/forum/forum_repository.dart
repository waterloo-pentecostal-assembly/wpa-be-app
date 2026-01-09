import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/domain/forum/interfaces.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

class ForumRepository implements IForumRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;

  ForumRepository(this._firestore, this._firebaseFirestoreService);

  @override
  Stream<Forum> watchForum(String forumId) {
    return _firestore
        .collection('forums')
        .doc(forumId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return Forum.empty();
      }
      final data = snapshot.data();
      if (data == null) return Forum.empty();

      return Forum(
        id: snapshot.id,
        title: data['title'] ?? '',
        isFrozen: data['is_frozen'] ?? false,
        isReadOnly: data['is_read_only'] ?? false,
      );
    }).handleError((e) {
      throw _firebaseFirestoreService.handleException(e);
    });
  }

  @override
  Stream<List<ForumThread>> watchThreads(String forumId) {
    return _firestore
        .collection('forums')
        .doc(forumId)
        .collection('threads')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ForumThread(
          id: doc.id,
          forumId: forumId,
          title: data['title'] ?? '',
          authorId: data['author_id'] ?? '',
          authorName: data['author_name'] ?? '',
          authorImageUrl: data['author_image_url'],
          createdAt: data['created_at'] as Timestamp,
          updatedAt: data['updated_at'] as Timestamp,
          commentCount: data['comment_count'] ?? 0,
          isFrozen: data['is_frozen'] ?? false,
        );
      }).toList();
    }).handleError((e) {
      throw _firebaseFirestoreService.handleException(e);
    });
  }

  @override
  Future<void> createThread(ForumThread thread) async {
    try {
      await _firestore
          .collection('forums')
          .doc(thread.forumId)
          .collection('threads')
          .doc(thread.id.isNotEmpty ? thread.id : null)
          .set({
        'title': thread.title,
        'author_id': thread.authorId,
        'author_name': thread.authorName,
        'author_image_url': thread.authorImageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'comment_count': 0,
        'is_frozen': false,
      });
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }

  @override
  Future<void> freezeThread(
      String threadId, String forumId, bool isFrozen) async {
    try {
      await _firestore
          .collection('forums')
          .doc(forumId)
          .collection('threads')
          .doc(threadId)
          .update({'is_frozen': isFrozen});
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }

  @override
  Stream<List<Comment>> watchComments(String threadId, String forumId) {
    return _firestore
        .collection('forums')
        .doc(forumId)
        .collection('threads')
        .doc(threadId)
        .collection('comments')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          threadId: threadId,
          body: data['body'] ?? '',
          authorId: data['author_id'] ?? '',
          authorName: data['author_name'] ?? '',
          authorImageUrl: data['author_image_url'],
          createdAt: data['created_at'] as Timestamp,
          updatedAt: data['updated_at'] as Timestamp,
          parentId: data['parent_id'],
          isHidden: data['is_hidden'] ?? false,
          isDeleted: data['is_deleted'] ?? false,
          likedBy: List<String>.from(data['liked_by'] ?? []),
          reportCount: data['report_count'] ?? 0,
        );
      }).toList();
    }).handleError((e) {
      throw _firebaseFirestoreService.handleException(e);
    });
  }

  @override
  Future<void> addComment(Comment comment, String forumId) async {
    try {
      final threadRef = _firestore
          .collection('forums')
          .doc(forumId)
          .collection('threads')
          .doc(comment.threadId);

      await _firestore.runTransaction((transaction) async {
        final threadSnapshot = await transaction.get(threadRef);
        if (!threadSnapshot.exists) {
          throw Exception("Thread does not exist");
        }

        final commentsRef = threadRef.collection('comments').doc();
        transaction.set(commentsRef, {
          'thread_id': comment.threadId,
          'body': comment.body,
          'author_id': comment.authorId,
          'author_name': comment.authorName,
          'author_image_url': comment.authorImageUrl,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'parent_id': comment.parentId,
          'is_hidden': false,
          'is_deleted': false,
          'liked_by': [],
          'report_count': 0,
        });

        transaction
            .update(threadRef, {'comment_count': FieldValue.increment(1)});
      });
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }

  @override
  Future<void> deleteComment(
      String commentId, String threadId, String forumId) async {
    try {
      await _firestore
          .collection('forums')
          .doc(forumId)
          .collection('threads')
          .doc(threadId)
          .collection('comments')
          .doc(commentId)
          .update({'is_deleted': true});
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }

  @override
  Future<void> reportComment(
      String commentId, String threadId, String forumId, String reason) async {
    try {
      // Also create a report document ideally, but for now just increment/update flag
      await _firestore
          .collection('forums')
          .doc(forumId)
          .collection('threads')
          .doc(threadId)
          .collection('comments')
          .doc(commentId)
          .update({
        'report_count': FieldValue.increment(1),
        // We might want to set is_hidden if reports > threshold, but for now just report
      });
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }

  @override
  Future<void> likeComment(
      String commentId, String threadId, String forumId, String userId) async {
    try {
      await _firestore
          .collection('forums')
          .doc(forumId)
          .collection('threads')
          .doc(threadId)
          .collection('comments')
          .doc(commentId)
          .update({
        'liked_by': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }

  @override
  Future<void> unlikeComment(
      String commentId, String threadId, String forumId, String userId) async {
    try {
      await _firestore
          .collection('forums')
          .doc(forumId)
          .collection('threads')
          .doc(threadId)
          .collection('comments')
          .doc(commentId)
          .update({
        'liked_by': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw _firebaseFirestoreService.handleException(e as Exception);
    }
  }
}
