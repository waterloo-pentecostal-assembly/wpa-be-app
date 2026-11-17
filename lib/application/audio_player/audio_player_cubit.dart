import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'audio_player_port.dart';

enum PlayerStatus { paused, playing, stopped }

class AudioPlayerState extends Equatable {
  const AudioPlayerState({
    this.playerStatus = PlayerStatus.stopped,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.sourceUrl = '',
    this.contentId = '',
  });

  final PlayerStatus playerStatus;
  final Duration duration;
  final Duration position;
  final String sourceUrl;

  /// Content currently loaded (used for the "playing" indicator).
  final String contentId;

  bool isPlayingContent(String id) =>
      contentId == id && playerStatus == PlayerStatus.playing;

  AudioPlayerState copyWith({
    PlayerStatus? playerStatus,
    Duration? duration,
    Duration? position,
    String? sourceUrl,
    String? contentId,
  }) {
    return AudioPlayerState(
      playerStatus: playerStatus ?? this.playerStatus,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      contentId: contentId ?? this.contentId,
    );
  }

  @override
  List<Object?> get props =>
      [playerStatus, duration, position, sourceUrl, contentId];
}

/// App-scoped audio player shared by all audio bodies.
class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  AudioPlayerCubit(this._player) : super(const AudioPlayerState()) {
    _subs = [
      _player.positionStream.listen((p) {
        if (!isClosed) emit(state.copyWith(position: p));
      }),
      _player.durationStream.listen((d) {
        if (d != null && !isClosed) emit(state.copyWith(duration: d));
      }),
      _player.completedStream.listen((_) async {
        await _player.stop();
        if (!isClosed) {
          emit(state.copyWith(
            playerStatus: PlayerStatus.stopped,
            position: Duration.zero,
          ));
        }
      }),
    ];
  }

  final IAudioPlayer _player;
  late final List<StreamSubscription<dynamic>> _subs;

  Future<void> play(
      {required String sourceUrl, required String contentId}) async {
    Duration position;
    // TODO(audio): key by content id; the same URL may appear twice.
    if (state.sourceUrl != sourceUrl) {
      await _player.setUrl(sourceUrl);
      position = _player.position;
    } else {
      position = state.position;
      if (state.playerStatus == PlayerStatus.stopped) {
        await _player.setUrl(sourceUrl);
      }
    }
    final duration = _player.duration ?? state.duration;
    await _player.play();
    emit(state.copyWith(
      playerStatus: PlayerStatus.playing,
      duration: duration,
      position: position,
      sourceUrl: sourceUrl,
      contentId: contentId,
    ));
  }

  Future<void> pause() async {
    await _player.pause();
    emit(state.copyWith(playerStatus: PlayerStatus.paused));
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    emit(state.copyWith(
      position: position,
      playerStatus: state.playerStatus == PlayerStatus.stopped
          ? PlayerStatus.paused
          : state.playerStatus,
    ));
  }

  /// Toggles play/pause for [sourceUrl].
  Future<void> toggle({required String sourceUrl, required String contentId}) {
    if (state.sourceUrl == sourceUrl &&
        state.playerStatus == PlayerStatus.playing) {
      return pause();
    }
    return play(sourceUrl: sourceUrl, contentId: contentId);
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _player.dispose();
    return super.close();
  }
}
