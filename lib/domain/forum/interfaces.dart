import 'entities.dart';

abstract class IForumRepository {
  Stream<Forum> watchForum(String forumId);
  Stream<List<ForumThread>> watchThreads(String forumId, {bool isAdmin});
  Stream<ForumThread> watchThread(String threadId, String forumId);
  Future<void> createThread(ForumThread thread);
  Future<void> freezeThread(String threadId, String forumId, bool isFrozen);
  Future<void> hideThread(String threadId, String forumId, bool isHidden);

  Stream<List<Comment>> watchComments(String threadId, String forumId);
  Future<void> addComment(Comment comment, String forumId);
  Future<void> deleteComment(String commentId, String threadId, String forumId);
  Future<void> reportComment(
      String commentId, String threadId, String forumId, String reason);
  Future<void> likeComment(
      String commentId, String threadId, String forumId, String userId);
  Future<void> unlikeComment(
      String commentId, String threadId, String forumId, String userId);

  Future<void> updateThread(String threadId, String forumId, String newTitle);
  Future<void> updateComment(
      String commentId, String threadId, String forumId, String newBody);
}
