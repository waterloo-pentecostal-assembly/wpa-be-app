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

  const ThreadLoaded({required this.comments});

  ThreadLoaded copyWith({List<Comment>? comments}) {
    return ThreadLoaded(
      comments: comments ?? this.comments,
    );
  }

  @override
  List<Object> get props => [comments];
}

class ThreadError extends ThreadState {
  final String message;

  const ThreadError(this.message);

  @override
  List<Object> get props => [message];
}
