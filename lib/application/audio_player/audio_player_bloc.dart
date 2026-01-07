import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';

part 'audio_player_event.dart';
part 'audio_player_state.dart';

enum PlayerStateEnum {
  PAUSED,
  PLAYING,
  STOPPED,
}

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final player = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ProcessingState>? _playerStateSubscription;

  AudioPlayerBloc() : super(AudioPlayerState.initial()) {
    on<AudioPlayerEvent>((event, emit) async {
      if (event is InitializePlayer) {
        initAudioPlayer(emit);
        emit(AudioPlayerState.initial());
      } else if (event is Reset) {
        emit(AudioPlayerState.initial());
      } else if (event is Play) {
        Duration position;
        //TODO: update this to use an ID since we can technically
        // have the same source URL appearing twice
        if (state.sourceUrl != event.sourceUrl) {
          await this.player.setUrl(event.sourceUrl);
          position = this.player.position;
        } else {
          position = state.position;
          if (state.playerState == PlayerStateEnum.STOPPED) {
            await this.player.setUrl(event.sourceUrl);
          }
        }
        Duration duration = this.player.duration!;
        this.player.play();
        emit(state.copyWith(
          PlayerStateEnum.PLAYING,
          duration,
          position,
          event.sourceUrl,
          event.contentId,
        ));
      } else if (event is Pause) {
        await this.player.pause();
        emit(state.copyWith(
          PlayerStateEnum.PAUSED,
          state.duration,
          state.position,
          state.sourceUrl,
          state.contentId,
        ));
      } else if (event is DurationChanged) {
        emit(state.copyWith(
          state.playerState,
          event.duration,
          state.position,
          state.sourceUrl,
          state.contentId,
        ));
      } else if (event is PositionChanged) {
        emit(state.copyWith(
          state.playerState,
          state.duration,
          event.position,
          state.sourceUrl,
          state.contentId,
        ));
      } else if (event is Complete) {
        emit(state.copyWith(
          PlayerStateEnum.STOPPED,
          state.duration,
          Duration(),
          state.sourceUrl,
          state.contentId,
        ));
      } else if (event is Seek) {
        PlayerStateEnum newState = state.playerState;
        await this.player.seek(event.position);
        if (state.playerState == PlayerStateEnum.STOPPED) {
          newState = PlayerStateEnum.PAUSED;
        }
        emit(state.copyWith(
          newState,
          state.duration,
          event.position,
          state.sourceUrl,
          state.contentId,
        ));
      }
    });
  }

  void initAudioPlayer(Emitter<AudioPlayerState> emit) {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _positionSubscription =
        this.player.positionStream.listen((Duration position) {
      if (!isClosed) {
        add(PositionChanged(position: position));
      }
    });
    _durationSubscription =
        this.player.durationStream.listen((Duration? duration) {
      if (duration != null && !isClosed) {
        add(DurationChanged(duration: duration));
      }
    });

    _playerStateSubscription =
        this.player.processingStateStream.listen((ProcessingState state) async {
      if (state == ProcessingState.completed) {
        await this.player.stop();
        if (!isClosed) {
          add(Complete());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    player.dispose();
    return super.close();
  }
}
