import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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

  BibleSeriesBloc(this._iBibleSeriesRepository, this._iCompletionsRepository)
      : super(BibleSeriesInitial()) {
    on<RecentBibleSeriesRequested>(_onRecentBibleSeriesRequested);
    on<BibleSeriesDetailRequested>(_onBibleSeriesDetailRequested);
    on<ContentDetailRequested>(_onContentDetailRequested);
    on<UpdateCompletionDetail>(_onUpdateCompletionDetail);
    on<RestoreState>(_onRestoreState);
    on<HasActiveBibleSeriesRequested>(_onHasActiveBibleSeriesRequested);
  }

  Future<void> _onRecentBibleSeriesRequested(
    RecentBibleSeriesRequested event,
    Emitter<BibleSeriesState> emit,
  ) async {
    emit(FetchingBibleSeries());
    try {
      List<BibleSeries> bibleSeriesList =
          await _iBibleSeriesRepository.getBibleSeries(
        limit: event.amount,
        isActive: event.isActive,
      );
      emit(RecentBibleSeries(bibleSeriesList));
    } on BaseApplicationException catch (e) {
      emit(BibleSeriesError(
        message: e.message,
      ));
    } catch (e) {
      emit(BibleSeriesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onBibleSeriesDetailRequested(
    BibleSeriesDetailRequested event,
    Emitter<BibleSeriesState> emit,
  ) async {
    try {
      BibleSeries bibleSeries =
          await _iBibleSeriesRepository.getBibleSeriesDetails(
        bibleSeriesId: event.bibleSeriesId.toString(),
      );

      Map<String, CompletionDetails> completionDetails =
          await _iCompletionsRepository.getAllCompletions(
        bibleSeriesId: event.bibleSeriesId.toString(),
      );

      BibleSeries bibleSeriesWithCompletions = addCompletionDetailsToSeries(
        bibleSeries,
        completionDetails,
      );
      emit(BibleSeriesDetail(bibleSeriesWithCompletions));
    } on BaseApplicationException catch (e) {
      emit(BibleSeriesError(
        message: e.message,
      ));
    } catch (e) {
      emit(BibleSeriesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onContentDetailRequested(
    ContentDetailRequested event,
    Emitter<BibleSeriesState> emit,
  ) async {
    try {
      SeriesContent seriesContentDetail =
          await _iBibleSeriesRepository.getContentDetails(
        seriesContentId: event.seriesContentId.toString(),
        bibleSeriesId: event.bibleSeriesId.toString(),
      );

      if (event.getCompletionDetails) {
        CompletionDetails completionDetails =
            await _iCompletionsRepository.getCompletion(
          seriesContentId: event.seriesContentId.toString(),
        );
        emit(SeriesContentDetail(seriesContentDetail, completionDetails));
      } else {
        emit(SeriesContentDetail(seriesContentDetail, null));
      }
    } on BaseApplicationException catch (e) {
      emit(BibleSeriesError(
        message: e.message,
      ));
    } catch (e) {
      emit(BibleSeriesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onUpdateCompletionDetail(
    UpdateCompletionDetail event,
    Emitter<BibleSeriesState> emit,
  ) async {
    try {
      CompletionDetails? completionDetails =
          await _iCompletionsRepository.getCompletionOrNull(
              seriesContentId: event
                  .bibleSeries
                  .seriesContentSnippet[event.scsNum]
                  .availableContentTypes[event.actNum]
                  .contentId);
      BibleSeries newBibleSeries = updateCompletionDetailToSeries(
          event.bibleSeries, completionDetails, event.scsNum, event.actNum);
      emit(UpdatedBibleSeries(newBibleSeries));
    } on BaseApplicationException catch (e) {
      emit(BibleSeriesError(message: e.message));
    } catch (e) {
      emit(BibleSeriesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onRestoreState(
    RestoreState event,
    Emitter<BibleSeriesState> emit,
  ) async {
    try {
      emit(BibleSeriesDetail(event.bibleSeries));
    } on BaseApplicationException catch (e) {
      emit(BibleSeriesError(message: e.message));
    } catch (e) {
      emit(BibleSeriesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onHasActiveBibleSeriesRequested(
    HasActiveBibleSeriesRequested event,
    Emitter<BibleSeriesState> emit,
  ) async {
    try {
      bool hasActive = await _iBibleSeriesRepository.hasActiveBibleSeries();
      emit(HasActiveBibleSeries(hasActive));
    } catch (_) {
      emit(HasActiveBibleSeries(false));
    }
  }
}
