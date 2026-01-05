part of 'forum_bloc.dart';

abstract class ForumState extends Equatable {
  const ForumState();

  @override
  List<Object> get props => [];
}

class ForumInitial extends ForumState {}

class ForumLoading extends ForumState {}

class ForumLoaded extends ForumState {
  final Forum forum;
  final List<ForumThread> threads;

  const ForumLoaded({required this.forum, required this.threads});

  ForumLoaded copyWith({Forum? forum, List<ForumThread>? threads}) {
    return ForumLoaded(
      forum: forum ?? this.forum,
      threads: threads ?? this.threads,
    );
  }

  @override
  List<Object> get props => [forum, threads];
}

class ForumError extends ForumState {
  final String message;

  const ForumError(this.message);

  @override
  List<Object> get props => [message];
}
