import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/audio/entities.dart';
import '../../domain/audio/interfaces.dart';
import '../../domain/audio/rules.dart';
import '../../domain/common/exceptions.dart';

class AudioPlayerState extends Equatable {
  const AudioPlayerState({
    this.playback = const AudioPlayback(),
    this.position = Duration.zero,
    this.actionError,
  });

  final AudioPlayback playback;
  final Duration position;

  /// Message of the last failed action (cleared by the next action).
  final String? actionError;

  AudioTrack? get track => playback.track;
  bool get hasTrack => track != null;
  Duration get duration => playback.duration ?? Duration.zero;
  Duration get bufferedPosition => playback.bufferedPosition;
  double get speed => playback.speed;

  /// Message to show for the current track, if it failed.
  String? get error => playback.errorMessage ?? actionError;

  /// Playing (or about to, once buffered).
  bool get isPlaying =>
      playback.playing &&
      playback.processing != AudioProcessing.completed &&
      playback.processing != AudioProcessing.idle;

  /// Loading the source, or buffering while playback is requested.
  bool get isLoading =>
      playback.processing == AudioProcessing.loading ||
      (playback.processing == AudioProcessing.buffering && playback.playing);

  bool isCurrent(String trackId) => track?.id == trackId;

  /// Whether a track started from content [contentId] is playing.
  bool isPlayingContent(String contentId) =>
      isPlaying && track?.origin?.contentId == contentId;

  AudioPlayerState copyWith({
    AudioPlayback? playback,
    Duration? position,
    String? Function()? actionError,
  }) {
    return AudioPlayerState(
      playback: playback ?? this.playback,
      position: position ?? this.position,
      actionError: actionError != null ? actionError() : this.actionError,
    );
  }

  @override
  List<Object?> get props => [playback, position, actionError];
}

/// App-scoped state holder of the audio player (inline players, mini
/// player, "playing" indicators). The [IAudioPlayer] outlives the UI: it
/// keeps playing in the background, and closing this cubit does not stop it.
class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  AudioPlayerCubit(this._player)
      : super(AudioPlayerState(
          playback: _player.playback,
          position: _player.position,
        )) {
    _subscriptions = [
      _player.playbackStream.listen((playback) {
        final trackChanged = playback.track?.id != state.track?.id;
        _safeEmit(state.copyWith(
          playback: playback,
          position: trackChanged ? Duration.zero : null,
        ));
      }),
      _player.positionStream
          .listen((position) => _safeEmit(state.copyWith(position: position))),
    ];
  }

  final IAudioPlayer _player;
  late final List<StreamSubscription<Object?>> _subscriptions;

  /// Plays [track], loading it first unless it is the current one.
  Future<void> play(AudioTrack track) => _run(() async {
        final reload = !state.isCurrent(track.id) ||
            state.playback.processing == AudioProcessing.idle ||
            state.error != null;
        if (reload) {
          await _player.load(track);
          // A newer request replaced this track while it was loading.
          if (_player.playback.track?.id != track.id) return;
        }
        await _player.play();
      });

  /// Play/pause button of [track].
  Future<void> toggle(AudioTrack track) =>
      state.isCurrent(track.id) && state.isPlaying ? pause() : play(track);

  /// Resumes the current track.
  Future<void> resume() => _run(_player.play);

  Future<void> pause() => _run(_player.pause);

  Future<void> seek(Duration position) =>
      _run(() => _player.seek(clampToTrack(position, state.playback.duration)));

  Future<void> skipBackward() => _run(_player.skipBackward);

  Future<void> skipForward() => _run(_player.skipForward);

  /// Speed button: cycles through `kAudioPlaybackSpeeds`.
  Future<void> cycleSpeed() =>
      _run(() => _player.setSpeed(nextPlaybackSpeed(state.speed)));

  /// Stops and unloads the current track (mini player close button).
  Future<void> stop() => _run(_player.stop);

  Future<void> _run(Future<void> Function() action) async {
    if (state.actionError != null) {
      _safeEmit(state.copyWith(actionError: () => null));
    }
    try {
      await action();
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(
        actionError: () => userMessageFor(e, stackTrace: stackTrace),
      ));
    }
  }

  void _safeEmit(AudioPlayerState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
