/// Audio playback abstraction (implemented with just_audio in services).
abstract class IAudioPlayer {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  /// Emits when the current source finished playing.
  Stream<void> get completedStream;

  Duration get position;
  Duration? get duration;

  Future<Duration?> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
