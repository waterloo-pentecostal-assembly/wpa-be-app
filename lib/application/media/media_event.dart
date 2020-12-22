part of 'media_bloc.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object> get props => [];
}

class AvailableMediaRequested extends MediaEvent {
  const AvailableMediaRequested();

  @override
  List<Object> get props => [];
}
