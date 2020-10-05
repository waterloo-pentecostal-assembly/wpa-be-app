import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/value_objects.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';

part 'bible_series_event.dart';
part 'bible_series_state.dart';

class BibleSeriesBloc extends Bloc<BibleSeriesEvent, BibleSeriesState> {
  final IBibleSeriesRepository _iBibleSeriesRepository;

  BibleSeriesBloc(this._iBibleSeriesRepository) : super(BibleSeriesInitial());

  @override
  Stream<BibleSeriesState> mapEventToState(
    BibleSeriesEvent event,
  ) async* {
    if (event is RecentBibleSeriesRequested) {
      yield* _mapGetRecentBibleSeriesEventToState(
        event,
        _iBibleSeriesRepository.getRecentBibleSeries,
      );
    } else if (event is BibleSeriesInformationRequested) {
      yield* _mapBibleSeriesInformationRequestedEventToState(
        event,
        _iBibleSeriesRepository.getBibleSeriesDetails,
      );
    }
  }
}

//TODO: handle errors
Stream<BibleSeriesState> _mapGetRecentBibleSeriesEventToState(
  RecentBibleSeriesRequested event,
  Future Function() getRecentBibleSeriesFunction,
) async* {
  yield FetchingBibleSeries();
  List<BibleSeries> bibleSeriesList = await getRecentBibleSeriesFunction();
  yield RecentBibleSeries(bibleSeriesList);
}

//TODO: handle errors
Stream<BibleSeriesState> _mapBibleSeriesInformationRequestedEventToState(
  BibleSeriesInformationRequested event,
  Future<BibleSeries> Function({@required String bibleSeriesId}) getBibleSeriesFunction,
) async* {
  yield FetchingBibleSeries();
  BibleSeries bibleSeries = await getBibleSeriesFunction(bibleSeriesId: event.bibleSeriesId.toString());
  yield BibleSeriesInformation(bibleSeries);
}
