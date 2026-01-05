part of 'forum_bloc.dart';

abstract class ForumEvent extends Equatable {
  const ForumEvent();

  @override
  List<Object> get props => [];
}

class LoadForum extends ForumEvent {
  final String forumId;

  const LoadForum(this.forumId);

  @override
  List<Object> get props => [forumId];
}

class ForumUpdated extends ForumEvent {
  final Forum forum;

  const ForumUpdated(this.forum);

  @override
  List<Object> get props => [forum];
}

class ThreadsUpdated extends ForumEvent {
  final List<ForumThread> threads;

  const ThreadsUpdated(this.threads);

  @override
  List<Object> get props => [threads];
}

class CreateThread extends ForumEvent {
  final ForumThread thread;

  const CreateThread(this.thread);

  @override
  List<Object> get props => [thread];
}

class FreezeThread extends ForumEvent {
  final String threadId;
  final String forumId;
  final bool isFrozen;

  const FreezeThread(this.threadId, this.forumId, this.isFrozen);

  @override
  List<Object> get props => [threadId, forumId, isFrozen];
}
