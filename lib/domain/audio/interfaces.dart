import 'entities.dart';

/// Audio playback. One instance lives for the whole process so playback
/// continues in the background and is controllable from the lock screen /
/// notification; the app UI reflects it through [playbackStream] and
/// [positionStream].
abstract class IAudioPlayer {
  /// Current snapshot (also the first value to show before any event).
  AudioPlayback get playback;
  Stream<AudioPlayback> get playbackStream;

  Duration get position;
  Stream<Duration> get positionStream;

  /// Loads [track] (no-op if it is already loaded). The track becomes the
  /// current one immediately; if its source cannot be loaded,
  /// [AudioPlayback.errorMessage] is set and `AudioPlaybackException` is
  /// thrown.
  Future<void> load(AudioTrack track);

  /// Starts or resumes playback; returns without waiting for it to end.
  Future<void> play();
  Future<void> pause();

  /// Seeks within the track (clamped to its duration).
  Future<void> seek(Duration position);

  /// Jumps back `kAudioRewindInterval`.
  Future<void> skipBackward();

  /// Jumps forward `kAudioFastForwardInterval`.
  Future<void> skipForward();
  Future<void> setSpeed(double speed);

  /// Stops playback and unloads the track (removes the notification).
  Future<void> stop();
}
