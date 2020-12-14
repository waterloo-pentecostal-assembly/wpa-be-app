import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/interfaces.dart';
import 'helpers.dart';

part 'bible_series_event.dart';
part 'bible_series_state.dart';

class BibleSeriesBloc extends Bloc<BibleSeriesEvent, BibleSeriesState> {
  final IBibleSeriesRepository _iBibleSeriesRepository;
  final ICompletionsRepository _iCompletionsRepository;

  BibleSeriesBloc(this._iBibleSeriesRepository, this._iCompletionsRepository) : super(BibleSeriesInitial());

  @override
  Stream<BibleSeriesState> mapEventToState(
    BibleSeriesEvent event,
  ) async* {
    if (event is RecentBibleSeriesRequested) {
      yield* _mapGetRecentBibleSeriesEventToState(
        event,
        _iBibleSeriesRepository.getBibleSeries,
      );
    } else if (event is BibleSeriesDetailRequested) {
      yield* _mapBibleSeriesDetailRequestedEventToState(
        event,
        _iBibleSeriesRepository.getBibleSeriesDetails,
        _iCompletionsRepository.getAllCompletions,
      );
    } else if (event is ContentDetailRequested) {
      yield* _mapContentDetailRequestedEventToState(
        event,
        _iBibleSeriesRepository.getContentDetails,
        _iCompletionsRepository.getCompletion,
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
  Future<CompletionDetails> Function({
    @required String seriesContentId,
  })
      getCompletionDetails,
) async* {
  yield FetchingBibleSeries();
  try {
    SeriesContent seriesContentDetail = await getContentDetails(
      seriesContentId: event.seriesContentId.toString(),
      bibleSeriesId: event.bibleSeriesId.toString(),
    );

    if (event.getCompletionDetails) {
      CompletionDetails completionDetails = await getCompletionDetails(
        seriesContentId: event.seriesContentId.toString(),
      );
      yield SeriesContentDetail(seriesContentDetail, completionDetails);
    } else {
      yield SeriesContentDetail(seriesContentDetail, null);
    }
  } on BaseApplicationException catch (e) {
    yield BibleSeriesError(
      message: e.message,
    );
  } catch (e) {
    yield BibleSeriesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<BibleSeriesState> _mapGetRecentBibleSeriesEventToState(
  RecentBibleSeriesRequested event,
  Future<List<BibleSeries>> Function({@required int limit}) getBibleSeriesFunction,
) async* {
  yield FetchingBibleSeries();
  try {
    List<BibleSeries> bibleSeriesList = await getBibleSeriesFunction(limit: event.amount);
    yield RecentBibleSeries(bibleSeriesList);
  } on BaseApplicationException catch (e) {
    yield BibleSeriesError(
      message: e.message,
    );
  } catch (e) {
    yield BibleSeriesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<BibleSeriesState> _mapBibleSeriesDetailRequestedEventToState(
  BibleSeriesDetailRequested event,
  Future<BibleSeries> Function({@required String bibleSeriesId}) getBibleSeriesDetailsFunction,
  Future<Map<String, CompletionDetails>> Function({@required String bibleSeriesId}) getAllCompletionDetailsFunction,
) async* {
  yield FetchingBibleSeries();

  try {
    BibleSeries bibleSeries = await getBibleSeriesDetailsFunction(
      bibleSeriesId: event.bibleSeriesId.toString(),
    );

    Map<String, CompletionDetails> completionDetails = await getAllCompletionDetailsFunction(
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
    );
  } catch (e) {
    yield BibleSeriesError(
      message: 'An unknown error occurred',
    );
  }
}
