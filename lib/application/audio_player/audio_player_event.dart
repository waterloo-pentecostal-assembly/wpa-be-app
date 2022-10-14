part of 'audio_player_bloc.dart';

abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object> get props => [];
}

class DurationChanged extends AudioPlayerEvent {
  final Duration duration;

  const DurationChanged({
    @required this.duration,
  });

  @override
  List<Object> get props => [duration];
}

class PositionChanged extends AudioPlayerEvent {
  final Duration position;

  const PositionChanged({
    @required this.position,
  });

  @override
  List<Object> get props => [position];
}

class Complete extends AudioPlayerEvent {
  const Complete();

  @override
  List<Object> get props => [];
}

class Play extends AudioPlayerEvent {
  final String sourceUrl;
  final String sourceTitle;

  const Play({
    @required this.sourceUrl,
    @required this.sourceTitle,
  });

  @override
  List<Object> get props => [sourceUrl, sourceTitle];
}

class Pause extends AudioPlayerEvent {
  const Pause();

  @override
  List<Object> get props => [];
}

class Reset extends AudioPlayerEvent {
  const Reset();

  @override
  List<Object> get props => [];
}

class InitializePlayer extends AudioPlayerEvent {
  const InitializePlayer();

  @override
  List<Object> get props => [];
}
