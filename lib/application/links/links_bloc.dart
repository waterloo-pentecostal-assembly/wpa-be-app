import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/links/interface.dart';

part 'links_event.dart';
part 'links_state.dart';

class LinksBloc extends Bloc<LinksEvent, LinksState> {
  final ILinksRepository _iLinksRepository;
  LinksBloc(this._iLinksRepository) : super(LinksInitial()) {
    on<LinksRequested>(_onLinksRequested);
  }

  Future<void> _onLinksRequested(
    LinksRequested event,
    Emitter<LinksState> emit,
  ) async {
    try {
      Map<String, dynamic> linksMap = await _iLinksRepository.getlinks();
      emit(LinksLoaded(linkMap: linksMap));
    } on BaseApplicationException catch (e) {
      emit(LinksError(
        message: e.message,
      ));
    } catch (e) {
      emit(LinksError(
        message: 'An unknown error occured',
      ));
    }
  }
}
