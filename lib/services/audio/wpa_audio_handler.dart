import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/audio/entities.dart';
import '../../domain/audio/exceptions.dart';
import '../../domain/audio/interfaces.dart';
import '../../domain/audio/rules.dart';
import '../../domain/common/exceptions.dart';

/// The app's audio player.
///
/// Wraps a just_audio [AudioPlayer] and publishes its state twice:
/// - to the OS through audio_service ([playbackState] / [mediaItem]), which
///   drives background playback, the lock screen, the media notification,
///   headset buttons and Bluetooth controls; the OS calls back into
///   [play], [pause], [seek], [rewind], [fastForward] and [stop];
/// - to the app through [IAudioPlayer] ([playbackStream] / [positionStream]).
class WpaAudioHandler extends BaseAudioHandler implements IAudioPlayer {
  WpaAudioHandler({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _subscriptions = [
      _player.playbackEventStream
          .listen((_) => _publish(), onError: _onPlaybackError),
      _player.playingStream.listen((_) => _publish()),
      _player.speedStream.listen((_) => _publish()),
      _player.durationStream.listen(_onDuration),
      _player.processingStateStream.listen(_onProcessingState),
    ];
  }

  final AudioPlayer _player;
  late final List<StreamSubscription<Object?>> _subscriptions;
  final _playbackController = StreamController<AudioPlayback>.broadcast();

  AudioTrack? _track;
  String? _errorMessage;
  AudioPlayback _playback = const AudioPlayback();

  /// Set while a source is loading, so the previous source's state (e.g.
  /// its duration) is never shown with the new track. A token, because a
  /// newer load may interrupt an older one.
  int _loads = 0;
  int? _loadingToken;
  bool get _isLoading => _loadingToken != null;

  // --- IAudioPlayer ---------------------------------------------------------

  @override
  AudioPlayback get playback => _playback;

  @override
  Stream<AudioPlayback> get playbackStream => _playbackController.stream;

  @override
  Duration get position => _player.position;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> load(AudioTrack track) async {
    final alreadyLoaded = _track?.id == track.id &&
        _errorMessage == null &&
        _player.processingState != ProcessingState.idle;
    if (alreadyLoaded) return;

    final token = ++_loads;
    _loadingToken = token;
    _track = track;
    _errorMessage = null;
    mediaItem.add(_mediaItemFor(track));
    _publish();
    try {
      final duration = await _player.setAudioSource(
        AudioSource.uri(Uri.parse(track.url)),
      );
      if (_loadingToken == token && duration != null) {
        mediaItem.add(_mediaItemFor(track, duration));
      }
    } on PlayerInterruptedException {
      // Another track was loaded (or playback stopped) meanwhile.
    } catch (e) {
      if (_loadingToken != token) return;
      _errorMessage = kAudioPlaybackErrorMessage;
      throw AudioPlaybackException(
        code: AudioPlaybackExceptionCode.unableToLoad,
        details: e,
      );
    } finally {
      if (_loadingToken == token) {
        _loadingToken = null;
        _publish();
      }
    }
  }

  @override
  Future<void> play() async {
    if (_track == null) return;
    // just_audio's play() only completes when playback pauses or stops, so
    // it is not awaited; its failures are handled like playback errors.
    unawaited(_player.play().catchError(_onPlaybackError));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) =>
      _player.seek(clampToTrack(position, _player.duration));

  @override
  Future<void> skipBackward() => seek(_player.position - kAudioRewindInterval);

  @override
  Future<void> skipForward() =>
      seek(_player.position + kAudioFastForwardInterval);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    _loadingToken = null;
    await _player.stop();
    _track = null;
    _errorMessage = null;
    mediaItem.add(null);
    // An idle state makes audio_service stop the foreground service and
    // remove the notification.
    _publish();
  }

  // --- Commands from the OS (lock screen, notification, headset) -----------

  @override
  Future<void> rewind() => skipBackward();

  @override
  Future<void> fastForward() => skipForward();

  /// The app was swiped away (Android): keep playing in the background, but
  /// do not keep a paused session around.
  @override
  Future<void> onTaskRemoved() async {
    if (!_player.playing) await stop();
  }

  /// Releases the player (tests; the app keeps one handler for its lifetime).
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _playbackController.close();
    await _player.dispose();
  }

  // --- Internals ------------------------------------------------------------

  void _onDuration(Duration? duration) {
    final track = _track;
    if (track != null && duration != null) {
      mediaItem.add(_mediaItemFor(track, duration));
    }
    _publish();
  }

  void _onProcessingState(ProcessingState state) {
    if (state == ProcessingState.completed) {
      // Rewind so the track can be replayed; the notification keeps a play
      // button and the session ends normally when dismissed.
      unawaited(_rewindAfterCompletion());
    }
    _publish();
  }

  Future<void> _rewindAfterCompletion() async {
    try {
      await _player.pause();
      await _player.seek(Duration.zero);
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
    }
  }

  void _onPlaybackError(Object error, [StackTrace? stackTrace]) {
    if (error is PlayerInterruptedException) return;
    reportError(
      AudioPlaybackException(
        code: AudioPlaybackExceptionCode.playbackFailed,
        details: error,
      ),
      stackTrace,
    );
    if (_track == null) return;
    _errorMessage = kAudioPlaybackErrorMessage;
    _publish();
  }

  MediaItem _mediaItemFor(AudioTrack track, [Duration? duration]) => MediaItem(
        id: track.id,
        title: track.title,
        // iOS shows the artist line, Android notifications the album/artist.
        artist: track.subtitle,
        album: track.subtitle,
        duration: duration,
        artUri:
            track.artworkUrl == null ? null : Uri.tryParse(track.artworkUrl!),
        extras: {'url': track.url},
      );

  void _publish() {
    final playing = _player.playing;
    final processing =
        _isLoading ? ProcessingState.loading : _player.processingState;
    final position = _isLoading ? Duration.zero : _player.position;
    final buffered = _isLoading ? Duration.zero : _player.bufferedPosition;
    final duration = _isLoading ? null : _player.duration;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _errorMessage != null
          ? AudioProcessingState.error
          : _track == null
              ? AudioProcessingState.idle
              : _systemProcessing[processing]!,
      playing: playing,
      updatePosition: position,
      bufferedPosition: buffered,
      speed: _player.speed,
      errorMessage: _errorMessage,
      queueIndex: _track == null ? null : 0,
    ));

    final next = AudioPlayback(
      track: _track,
      processing:
          _track == null ? AudioProcessing.idle : _appProcessing[processing]!,
      playing: playing,
      duration: duration,
      bufferedPosition: buffered,
      speed: _player.speed,
      errorMessage: _errorMessage,
    );
    if (next != _playback && !_playbackController.isClosed) {
      _playback = next;
      _playbackController.add(next);
    }
  }

  static const _systemProcessing = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  static const _appProcessing = {
    ProcessingState.idle: AudioProcessing.idle,
    ProcessingState.loading: AudioProcessing.loading,
    ProcessingState.buffering: AudioProcessing.buffering,
    ProcessingState.ready: AudioProcessing.ready,
    ProcessingState.completed: AudioProcessing.completed,
  };
}
