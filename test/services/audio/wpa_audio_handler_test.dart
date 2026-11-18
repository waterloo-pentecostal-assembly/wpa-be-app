import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wpa_app/domain/audio/entities.dart';
import 'package:wpa_app/domain/audio/exceptions.dart';
import 'package:wpa_app/domain/audio/rules.dart';
import 'package:wpa_app/services/audio/wpa_audio_handler.dart';

/// Minimal stand-in for just_audio's [AudioPlayer] (no platform channels).
class FakeJustAudio extends Fake implements AudioPlayer {
  final _events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final _playingCtrl = StreamController<bool>.broadcast(sync: true);
  final _speedCtrl = StreamController<double>.broadcast(sync: true);
  final _durationCtrl = StreamController<Duration?>.broadcast(sync: true);
  final _processingCtrl =
      StreamController<ProcessingState>.broadcast(sync: true);
  final _positionCtrl = StreamController<Duration>.broadcast(sync: true);

  @override
  bool playing = false;
  @override
  ProcessingState processingState = ProcessingState.idle;
  @override
  Duration position = Duration.zero;
  @override
  Duration bufferedPosition = Duration.zero;
  @override
  Duration? duration;
  @override
  double speed = 1.0;

  /// Duration reported by the next load; set [loadError] to fail it.
  Duration sourceDuration = const Duration(minutes: 10);
  Object? loadError;

  /// When set, loads wait for it (to observe the loading state).
  Completer<void>? loadGate;
  final List<String> loadedUris = [];
  final List<Duration?> seeks = [];
  bool disposed = false;

  @override
  Stream<PlaybackEvent> get playbackEventStream => _events.stream;
  @override
  Stream<bool> get playingStream => _playingCtrl.stream;
  @override
  Stream<double> get speedStream => _speedCtrl.stream;
  @override
  Stream<Duration?> get durationStream => _durationCtrl.stream;
  @override
  Stream<ProcessingState> get processingStateStream => _processingCtrl.stream;
  @override
  Stream<Duration> get positionStream => _positionCtrl.stream;

  void _setProcessing(ProcessingState state) {
    processingState = state;
    _processingCtrl.add(state);
    _events.add(PlaybackEvent(processingState: state));
  }

  /// Simulates the end of the track.
  void complete() => _setProcessing(ProcessingState.completed);

  /// Simulates a playback error reported on the event stream.
  void failPlayback(Object error) => _events.addError(error);

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    loadedUris.add((audioSource as UriAudioSource).uri.toString());
    _setProcessing(ProcessingState.loading);
    await loadGate?.future;
    final error = loadError;
    if (error != null) {
      _setProcessing(ProcessingState.idle);
      throw error;
    }
    duration = sourceDuration;
    _durationCtrl.add(duration);
    position = Duration.zero;
    _setProcessing(ProcessingState.ready);
    return duration;
  }

  @override
  Future<void> play() async {
    playing = true;
    _playingCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    playing = false;
    _playingCtrl.add(false);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seeks.add(position);
    this.position = position ?? Duration.zero;
    _events.add(PlaybackEvent(processingState: processingState));
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed = speed;
    _speedCtrl.add(speed);
  }

  @override
  Future<void> stop() async {
    playing = false;
    _playingCtrl.add(false);
    _setProcessing(ProcessingState.idle);
  }

  @override
  Future<void> dispose() async => disposed = true;
}

const track = AudioTrack(
  id: 'content-1/2',
  url: 'https://example.com/sermon.mp3',
  title: 'Sunday sermon',
  subtitle: 'Day 1 · Gospel of John',
  artworkUrl: 'https://example.com/art.jpg',
  origin: AudioTrackOrigin(seriesId: 's1', contentId: 'content-1'),
);

void main() {
  late FakeJustAudio player;
  late WpaAudioHandler handler;

  setUp(() {
    player = FakeJustAudio();
    handler = WpaAudioHandler(player: player);
  });

  tearDown(() => handler.dispose());

  group('load', () {
    test('publishes the track and its lock-screen metadata', () async {
      await handler.load(track);

      expect(player.loadedUris, [track.url]);
      final item = handler.mediaItem.value!;
      expect(item.id, track.id);
      expect(item.title, 'Sunday sermon');
      expect(item.artist, 'Day 1 · Gospel of John');
      expect(item.album, 'Day 1 · Gospel of John');
      expect(item.artUri, Uri.parse('https://example.com/art.jpg'));
      expect(item.duration, const Duration(minutes: 10));

      expect(handler.playback.track, track);
      expect(handler.playback.processing, AudioProcessing.ready);
      expect(handler.playback.duration, const Duration(minutes: 10));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.ready);
    });

    test('while a new track loads, the old track state is not shown', () async {
      await handler.load(track);
      await handler.play();
      player.sourceDuration = const Duration(minutes: 2);
      player.loadGate = Completer<void>();
      const next = AudioTrack(
          id: 'next', url: 'https://example.com/n.mp3', title: 'Next');

      final loading = handler.load(next);
      expect(handler.playback.track, next);
      expect(handler.playback.processing, AudioProcessing.loading);
      expect(handler.playback.duration, isNull);
      expect(handler.mediaItem.value!.title, 'Next');

      player.loadGate!.complete();
      await loading;
      expect(handler.playback.processing, AudioProcessing.ready);
      expect(handler.playback.duration, const Duration(minutes: 2));
    });

    test('loading the current track again does nothing', () async {
      await handler.load(track);
      await handler.load(track);
      expect(player.loadedUris, hasLength(1));
    });

    test('a failure throws AudioPlaybackException and shows an error',
        () async {
      player.loadError = PlayerException(0, 'Source error', null);

      await expectLater(
        handler.load(track),
        throwsA(isA<AudioPlaybackException>().having(
            (e) => e.code, 'code', AudioPlaybackExceptionCode.unableToLoad)),
      );
      expect(handler.playback.errorMessage, kAudioPlaybackErrorMessage);
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.error);

      // Retrying reloads the same track.
      player.loadError = null;
      await handler.load(track);
      expect(player.loadedUris, hasLength(2));
      expect(handler.playback.errorMessage, isNull);
    });

    test('an interrupted load (newer track loading) is not an error', () async {
      player.loadError = PlayerInterruptedException('Loading interrupted');
      await handler.load(track);
      expect(handler.playback.errorMessage, isNull);
    });
  });

  group('transport', () {
    setUp(() => handler.load(track));

    test('play / pause update the app and the system controls', () async {
      await handler.play();
      expect(handler.playback.playing, isTrue);
      var system = handler.playbackState.value;
      expect(system.playing, isTrue);
      expect(system.controls, [
        MediaControl.rewind,
        MediaControl.pause,
        MediaControl.fastForward,
        MediaControl.stop,
      ]);
      expect(system.androidCompactActionIndices, [0, 1, 2]);
      expect(system.systemActions, contains(MediaAction.seek));

      await handler.pause();
      expect(handler.playback.playing, isFalse);
      system = handler.playbackState.value;
      expect(system.controls[1], MediaControl.play);
    });

    test('seek is clamped to the track', () async {
      await handler.seek(const Duration(minutes: 20));
      await handler.seek(const Duration(seconds: -5));
      expect(player.seeks, [const Duration(minutes: 10), Duration.zero]);
    });

    test('skip buttons (app and lock screen) jump by the intervals', () async {
      player.position = const Duration(minutes: 5);
      await handler.skipForward();
      expect(player.position,
          const Duration(minutes: 5) + kAudioFastForwardInterval);

      await handler.skipBackward();
      expect(
        player.position,
        const Duration(minutes: 5) +
            kAudioFastForwardInterval -
            kAudioRewindInterval,
      );

      player.position = const Duration(seconds: 3);
      await handler.rewind(); // lock screen "back"
      expect(player.position, Duration.zero);

      player.position = const Duration(minutes: 9, seconds: 50);
      await handler.fastForward(); // lock screen "forward"
      expect(player.position, const Duration(minutes: 10));
    });

    test('setSpeed is published', () async {
      await handler.setSpeed(1.5);
      expect(handler.playback.speed, 1.5);
      expect(handler.playbackState.value.speed, 1.5);
    });

    test('at the end the track rewinds and pauses, ready to replay', () async {
      await handler.play();
      player.complete();
      await pumpEventQueue();

      expect(player.playing, isFalse);
      expect(player.seeks.last, Duration.zero);
      expect(handler.playback.track, track);
    });

    test('a playback error is shown on the track', () async {
      player.failPlayback(PlayerException(0, 'Network', null));
      await pumpEventQueue();
      expect(handler.playback.errorMessage, kAudioPlaybackErrorMessage);
    });

    test('stop unloads the track and ends the session', () async {
      await handler.play();
      await handler.stop();

      expect(handler.playback.track, isNull);
      expect(handler.playback.processing, AudioProcessing.idle);
      expect(handler.mediaItem.value, isNull);
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.idle);
    });
  });

  group('app swiped away (Android)', () {
    setUp(() => handler.load(track));

    test('keeps playing in the background', () async {
      await handler.play();
      await handler.onTaskRemoved();
      expect(handler.playback.track, track);
      expect(player.playing, isTrue);
    });

    test('ends a paused session', () async {
      await handler.onTaskRemoved();
      expect(handler.playback.track, isNull);
    });
  });

  test('play without a track does nothing', () async {
    await handler.play();
    expect(player.playing, isFalse);
  });

  test('the app receives position updates', () async {
    final positions = <Duration>[];
    final sub = handler.positionStream.listen(positions.add);
    player._positionCtrl.add(const Duration(seconds: 1));
    expect(positions, [const Duration(seconds: 1)]);
    await sub.cancel();
  });
}
