import 'entities.dart';

abstract class IForumRepository {
  Stream<Forum> watchForum(String forumId);

  /// Threads newest first. Hidden threads are included (as before the
  /// refactor); the UI marks them for admins.
  Stream<List<ForumThread>> watchThreads(String forumId, {bool isAdmin});

  Stream<ForumThread?> watchThread(String threadId, String forumId);

  /// Creates a thread (client-generated id) and returns its id.
  Future<String> createThread(NewThread thread);

  Future<void> freezeThread(String threadId, String forumId, bool isFrozen);
  Future<void> hideThread(String threadId, String forumId, bool isHidden);
  Future<void> updateThread(String threadId, String forumId, String newTitle);

  /// Comments oldest first.
  Stream<List<Comment>> watchComments(String threadId, String forumId);
  Future<void> addComment(NewComment comment, String forumId);
  Future<void> deleteComment(String commentId, String threadId, String forumId);
  Future<void> reportComment(
    String commentId,
    String threadId,
    String forumId,
    String reason,
  );
  Future<void> likeComment(
    String commentId,
    String threadId,
    String forumId,
    String userId,
  );
  Future<void> unlikeComment(
    String commentId,
    String threadId,
    String forumId,
    String userId,
  );
  Future<void> updateComment(
    String commentId,
    String threadId,
    String forumId,
    String newBody,
  );
}
