import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/common/community_post.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/paging.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';
import 'post_actions.dart';

/// Kind of one-shot message a list screen should show.
enum PostListMessageKind { info, error }

class PostListState<T extends CommunityPost> extends Equatable {
  const PostListState({
    this.status = LoadStatus.initial,
    this.posts = const [],
    this.isEndOfList = false,
    this.isLoadingMore = false,
    this.reactingIds = const {},
    this.errorMessage,
    this.message,
    this.messageKind = PostListMessageKind.info,
    this.messageId = 0,
  });

  final LoadStatus status;
  final List<T> posts;
  final bool isEndOfList;
  final bool isLoadingMore;

  /// Posts with a react (pray/amen) request in flight.
  final Set<String> reactingIds;

  /// Error shown instead of the list when loading failed.
  final String? errorMessage;

  /// One-shot toast; [messageId] changes for each new message.
  final String? message;
  final PostListMessageKind messageKind;
  final int messageId;

  PostListState<T> copyWith({
    LoadStatus? status,
    List<T>? posts,
    bool? isEndOfList,
    bool? isLoadingMore,
    Set<String>? reactingIds,
    String? errorMessage,
  }) {
    return PostListState<T>(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      isEndOfList: isEndOfList ?? this.isEndOfList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      reactingIds: reactingIds ?? this.reactingIds,
      errorMessage: errorMessage ?? this.errorMessage,
      message: message,
      messageKind: messageKind,
      messageId: messageId,
    );
  }

  PostListState<T> withMessage(String text, PostListMessageKind kind) =>
      PostListState<T>(
        status: status,
        posts: posts,
        isEndOfList: isEndOfList,
        isLoadingMore: isLoadingMore,
        reactingIds: reactingIds,
        errorMessage: errorMessage,
        message: text,
        messageKind: kind,
        messageId: nextEffectId(),
      );

  @override
  List<Object?> get props => [
        status,
        posts,
        isEndOfList,
        isLoadingMore,
        reactingIds,
        errorMessage,
        message,
        messageKind,
        messageId,
      ];
}

/// Copy shown by list screens after successful actions.
class PostListCopy {
  const PostListCopy({required this.reportedMessage});

  /// e.g. "Prayer Request has been reported".
  final String reportedMessage;
}

/// Base class of the per-screen post list cubits. Subclasses decide what to
/// load and how to react to cross-screen [AppEvent]s.
abstract class PostListCubit<T extends CommunityPost>
    extends Cubit<PostListState<T>> {
  PostListCubit({
    required this.actions,
    required AppEventBus events,
    this.listCopy,
  }) : super(PostListState<T>()) {
    _eventsSub = events.stream.listen(onAppEvent);
  }

  final PostActions<T> actions;
  final PostListCopy? listCopy;
  late final StreamSubscription<AppEvent> _eventsSub;

  /// Loads (or reloads) the list.
  Future<void> load();

  Future<void> refresh() => load();

  /// Reacts to changes made from other screens (or this one).
  void onAppEvent(AppEvent event) {
    if (event is PostDeleted<T>) removePost(event.id);
  }

  void safeEmit(PostListState<T> s) {
    if (!isClosed) emit(s);
  }

  void showMessage(String text, PostListMessageKind kind) =>
      safeEmit(state.withMessage(text, kind));

  void removePost(String id) {
    if (!state.posts.any((p) => p.id == id)) return;
    safeEmit(state.copyWith(
      posts: state.posts.where((p) => p.id != id).toList(),
    ));
  }

  void insertPostAtTop(T post) =>
      safeEmit(state.copyWith(posts: [post, ...state.posts]));

  Future<void> loadList(Future<List<T>> Function() fetch) async {
    if (state.posts.isEmpty) {
      safeEmit(state.copyWith(status: LoadStatus.loading));
    }
    try {
      final posts = await fetch();
      safeEmit(PostListState<T>(status: LoadStatus.success, posts: posts));
    } catch (e) {
      safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e),
      ));
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await actions.delete(id);
    } on PostActionException catch (e) {
      showMessage(e.message, PostListMessageKind.error);
    }
  }

  /// Marks the post answered / archived.
  Future<void> closePost(String id) async {
    try {
      await actions.close(id);
    } on PostActionException catch (e) {
      showMessage(e.message, PostListMessageKind.error);
    }
  }

  Future<void> reportPost(String id) async {
    try {
      await actions.report(id);
      final copy = listCopy;
      if (copy != null) {
        showMessage(copy.reportedMessage, PostListMessageKind.info);
      }
    } on PostActionException catch (e) {
      showMessage(e.message, PostListMessageKind.error);
    }
  }

  @override
  Future<void> close() async {
    await _eventsSub.cancel();
    return super.close();
  }
}

/// "All" tab: approved open posts, paginated, with react + report.
class AllPostsCubit<T extends CommunityPost> extends PostListCubit<T> {
  AllPostsCubit({
    required super.actions,
    required super.events,
    required PostListCopy super.listCopy,
    this.pageSize = defaultPageSize,
  });

  /// Fixed page size (replaces the old screen-height based calculation).
  static const defaultPageSize = 15;

  final int pageSize;
  PageCursor? _cursor;

  @override
  void onAppEvent(AppEvent event) {
    super.onAppEvent(event);
    if (event is PostReported<T>) removePost(event.id);
    if (event is PostClosed<T>) removePost(event.post.id);
    if (event is PostReacted<T>) _markReacted(event.id);
  }

  @override
  Future<void> load() async {
    if (state.posts.isEmpty) {
      safeEmit(state.copyWith(status: LoadStatus.loading));
    }
    try {
      final page = await actions.repository.fetchPage(limit: pageSize);
      _cursor = page.nextCursor;
      safeEmit(PostListState<T>(
        status: LoadStatus.success,
        posts: page.items,
        isEndOfList: page.isEnd,
      ));
    } catch (e) {
      safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e),
      ));
    }
  }

  /// Loads the next page (no-op at the end or while loading).
  Future<void> loadMore() async {
    if (state.isEndOfList || state.isLoadingMore || _cursor == null) return;
    safeEmit(state.copyWith(isLoadingMore: true));
    try {
      final page =
          await actions.repository.fetchPage(limit: pageSize, after: _cursor);
      _cursor = page.nextCursor;
      safeEmit(state.copyWith(
        posts: [...state.posts, ...page.items],
        isEndOfList: page.isEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      safeEmit(state.copyWith(isLoadingMore: false));
      showMessage(userMessageFor(e), PostListMessageKind.error);
    }
  }

  /// Pray / say amen.
  Future<void> react(String id) async {
    safeEmit(state.copyWith(reactingIds: {...state.reactingIds, id}));
    try {
      await actions.react(id);
    } on PostActionException catch (e) {
      showMessage(e.message, PostListMessageKind.error);
    } finally {
      safeEmit(state.copyWith(
        reactingIds: {...state.reactingIds}..remove(id),
      ));
    }
  }

  void _markReacted(String id) {
    safeEmit(state.copyWith(
      posts: [
        for (final p in state.posts) p.id == id ? p.markReacted() as T : p,
      ],
    ));
  }
}

/// "My open" tab: the user's open posts (new posts appear at the top).
class MyPostsCubit<T extends CommunityPost> extends PostListCubit<T> {
  MyPostsCubit({required super.actions, required super.events});

  @override
  void onAppEvent(AppEvent event) {
    super.onAppEvent(event);
    if (event is PostCreated<T>) insertPostAtTop(event.post);
    if (event is PostClosed<T>) removePost(event.post.id);
  }

  @override
  Future<void> load() => loadList(actions.repository.fetchMine);
}

/// "My answered / archived" tab: the user's closed posts.
class MyClosedPostsCubit<T extends CommunityPost> extends PostListCubit<T> {
  MyClosedPostsCubit({required super.actions, required super.events});

  @override
  void onAppEvent(AppEvent event) {
    super.onAppEvent(event);
    if (event is PostClosed<T>) insertPostAtTop(event.post);
  }

  @override
  Future<void> load() => loadList(actions.repository.fetchMineClosed);
}
