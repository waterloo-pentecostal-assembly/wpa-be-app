import 'package:equatable/equatable.dart';

/// Where a track was started from, so the app can navigate back to it
/// (e.g. from the mini player).
class AudioTrackOrigin extends Equatable {
  const AudioTrackOrigin({
    required this.seriesId,
    required this.contentId,
    this.contentType,
  });

  final String seriesId;
  final String contentId;
  final String? contentType;

  @override
  List<Object?> get props => [seriesId, contentId, contentType];
}

/// A playable item and the metadata shown in the app, on the lock screen and
/// in the media notification.
class AudioTrack extends Equatable {
  const AudioTrack({
    required this.id,
    required this.url,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    this.origin,
  });

  /// Unique key (the same URL may appear in several contents).
  final String id;
  final String url;
  final String title;

  /// Secondary line, e.g. "Day 1 · Gospel of John".
  final String? subtitle;
  final String? artworkUrl;
  final AudioTrackOrigin? origin;

  @override
  List<Object?> get props => [id, url, title, subtitle, artworkUrl, origin];
}

enum AudioProcessing {
  /// Nothing loaded (or stopped).
  idle,

  /// Loading the source.
  loading,

  /// Waiting for data while playing or after a seek.
  buffering,

  /// Ready to play (playing or paused).
  ready,

  /// Reached the end.
  completed,
}

/// Snapshot of the player, except the position (which changes continuously
/// and has its own stream).
class AudioPlayback extends Equatable {
  const AudioPlayback({
    this.track,
    this.processing = AudioProcessing.idle,
    this.playing = false,
    this.duration,
    this.bufferedPosition = Duration.zero,
    this.speed = 1.0,
    this.errorMessage,
  });

  /// The loaded track; `null` when idle.
  final AudioTrack? track;
  final AudioProcessing processing;

  /// Whether playback is requested (it may still be loading/buffering).
  final bool playing;

  /// Known once the source has loaded.
  final Duration? duration;
  final Duration bufferedPosition;
  final double speed;

  /// User-safe message when the track could not be loaded or played.
  final String? errorMessage;

  @override
  List<Object?> get props => [
        track,
        processing,
        playing,
        duration,
        bufferedPosition,
        speed,
        errorMessage,
      ];
}
