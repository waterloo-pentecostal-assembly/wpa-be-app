import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/domain/forum/interfaces.dart';

part 'thread_event.dart';
part 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final IForumRepository _forumRepository;
  StreamSubscription<List<Comment>>? _commentsSubscription;

  ThreadBloc(this._forumRepository) : super(ThreadInitial()) {
    on<LoadThreadComments>(_onLoadThreadComments);
    on<CommentsUpdated>(_onCommentsUpdated);
    on<AddComment>(_onAddComment);
    on<DeleteComment>(_onDeleteComment);
    on<ReportComment>(_onReportComment);
    on<LikeComment>(_onLikeComment);
    on<UnlikeComment>(_onUnlikeComment);
    on<FreezeThread>(_onFreezeThread);
    on<UnfreezeThread>(_onUnfreezeThread);
    on<HideThread>(_onHideThread);
  }

  Future<void> _onLoadThreadComments(
      LoadThreadComments event, Emitter<ThreadState> emit) async {
    emit(ThreadLoading());
    try {
      await _commentsSubscription?.cancel();
      _commentsSubscription = _forumRepository
          .watchComments(event.threadId, event.forumId)
          .listen((comments) => add(CommentsUpdated(comments)), onError: (e) {
        // Handle error
      });
    } catch (e) {
      emit(ThreadError(e.toString()));
    }
  }

  Future<void> _onCommentsUpdated(
      CommentsUpdated event, Emitter<ThreadState> emit) async {
    emit(ThreadLoaded(comments: event.comments));
  }

  Future<void> _onAddComment(
      AddComment event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.addComment(event.comment, event.forumId);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onDeleteComment(
      DeleteComment event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.deleteComment(
          event.commentId, event.threadId, event.forumId);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onReportComment(
      ReportComment event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.reportComment(
          event.commentId, event.threadId, event.forumId, event.reason);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onLikeComment(
      LikeComment event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.likeComment(
          event.commentId, event.threadId, event.forumId, event.userId);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onUnlikeComment(
      UnlikeComment event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.unlikeComment(
          event.commentId, event.threadId, event.forumId, event.userId);
    } catch (e) {
      // emit error
    }
  }

  @override
  Future<void> close() {
    _commentsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFreezeThread(
      FreezeThread event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.freezeThread(event.threadId, event.forumId, true);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onUnfreezeThread(
      UnfreezeThread event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.freezeThread(event.threadId, event.forumId, false);
    } catch (e) {
      // emit error
    }
  }

  Future<void> _onHideThread(
      HideThread event, Emitter<ThreadState> emit) async {
    try {
      await _forumRepository.hideThread(
          event.threadId, event.forumId, event.isHidden);
    } catch (e) {
      // emit error
    }
  }
}
