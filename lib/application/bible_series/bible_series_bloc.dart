import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/value_objects.dart';

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

//TODO: handle errors
Stream<BibleSeriesState> _mapContentDetailRequestedEventToState(
  ContentDetailRequested event,
  Future<SeriesContent> Function({
    @required String seriesContentId,
    @required String bibleSeriesId,
  })
      getContentDetails,
) async* {
  yield FetchingBibleSeries();

  SeriesContent seriesContentDetails = await getContentDetails(
    seriesContentId: event.seriesContentId.toString(),
    bibleSeriesId: event.bibleSeriesId.toString(),
  );

  print('>>>>>>>>>');
  print(seriesContentDetails);
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
  Future<BibleSeries> Function({@required String bibleSeriesId}) getBibleSeriesDetailsFunction,
  Future<Map<UniqueId, ContentCompletionDetails>> Function({@required String bibleSeriesId})
      getAllContentCompletionDetailsFunction,
) async* {
  yield FetchingBibleSeries();

  BibleSeries bibleSeries = await getBibleSeriesDetailsFunction(
    bibleSeriesId: event.bibleSeriesId.toString(),
  );

  Map<UniqueId, ContentCompletionDetails> completionDetails = await getAllContentCompletionDetailsFunction(
    bibleSeriesId: event.bibleSeriesId.toString(),
  );

  BibleSeries bibleSeriesWithCompletions = _addCompletionInformation(
    bibleSeries,
    completionDetails,
  );

  yield BibleSeriesInformation(bibleSeriesWithCompletions);
}

BibleSeries _addCompletionInformation(
  BibleSeries bibleSeries,
  Map<UniqueId, ContentCompletionDetails> completionDetails,
) {
  bibleSeries.seriesContentSnippet.forEach((date) {
    int isCompletedCount = 0;
    int isOnTimeCount = 0;
    int isDraftCount = 0;

    date.isDraft = false;
    date.isCompleted = false;
    date.isOnTime = false;

    date.availableContentTypes.forEach((contentType) {
      contentType.isDraft = false;
      contentType.isCompleted = false;
      contentType.isOnTime = false;

      if (completionDetails.containsKey(contentType.contentId)) {
        ContentCompletionDetails currentCompletionDetails = completionDetails[contentType.contentId];

        if (currentCompletionDetails.isDraft) {
          contentType.isDraft = true;
          isDraftCount++;
        } else {
          contentType.isCompleted = true;
          isCompletedCount++;
          if (currentCompletionDetails.isOnTime) {
            contentType.isOnTime = true;
            isOnTimeCount++;
          }
        }
      }
    });

    if (isCompletedCount >= 1) {
      date.isCompleted = true;
      if (isOnTimeCount >= 1) {
        date.isOnTime = true;
      }
    } else if (isDraftCount >= 1) {
      date.isDraft = true;
    }
  });

  return bibleSeries;
}
