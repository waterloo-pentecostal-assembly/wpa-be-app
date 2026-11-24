import 'dart:async';

import '../../domain/bible/entities.dart';
import '../../domain/common/community_post.dart';

/// Cross-screen invalidation events. Replaces `.then(refresh)` after pops:
/// a screen that changes data emits an event and interested cubits update.
sealed class AppEvent {
  const AppEvent();
}

/// A completion (or draft) of [contentId] in [seriesId] changed.
class CompletionChanged extends AppEvent {
  const CompletionChanged({required this.seriesId, required this.contentId});
  final String seriesId;
  final String contentId;
}

/// The signed-in user followed/unfollowed a forum thread.
class ThreadFollowChanged extends AppEvent {
  const ThreadFollowChanged(
      {required this.threadId, required this.isFollowing});
  final String threadId;
  final bool isFollowing;
}

class PostCreated<T extends CommunityPost> extends AppEvent {
  const PostCreated(this.post);
  final T post;
}

class PostDeleted<T extends CommunityPost> extends AppEvent {
  const PostDeleted(this.id);
  final String id;
}

/// Answered (prayer request) / archived (testimony).
class PostClosed<T extends CommunityPost> extends AppEvent {
  const PostClosed(this.post);
  final T post;
}

class PostReported<T extends CommunityPost> extends AppEvent {
  const PostReported(this.id);
  final String id;
}

/// The signed-in user prayed for / said amen to a post.
class PostReacted<T extends CommunityPost> extends AppEvent {
  const PostReacted(this.id);
  final String id;
}

/// A saved verse was created or changed (e.g. its note).
class SavedVerseChanged extends AppEvent {
  const SavedVerseChanged(this.savedVerse);
  final SavedVerse savedVerse;
}

/// The user chose the Bible version they read in (`null`: each series' own
/// version), from the reader or from their saved verses. Open scripture
/// switches to it.
class PreferredBibleChanged extends AppEvent {
  const PreferredBibleChanged(this.bibleId);
  final String? bibleId;
}

/// A saved verse (and its note) was removed.
class SavedVerseDeleted extends AppEvent {
  const SavedVerseDeleted(this.id);
  final String id;
}

/// App-scoped broadcast bus for [AppEvent]s.
class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast(sync: true);

  Stream<AppEvent> get stream => _controller.stream;

  Stream<E> on<E extends AppEvent>() => stream.where((e) => e is E).cast<E>();

  void emit(AppEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
