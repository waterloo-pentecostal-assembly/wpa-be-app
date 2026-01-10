part of 'thread_bloc.dart';

abstract class ThreadState extends Equatable {
  const ThreadState();

  @override
  List<Object> get props => [];
}

class ThreadInitial extends ThreadState {}

class ThreadLoading extends ThreadState {}

class ThreadLoaded extends ThreadState {
  final List<Comment> comments;
  final ForumThread thread;

  const ThreadLoaded({required this.comments, required this.thread});

  ThreadLoaded copyWith({List<Comment>? comments, ForumThread? thread}) {
    return ThreadLoaded(
      comments: comments ?? this.comments,
      thread: thread ?? this.thread,
    );
  }

  @override
  List<Object> get props => [comments, thread];
}

class ThreadError extends ThreadState {
  final String message;

  const ThreadError(this.message);

  @override
  List<Object> get props => [message];
}
