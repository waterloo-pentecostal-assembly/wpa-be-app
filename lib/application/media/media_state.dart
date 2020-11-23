part of 'media_bloc.dart';

abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object> get props => [];
}

class AvailableMediaLoading extends MediaState {
  @override
  List<Object> get props => [];
}

class AvailableMediaLoaded extends MediaState {
  final List<Media> media;

  const AvailableMediaLoaded({@required this.media});

  @override
  List<Object> get props => [media];
}

class AvailableMediaError extends MediaState {
  final String message;

  const AvailableMediaError({@required this.message});

  @override
  List<Object> get props => [message];
}
