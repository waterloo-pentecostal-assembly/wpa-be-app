import 'entities.dart';

abstract class IForumRepository {
  Stream<Forum> watchForum(String forumId);
  Stream<List<ForumThread>> watchThreads(String forumId);
  Future<void> createThread(ForumThread thread);
  Future<void> freezeThread(String threadId, String forumId, bool isFrozen);

  Stream<List<Comment>> watchComments(String threadId, String forumId);
  Future<void> addComment(Comment comment, String forumId);
  Future<void> deleteComment(String commentId, String threadId, String forumId);
  Future<void> reportComment(
      String commentId, String threadId, String forumId, String reason);
  Future<void> likeComment(String commentId, String threadId, String forumId);
  Future<void> unlikeComment(String commentId, String threadId, String forumId);
}
