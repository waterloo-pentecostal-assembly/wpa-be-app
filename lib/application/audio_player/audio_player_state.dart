part of 'audio_player_bloc.dart';

class AudioPlayerState extends Equatable {
  final PlayerStateEnum playerState;
  final Duration duration;
  final Duration position;
  final String sourceUrl;
  final String contentId;

  const AudioPlayerState({
    required this.playerState,
    required this.duration,
    required this.position,
    required this.sourceUrl,
    required this.contentId,
  });

  factory AudioPlayerState.initial() {
    return AudioPlayerState(
      playerState: PlayerStateEnum.STOPPED,
      duration: Duration(),
      position: Duration(),
      sourceUrl: '',
      contentId: '',
    );
  }

  AudioPlayerState copyWith(
    PlayerStateEnum playerState,
    Duration duration,
    Duration position,
    String sourceUrl,
    String contentId,
  ) {
    return AudioPlayerState(
      playerState: playerState,
      duration: duration,
      position: position,
      sourceUrl: sourceUrl,
      contentId: contentId,
    );
  }

  @override
  List<Object> get props => [
        playerState,
        duration,
        position,
        sourceUrl,
        contentId,
      ];
}
