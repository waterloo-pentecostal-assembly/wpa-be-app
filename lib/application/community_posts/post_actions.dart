import 'dart:async';

import '../../domain/common/analytics.dart';
import '../../domain/common/community_post.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/paging.dart';
import '../common/app_events.dart';

/// Repository operations needed by the community post screens. Built by the
/// composition root from IPrayerRequestsRepository / ITestimoniesRepository.
class PostRepositoryAdapter<T extends CommunityPost> {
  const PostRepositoryAdapter({
    required this.fetchPage,
    required this.fetchMine,
    required this.fetchMineClosed,
    required this.create,
    required this.delete,
    required this.close,
    required this.report,
    required this.react,
  });

  final Future<PageResult<T>> Function({required int limit, PageCursor? after})
      fetchPage;
  final Future<List<T>> Function() fetchMine;
  final Future<List<T>> Function() fetchMineClosed;
  final Future<T> Function({required String request, required bool isAnonymous})
      create;
  final Future<void> Function({required String id}) delete;
  final Future<T> Function({required String id}) close;
  final Future<void> Function({required String id}) report;
  final Future<void> Function({required String id}) react;
}

/// Analytics event names and user-facing error copy for one post kind.
class PostActionCopy {
  const PostActionCopy({
    required this.createdEvent,
    required this.deletedEvent,
    required this.reportedEvent,
    required this.reactedEvent,
    required this.closedEvent,
    required this.createError,
    required this.deleteError,
    required this.reportError,
    required this.closeError,
    required this.reactError,
  });

  final String createdEvent;
  final String deletedEvent;
  final String reportedEvent;
  final String reactedEvent;
  final String closedEvent;
  final String createError;
  final String deleteError;
  final String reportError;
  final String closeError;
  final String reactError;
}

/// Error raised by [PostActions] with a message safe to show.
class PostActionException implements Exception {
  const PostActionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Shared item actions (react, report, delete, close, create) used by every
/// prayer request / testimony screen. Each successful action logs analytics
/// and broadcasts an [AppEvent] so other screens update.
class PostActions<T extends CommunityPost> {
  PostActions({
    required this.repository,
    required this.copy,
    required IAnalytics analytics,
    required AppEventBus events,
  })  : _analytics = analytics,
        _events = events;

  final PostRepositoryAdapter<T> repository;
  final PostActionCopy copy;
  final IAnalytics _analytics;
  final AppEventBus _events;

  Future<T> create({required String body, required bool isAnonymous}) async {
    try {
      final post =
          await repository.create(request: body, isAnonymous: isAnonymous);
      unawaited(_analytics.log(copy.createdEvent));
      _events.emit(PostCreated<T>(post));
      return post;
    } catch (_) {
      throw PostActionException(copy.createError);
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.delete(id: id);
      unawaited(_analytics.log(copy.deletedEvent));
      _events.emit(PostDeleted<T>(id));
    } catch (_) {
      throw PostActionException(copy.deleteError);
    }
  }

  Future<void> report(String id) async {
    try {
      await repository.report(id: id);
      unawaited(_analytics.log(copy.reportedEvent));
      _events.emit(PostReported<T>(id));
    } catch (e) {
      throw PostActionException(
        e is BaseApplicationException && e.code.name == 'alreadyReported'
            ? e.message
            : copy.reportError,
      );
    }
  }

  Future<T> close(String id) async {
    try {
      final post = await repository.close(id: id);
      unawaited(_analytics.log(copy.closedEvent));
      _events.emit(PostClosed<T>(post));
      return post;
    } catch (_) {
      throw PostActionException(copy.closeError);
    }
  }

  Future<void> react(String id) async {
    try {
      await repository.react(id: id);
      unawaited(_analytics.log(copy.reactedEvent));
      _events.emit(PostReacted<T>(id));
    } catch (_) {
      throw PostActionException(copy.reactError);
    }
  }
}
