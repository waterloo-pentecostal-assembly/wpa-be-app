import 'package:just_audio/just_audio.dart';

import '../application/audio_player/audio_player_port.dart';

class JustAudioPlayer implements IAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<void> get completedStream => _player.processingStateStream
      .where((s) => s == ProcessingState.completed)
      .map((_) {});

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  Future<Duration?> setUrl(String url) => _player.setUrl(url);

  @override
  Future<void> play() async {
    // just_audio's play() completes when playback ends; don't wait for it.
    _player.play().ignore();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() => _player.dispose();
}
