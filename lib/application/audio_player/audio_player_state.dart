part of 'audio_player_bloc.dart';

class AudioPlayerState extends Equatable {
  final PlayerStateEnum playerState;
  final Duration duration;
  final Duration position;
  final String sourceUrl;
  final String sourceTitle;

  const AudioPlayerState({
    @required this.playerState,
    @required this.duration,
    @required this.position,
    this.sourceUrl,
    this.sourceTitle,
  });

  factory AudioPlayerState.initial() {
    return AudioPlayerState(
      playerState: PlayerStateEnum.STOPPED,
      duration: Duration(),
      position: Duration(),
    );
  }

  AudioPlayerState copyWith(
    PlayerStateEnum playerState,
    Duration duration,
    Duration position,
    String sourceUrl,
    String sourceTitle,
  ) {
    return AudioPlayerState(
      playerState: playerState,
      duration: duration,
      position: position,
      sourceTitle: sourceTitle,
      sourceUrl: sourceUrl,
    );
  }

  @override
  List<Object> get props => [playerState, duration, position, sourceTitle, sourceUrl];
}
