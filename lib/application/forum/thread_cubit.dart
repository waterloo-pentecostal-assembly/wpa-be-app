import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/entities.dart';
import '../../domain/authentication/session.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/forum/entities.dart';
import '../../domain/forum/interfaces.dart';
import '../../domain/forum/policies.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';

/// What the current user may do with a comment (decided by domain policies).
class CommentPermissions extends Equatable {
  const CommentPermissions({
    required this.canEdit,
    required this.canDelete,
    required this.canReply,
    required this.isLiked,
  });

  final bool canEdit;
  final bool canDelete;
  final bool canReply;
  final bool isLiked;

  @override
  List<Object?> get props => [canEdit, canDelete, canReply, isLiked];
}

class ThreadState extends Equatable {
  const ThreadState({
    this.status = LoadStatus.initial,
    this.thread,
    this.comments = const [],
    this.collapsedIds = const {},
    this.isFollowing,
    this.replyTo,
    this.editing,
    this.user,
    this.errorMessage,
    this.message,
    this.messageId = 0,
    this.closeRequested = false,
  });

  final LoadStatus status;
  final ForumThread? thread;

  /// All comments in server order (oldest first).
  final List<Comment> comments;
  final Set<String> collapsedIds;

  /// `null` until notification settings are loaded.
  final bool? isFollowing;

  /// Comment being replied to.
  final Comment? replyTo;

  /// Comment being edited.
  final Comment? editing;
  final LocalUser? user;
  final String? errorMessage;

  /// One-shot snackbar message.
  final String? message;
  final int messageId;

  /// The screen should close (thread hidden/unhidden by an admin).
  final bool closeRequested;

  /// Comments as displayed: parents followed by (non-collapsed) replies.
  List<Comment> get visibleComments =>
      threadedComments(comments, collapsed: collapsedIds);

  bool hasReplies(String commentId) =>
      comments.any((c) => c.parentId == commentId);

  String get title => thread?.title ?? 'Thread';
  bool get isFrozen => thread?.isFrozen ?? false;
  bool get isHidden => thread?.isHidden ?? false;
  bool get canComment => !isFrozen;
  bool get canModerate => canModerateThreads(user);

  ThreadState copyWith({
    LoadStatus? status,
    ForumThread? thread,
    List<Comment>? comments,
    Set<String>? collapsedIds,
    bool? isFollowing,
    Comment? Function()? replyTo,
    Comment? Function()? editing,
    String? errorMessage,
    String? message,
    int? messageId,
    bool? closeRequested,
  }) {
    return ThreadState(
      status: status ?? this.status,
      thread: thread ?? this.thread,
      comments: comments ?? this.comments,
      collapsedIds: collapsedIds ?? this.collapsedIds,
      isFollowing: isFollowing ?? this.isFollowing,
      replyTo: replyTo != null ? replyTo() : this.replyTo,
      editing: editing != null ? editing() : this.editing,
      user: user,
      errorMessage: errorMessage ?? this.errorMessage,
      message: message ?? this.message,
      messageId: messageId ?? this.messageId,
      closeRequested: closeRequested ?? this.closeRequested,
    );
  }

  @override
  List<Object?> get props => [
        status,
        thread,
        comments,
        collapsedIds,
        isFollowing,
        replyTo,
        editing,
        user,
        errorMessage,
        message,
        messageId,
        closeRequested,
      ];
}

/// Thread detail: thread, comments, replies, likes, edit/delete, follow and
/// admin moderation. All permission decisions come from domain policies.
class ThreadCubit extends Cubit<ThreadState> {
  ThreadCubit({
    required this.forumId,
    required this.threadId,
    required IForumRepository forumRepository,
    required INotificationSettingsService notificationSettings,
    required ISession session,
    required AppEventBus events,
    DateTime Function()? clock,
  })  : _forum = forumRepository,
        _notifications = notificationSettings,
        _events = events,
        _clock = clock ?? DateTime.now,
        super(ThreadState(user: session.currentUser));

  final String forumId;
  final String threadId;
  final IForumRepository _forum;
  final INotificationSettingsService _notifications;
  final AppEventBus _events;
  final DateTime Function() _clock;
  StreamSubscription<ForumThread?>? _threadSub;
  StreamSubscription<List<Comment>>? _commentsSub;

  void _safeEmit(ThreadState s) {
    if (!isClosed) emit(s);
  }

  void _message(String text) =>
      _safeEmit(state.copyWith(message: text, messageId: nextEffectId()));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, stackTrace) {
      _message(userMessageFor(e, stackTrace: stackTrace));
    }
  }

  Future<void> load() async {
    _safeEmit(state.copyWith(status: LoadStatus.loading));
    await _threadSub?.cancel();
    await _commentsSub?.cancel();
    _threadSub = _forum.watchThread(threadId, forumId).listen(
          (thread) => _safeEmit(
            ThreadState(
              status: state.comments.isNotEmpty || thread != null
                  ? LoadStatus.success
                  : state.status,
              thread: thread,
              comments: state.comments,
              collapsedIds: state.collapsedIds,
              isFollowing: state.isFollowing,
              replyTo: state.replyTo,
              editing: state.editing,
              user: state.user,
              message: state.message,
              messageId: state.messageId,
              closeRequested: state.closeRequested,
            ),
          ),
          onError: reportError,
        );
    _commentsSub = _forum.watchComments(threadId, forumId).listen(
          (comments) => _safeEmit(
            state.copyWith(status: LoadStatus.success, comments: comments),
          ),
          onError: (Object e, StackTrace stackTrace) =>
              _safeEmit(state.copyWith(
            status: LoadStatus.failure,
            errorMessage: userMessageFor(e, stackTrace: stackTrace),
          )),
        );
    try {
      final settings = await _notifications.getNotificationSettings();
      _safeEmit(state.copyWith(
        isFollowing: settings.threadsFollowed.contains(threadId),
      ));
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      // Follow option hidden when settings are unavailable.
    }
  }

  // ---- permissions -------------------------------------------------------

  bool get canEditThread {
    final thread = state.thread;
    return thread != null &&
        canEditThreadPolicy(thread: thread, user: state.user, now: _clock());
  }

  CommentPermissions permissionsFor(Comment comment) => CommentPermissions(
        canEdit:
            canEditComment(comment: comment, user: state.user, now: _clock()),
        canDelete: canDeleteComment(comment: comment, user: state.user),
        canReply: canReplyTo(comment),
        isLiked: comment.likedBy.contains(state.user?.id ?? ''),
      );

  // ---- composing ---------------------------------------------------------

  void startReply(Comment comment) => _safeEmit(state.copyWith(
        replyTo: () => comment,
        editing: () => null,
        collapsedIds: {...state.collapsedIds}..remove(comment.id),
      ));

  void cancelReply() => _safeEmit(state.copyWith(replyTo: () => null));

  void startEdit(Comment comment) => _safeEmit(state.copyWith(
        editing: () => comment,
        replyTo: () => null,
      ));

  void cancelEdit() => _safeEmit(state.copyWith(editing: () => null));

  void toggleReplies(String commentId) {
    final ids = {...state.collapsedIds};
    ids.contains(commentId) ? ids.remove(commentId) : ids.add(commentId);
    _safeEmit(state.copyWith(collapsedIds: ids));
  }

  /// Sends the composer text as an edit, a reply or a new comment.
  Future<void> submit(String text) async {
    if (text.isEmpty) return;
    final editing = state.editing;
    if (editing != null) {
      _safeEmit(state.copyWith(editing: () => null));
      await _guard(
        () => _forum.updateComment(editing.id, threadId, forumId, text),
      );
      return;
    }
    final user = state.user;
    final parentId = state.replyTo?.id;
    _safeEmit(state.copyWith(replyTo: () => null));
    await _guard(() => _forum.addComment(
          NewComment(
            threadId: threadId,
            body: text,
            authorId: user?.id ?? '',
            authorName: user?.fullName ?? 'Anonymous',
            authorImageUrl: user?.profilePhotoUrl,
            parentId: parentId,
          ),
          forumId,
        ));
  }

  // ---- comment actions ---------------------------------------------------

  Future<void> toggleLike(Comment comment) async {
    final user = state.user;
    if (user == null) {
      _message('You need to sign in to like comments');
      return;
    }
    if (comment.likedBy.contains(user.id)) {
      await _guard(
        () => _forum.unlikeComment(comment.id, threadId, forumId, user.id),
      );
    } else {
      await _guard(
        () => _forum.likeComment(comment.id, threadId, forumId, user.id),
      );
    }
  }

  Future<void> report(Comment comment) async {
    _message('Reported');
    await _guard(() =>
        _forum.reportComment(comment.id, threadId, forumId, 'User Report'));
  }

  Future<void> delete(Comment comment) =>
      _guard(() => _forum.deleteComment(comment.id, threadId, forumId));

  // ---- thread actions ----------------------------------------------------

  Future<void> updateTitle(String title) =>
      _guard(() => _forum.updateThread(threadId, forumId, title));

  Future<void> setFrozen(bool frozen) =>
      _guard(() => _forum.freezeThread(threadId, forumId, frozen));

  /// Hides/unhides the thread and closes the screen.
  Future<void> setHidden(bool hidden) async {
    _safeEmit(state.copyWith(closeRequested: true));
    await _guard(() => _forum.hideThread(threadId, forumId, hidden));
  }

  Future<void> setFollowing(bool follow) async {
    _safeEmit(state.copyWith(isFollowing: follow));
    _message(follow ? 'Thread followed' : 'Thread unfollowed');
    try {
      follow
          ? await _notifications.followThread(threadId)
          : await _notifications.unfollowThread(threadId);
      _events
          .emit(ThreadFollowChanged(threadId: threadId, isFollowing: follow));
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _safeEmit(state.copyWith(isFollowing: !follow));
      _message(
          follow ? 'Unable to follow thread' : 'Unable to unfollow thread');
    }
  }

  @override
  Future<void> close() async {
    await _threadSub?.cancel();
    await _commentsSub?.cancel();
    return super.close();
  }
}

/// Alias so the cubit getter can share the policy name.
const canEditThreadPolicy = canEditThread;
