import '../authentication/entities.dart';
import 'entities.dart';

/// Authors may edit their thread title / comment for this long.
const kForumEditWindow = Duration(minutes: 15);

bool _withinEditWindow(DateTime createdAt, DateTime now) =>
    now.difference(createdAt).inMinutes < kForumEditWindow.inMinutes;

/// Thread authors may edit the title within [kForumEditWindow].
bool canEditThread({
  required ForumThread thread,
  required LocalUser? user,
  required DateTime now,
}) =>
    user != null &&
    user.id == thread.authorId &&
    _withinEditWindow(thread.createdAt, now);

/// Admins may freeze/unfreeze and hide/unhide threads.
bool canModerateThreads(LocalUser? user) => user?.isAdmin ?? false;

/// Authors may delete their own (not yet deleted) comments.
bool canDeleteComment({required Comment comment, required LocalUser? user}) =>
    !comment.isDeleted && user != null && user.id == comment.authorId;

/// Authors may edit their own comments within [kForumEditWindow].
bool canEditComment({
  required Comment comment,
  required LocalUser? user,
  required DateTime now,
}) =>
    canDeleteComment(comment: comment, user: user) &&
    _withinEditWindow(comment.createdAt, now);

/// Only top-level, non-deleted comments can be replied to.
bool canReplyTo(Comment comment) => !comment.isReply && !comment.isDeleted;

/// Frozen threads are read-only.
bool canComment(ForumThread? thread) => !(thread?.isFrozen ?? false);

bool hasReplies(List<Comment> comments, String commentId) =>
    comments.any((c) => c.parentId == commentId);

/// Orders comments as parent followed by its replies (server order kept),
/// skipping replies of [collapsed] parents and de-duplicating by id.
List<Comment> threadedComments(
  List<Comment> comments, {
  Set<String> collapsed = const {},
}) {
  final unique = <String, Comment>{for (final c in comments) c.id: c};
  final values = unique.values.toList();
  final parents = values.where((c) => c.parentId == null);
  final replies = values.where((c) => c.parentId != null).toList();
  final result = <Comment>[];
  for (final parent in parents) {
    result.add(parent);
    if (collapsed.contains(parent.id)) continue;
    result.addAll(replies.where((r) => r.parentId == parent.id));
  }
  return result;
}
