import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/links/interface.dart';

part 'links_event.dart';
part 'links_state.dart';

class LinksBloc extends Bloc<LinksEvent, LinksState> {
  final ILinksRepository _iLinksRepository;
  LinksBloc(this._iLinksRepository) : super(LinksInitial());

  @override
  Stream<LinksState> mapEventToState(
    LinksEvent event,
  ) async* {
    if (event is LinksRequested) {
      try {
        Map<String, dynamic> linksMap = await _iLinksRepository.getlinks();
        yield LinksLoaded(linkMap: linksMap);
      } on BaseApplicationException catch (e) {
        yield LinksError(
          message: e.message,
        );
      } catch (e) {
        yield LinksError(
          message: 'An unknown error occured',
        );
      }
    }
  }
}
