part of 'thread_bloc.dart';

abstract class ThreadEvent extends Equatable {
  const ThreadEvent();

  @override
  List<Object> get props => [];
}

class LoadThread extends ThreadEvent {
  final String threadId;
  final String forumId;

  const LoadThread(this.threadId, this.forumId);

  @override
  List<Object> get props => [threadId, forumId];
}

class ThreadUpdated extends ThreadEvent {
  final ForumThread thread;

  const ThreadUpdated(this.thread);

  @override
  List<Object> get props => [thread];
}

class CommentsUpdated extends ThreadEvent {
  final List<Comment> comments;

  const CommentsUpdated(this.comments);

  @override
  List<Object> get props => [comments];
}

class AddComment extends ThreadEvent {
  final Comment comment;
  final String forumId; // Needed for path

  const AddComment(this.comment, this.forumId);

  @override
  List<Object> get props => [comment, forumId];
}

class DeleteComment extends ThreadEvent {
  final String commentId;
  final String threadId;
  final String forumId;

  const DeleteComment(this.commentId, this.threadId, this.forumId);

  @override
  List<Object> get props => [commentId, threadId, forumId];
}

class ReportComment extends ThreadEvent {
  final String commentId;
  final String threadId;
  final String forumId;
  final String reason;

  const ReportComment(this.commentId, this.threadId, this.forumId, this.reason);

  @override
  List<Object> get props => [commentId, threadId, forumId, reason];
}

class LikeComment extends ThreadEvent {
  final String commentId;
  final String threadId;
  final String forumId;
  final String userId;

  const LikeComment(this.commentId, this.threadId, this.forumId, this.userId);

  @override
  List<Object> get props => [commentId, threadId, forumId, userId];
}

class UnlikeComment extends ThreadEvent {
  final String commentId;
  final String threadId;
  final String forumId;
  final String userId;

  const UnlikeComment(this.commentId, this.threadId, this.forumId, this.userId);

  @override
  List<Object> get props => [commentId, threadId, forumId, userId];
}

class DeleteThread extends ThreadEvent {
  final String threadId;
  final String forumId;

  const DeleteThread(this.threadId, this.forumId);

  @override
  List<Object> get props => [threadId, forumId];
}

class HideThread extends ThreadEvent {
  final String threadId;
  final String forumId;
  final bool isHidden;

  const HideThread(this.threadId, this.forumId, this.isHidden);

  @override
  List<Object> get props => [threadId, forumId, isHidden];
}

class FreezeThread extends ThreadEvent {
  final String threadId;
  final String forumId;

  const FreezeThread(this.threadId, this.forumId);

  @override
  List<Object> get props => [threadId, forumId];
}

class UnfreezeThread extends ThreadEvent {
  final String threadId;
  final String forumId;

  const UnfreezeThread(this.threadId, this.forumId);

  @override
  List<Object> get props => [threadId, forumId];
}

class UpdateThread extends ThreadEvent {
  final String threadId;
  final String forumId;
  final String newTitle;

  const UpdateThread(this.threadId, this.forumId, this.newTitle);

  @override
  List<Object> get props => [threadId, forumId, newTitle];
}

class UpdateComment extends ThreadEvent {
  final String commentId;
  final String threadId;
  final String forumId;
  final String newBody;

  const UpdateComment(
      this.commentId, this.threadId, this.forumId, this.newBody);

  @override
  List<Object> get props => [commentId, threadId, forumId, newBody];
}
