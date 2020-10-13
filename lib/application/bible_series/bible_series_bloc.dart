import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/value_objects.dart';
import 'helpers.dart';

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
    } else if (event is BibleSeriesDetailRequested) {
      yield* _mapBibleSeriesDetailRequestedEventToState(
        event,
        _iBibleSeriesRepository.getBibleSeriesDetails,
        _iBibleSeriesRepository.getAllContentCompletionDetails,
      );
    } else if (event is ContentDetailRequested) {
      yield* _mapContentDetailRequestedEventToState(
        event,
        _iBibleSeriesRepository.getContentDetails,
      );
    }
  }
}

Stream<BibleSeriesState> _mapContentDetailRequestedEventToState(
  ContentDetailRequested event,
  Future<SeriesContent> Function({
    @required String seriesContentId,
    @required String bibleSeriesId,
  })
      getContentDetails,
) async* {
  yield FetchingBibleSeries();
  try {
    SeriesContent seriesContentDetail = await getContentDetails(
      seriesContentId: event.seriesContentId.toString(),
      bibleSeriesId: event.bibleSeriesId.toString(),
    );
    yield SeriesContentDetail(seriesContentDetail);
  } on BaseApplicationException catch (e) {
    yield BibleSeriesError(
      message: e.message,
      code: e.code,
    );
  } catch (e) {
    yield BibleSeriesError(
      message: 'An unknown error occured.',
      code: e.code,
    );
  }
}

Stream<BibleSeriesState> _mapGetRecentBibleSeriesEventToState(
  RecentBibleSeriesRequested event,
  Future Function() getRecentBibleSeriesFunction,
) async* {
  yield FetchingBibleSeries();
  try {
    List<BibleSeries> bibleSeriesList = await getRecentBibleSeriesFunction();
    yield RecentBibleSeries(bibleSeriesList);
  } on BaseApplicationException catch (e) {
    yield BibleSeriesError(
      message: e.message,
      code: e.code,
    );
  } catch (e) {
    yield BibleSeriesError(
      message: 'An unknown error occured.',
      code: e.code,
    );
  }
}

Stream<BibleSeriesState> _mapBibleSeriesDetailRequestedEventToState(
  BibleSeriesDetailRequested event,
  Future<BibleSeries> Function({@required String bibleSeriesId}) getBibleSeriesDetailsFunction,
  Future<Map<UniqueId, ContentCompletionDetails>> Function({@required String bibleSeriesId})
      getAllContentCompletionDetailsFunction,
) async* {
  yield FetchingBibleSeries();

  try {
    BibleSeries bibleSeries = await getBibleSeriesDetailsFunction(
      bibleSeriesId: event.bibleSeriesId.toString(),
    );

    Map<UniqueId, ContentCompletionDetails> completionDetails = await getAllContentCompletionDetailsFunction(
      bibleSeriesId: event.bibleSeriesId.toString(),
    );

    BibleSeries bibleSeriesWithCompletions = addCompletionDetailsToSeries(
      bibleSeries,
      completionDetails,
    );
    yield BibleSeriesDetail(bibleSeriesWithCompletions);
  } on BaseApplicationException catch (e) {
    yield BibleSeriesError(
      message: e.message,
      code: e.code,
    );
  } catch (e) {
    yield BibleSeriesError(
      message: 'An unknown error occured.',
      code: e.code,
    );
  }
}
