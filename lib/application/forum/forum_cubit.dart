import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/forum/entities.dart';
import '../../domain/forum/interfaces.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';

class ForumState extends Equatable {
  const ForumState({
    this.status = LoadStatus.initial,
    this.forum = const Forum.empty(),
    this.threads = const [],
    this.followedThreadIds = const {},
    this.isAdmin = false,
    this.errorMessage,
    this.message,
    this.messageId = 0,
  });

  final LoadStatus status;
  final Forum forum;
  final List<ForumThread> threads;
  final Set<String> followedThreadIds;

  /// Admins see the hidden-thread marker.
  final bool isAdmin;
  final String? errorMessage;

  /// One-shot snackbar message.
  final String? message;
  final int messageId;

  ForumState copyWith({
    LoadStatus? status,
    Forum? forum,
    List<ForumThread>? threads,
    Set<String>? followedThreadIds,
    String? errorMessage,
    String? message,
    int? messageId,
  }) {
    return ForumState(
      status: status ?? this.status,
      forum: forum ?? this.forum,
      threads: threads ?? this.threads,
      followedThreadIds: followedThreadIds ?? this.followedThreadIds,
      isAdmin: isAdmin,
      errorMessage: errorMessage ?? this.errorMessage,
      message: message ?? this.message,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        forum,
        threads,
        followedThreadIds,
        isAdmin,
        errorMessage,
        message,
        messageId,
      ];
}

/// Thread list of a series discussion forum.
class ForumCubit extends Cubit<ForumState> {
  ForumCubit({
    required this.forumId,
    required IForumRepository forumRepository,
    required INotificationSettingsService notificationSettings,
    required ISession session,
    required AppEventBus events,
  })  : _forum = forumRepository,
        _notifications = notificationSettings,
        _session = session,
        _events = events,
        super(ForumState(isAdmin: session.currentUser?.isAdmin ?? false)) {
    _eventsSub = events.on<ThreadFollowChanged>().listen((e) {
      final ids = {...state.followedThreadIds};
      e.isFollowing ? ids.add(e.threadId) : ids.remove(e.threadId);
      _safeEmit(state.copyWith(followedThreadIds: ids));
    });
  }

  final String forumId;
  final IForumRepository _forum;
  final INotificationSettingsService _notifications;
  final ISession _session;
  final AppEventBus _events;
  late final StreamSubscription<ThreadFollowChanged> _eventsSub;
  StreamSubscription<Forum>? _forumSub;
  StreamSubscription<List<ForumThread>>? _threadsSub;

  void _safeEmit(ForumState s) {
    if (!isClosed) emit(s);
  }

  void _message(String text) =>
      _safeEmit(state.copyWith(message: text, messageId: nextEffectId()));

  Future<void> load() async {
    _safeEmit(state.copyWith(status: LoadStatus.loading));
    await _forumSub?.cancel();
    await _threadsSub?.cancel();
    _forumSub = _forum.watchForum(forumId).listen(
          (forum) => _safeEmit(state.copyWith(forum: forum)),
          onError: (Object _) {},
        );
    _threadsSub = _forum.watchThreads(forumId, isAdmin: state.isAdmin).listen(
          (threads) => _safeEmit(
            state.copyWith(status: LoadStatus.success, threads: threads),
          ),
          onError: (Object e) => _safeEmit(state.copyWith(
            status: LoadStatus.failure,
            errorMessage: userMessageFor(e),
          )),
        );
    try {
      final settings = await _notifications.getNotificationSettings();
      _safeEmit(state.copyWith(
        followedThreadIds: settings.threadsFollowed.toSet(),
      ));
    } catch (_) {
      // Follow markers are optional.
    }
  }

  /// Creates a thread and follows it automatically.
  Future<void> createThread(String title) async {
    final user = _session.currentUser;
    if (user == null) {
      _message('You must be signed in to create a thread.');
      return;
    }
    try {
      final threadId = await _forum.createThread(NewThread(
        forumId: forumId,
        title: title,
        authorId: user.id,
        authorName: user.fullName,
        authorImageUrl: user.profilePhotoUrl,
      ));
      _safeEmit(state.copyWith(
        followedThreadIds: {...state.followedThreadIds, threadId},
      ));
      await _notifications.followThread(threadId);
      _events.emit(ThreadFollowChanged(threadId: threadId, isFollowing: true));
    } catch (e) {
      _message(userMessageFor(e));
    }
  }

  @override
  Future<void> close() async {
    await _eventsSub.cancel();
    await _forumSub?.cancel();
    await _threadsSub?.cancel();
    return super.close();
  }
}
