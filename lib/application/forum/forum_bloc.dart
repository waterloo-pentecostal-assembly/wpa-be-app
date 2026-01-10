import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/domain/forum/interfaces.dart';

part 'forum_event.dart';
part 'forum_state.dart';

class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final IForumRepository _forumRepository;
  StreamSubscription<List<ForumThread>>? _threadsSubscription;
  StreamSubscription<Forum>? _forumSubscription;

  ForumBloc(this._forumRepository) : super(ForumInitial()) {
    on<LoadForum>(_onLoadForum);
    on<ForumUpdated>(_onForumUpdated);
    on<ThreadsUpdated>(_onThreadsUpdated);
    on<CreateThread>(_onCreateThread);
    on<FreezeThread>(_onFreezeThread);
    on<HideThread>(_onHideThread);
  }

  Future<void> _onLoadForum(LoadForum event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    try {
      await _forumSubscription?.cancel();
      _forumSubscription = _forumRepository
          .watchForum(event.forumId)
          .listen((forum) => add(ForumUpdated(forum)), onError: (e) {
        // Handle error
      });

      await _threadsSubscription?.cancel();
      _threadsSubscription = _forumRepository
          .watchThreads(event.forumId, isAdmin: event.includeHidden)
          .listen((threads) => add(ThreadsUpdated(threads)), onError: (e) {
        // Handle error
      });
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }

  Future<void> _onForumUpdated(
      ForumUpdated event, Emitter<ForumState> emit) async {
    if (state is ForumLoaded) {
      emit((state as ForumLoaded).copyWith(forum: event.forum));
    } else {
      emit(ForumLoaded(forum: event.forum, threads: []));
    }
  }

  Future<void> _onThreadsUpdated(
      ThreadsUpdated event, Emitter<ForumState> emit) async {
    if (state is ForumLoaded) {
      emit((state as ForumLoaded).copyWith(threads: event.threads));
    } else {
      // Wait for forum to load usually, but assuming it comes quick
      emit(ForumLoaded(forum: Forum.empty(), threads: event.threads));
    }
  }

  Future<void> _onCreateThread(
      CreateThread event, Emitter<ForumState> emit) async {
    try {
      await _forumRepository.createThread(event.thread);
    } catch (e) {
      // emit error or toast
    }
  }

  Future<void> _onFreezeThread(
      FreezeThread event, Emitter<ForumState> emit) async {
    try {
      await _forumRepository.freezeThread(
          event.threadId, event.forumId, event.isFrozen);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onHideThread(HideThread event, Emitter<ForumState> emit) async {
    try {
      await _forumRepository.hideThread(
          event.threadId, event.forumId, event.isHidden);
    } catch (e) {
      // emit error
    }
  }

  @override
  Future<void> close() {
    _threadsSubscription?.cancel();
    _forumSubscription?.cancel();
    return super.close();
  }
}
