import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';

part 'media_event.dart';
part 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final IMediaRepository _iMediaRepository;

  MediaBloc(this._iMediaRepository) : super(AvailableMediaLoading());

  @override
  Stream<MediaState> mapEventToState(
    MediaEvent event,
  ) async* {
    if (event is AvailableMediaRequested) {
      yield* _mapAvailableMediaRequestedEventToState(
        event,
        _iMediaRepository.getAvailableMedia,
      );
    }
  }
}

Stream<MediaState> _mapAvailableMediaRequestedEventToState(
  MediaEvent event,
  Future<List<Media>> Function() getAvailableMedia,
) async* {
  try {
    yield AvailableMediaLoading();
    List<Media> media = await getAvailableMedia();
    yield AvailableMediaLoaded(media: media);
  } catch (e) {
    yield AvailableMediaError(message: 'Unable to load media');
  }
}
