import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';

part 'media_event.dart';
part 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final IMediaRepository _iMediaRepository;

  MediaBloc(this._iMediaRepository) : super(AvailableMediaLoading()) {
    on<AvailableMediaRequested>(_onAvailableMediaRequested);
  }

  Future<void> _onAvailableMediaRequested(
    AvailableMediaRequested event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(AvailableMediaLoading());
      List<Media> media = await _iMediaRepository.getAvailableMedia();
      emit(AvailableMediaLoaded(media: media));
    } catch (e) {
      emit(AvailableMediaError(message: 'Unable to load media'));
    }
  }
}
