import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/app/injection.dart';

part 'audio_player_event.dart';
part 'audio_player_state.dart';

enum PlayerStateEnum {
  PAUSED,
  PLAYING,
  STOPPED,
}

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final player = AudioPlayer();

  AudioPlayerBloc() : super(AudioPlayerState.initial()) {
    on<AudioPlayerEvent>((event, emit) async {
      if (event is InitializePlayer) {
        initAudioPlayer(emit);
        emit(AudioPlayerState.initial());
      } else if (event is Reset) {
        emit(AudioPlayerState.initial());
      } else if (event is Play) {
        await this.player.setSourceUrl(event.sourceUrl);
        Duration duration = await this.player.getDuration();
        Duration position = await this.player.getCurrentPosition();
        await this.player.resume();
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
        await this.player.seek(event.position);
        emit(state.copyWith(
          PlayerStateEnum.PLAYING,
          state.duration,
          event.position,
          state.sourceUrl,
          state.contentId,
        ));
      }
    });
  }

  void initAudioPlayer(Emitter<AudioPlayerState> emit) {
    player.onDurationChanged.listen((Duration duration) {
      getIt<AudioPlayerBloc>().add(DurationChanged(duration: duration));
    });
    player.onPositionChanged.listen((Duration position) {
      getIt<AudioPlayerBloc>().add(PositionChanged(position: position));
    });
    player.onPlayerComplete.listen((event) {
      getIt<AudioPlayerBloc>().add(Complete());
    });
  }
}
