import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/bible_series/progress.dart';
import '../../domain/common/analytics.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/interfaces.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';

class BibleSeriesDetailState extends Equatable {
  const BibleSeriesDetailState({
    this.status = LoadStatus.initial,
    this.series,
    this.initialDayIndex = 0,
    this.errorMessage,
  });

  final LoadStatus status;

  /// Series with completion flags applied.
  final BibleSeries? series;

  /// Day tab to select initially (today, or the first day).
  final int initialDayIndex;
  final String? errorMessage;

  BibleSeriesDetailState copyWith({BibleSeries? series}) =>
      BibleSeriesDetailState(
        status: status,
        series: series ?? this.series,
        initialDayIndex: initialDayIndex,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, series, initialDayIndex, errorMessage];
}

class BibleSeriesDetailCubit extends Cubit<BibleSeriesDetailState> {
  BibleSeriesDetailCubit({
    required this.bibleSeriesId,
    required IBibleSeriesRepository bibleSeriesRepository,
    required ICompletionsRepository completionsRepository,
    required IAnalytics analytics,
    required AppEventBus events,
    DateTime Function()? clock,
  })  : _bibleSeries = bibleSeriesRepository,
        _completions = completionsRepository,
        _analytics = analytics,
        _clock = clock ?? DateTime.now,
        super(const BibleSeriesDetailState()) {
    _eventsSub = events.on<CompletionChanged>().listen((e) {
      if (e.seriesId == bibleSeriesId) refreshContent(e.contentId);
    });
  }

  final String bibleSeriesId;
  final IBibleSeriesRepository _bibleSeries;
  final ICompletionsRepository _completions;
  final IAnalytics _analytics;
  final DateTime Function() _clock;
  late final StreamSubscription<CompletionChanged> _eventsSub;

  Future<void> load() async {
    unawaited(_analytics.log(AnalyticsEvents.bibleSeriesViewed));
    try {
      final results = await Future.wait([
        _bibleSeries.getBibleSeriesDetails(bibleSeriesId: bibleSeriesId),
        _completions.getAllCompletions(bibleSeriesId: bibleSeriesId),
      ]);
      final series = applyCompletions(
        results[0] as BibleSeries,
        results[1] as Map<String, CompletionDetails>,
      );
      if (!isClosed) {
        emit(BibleSeriesDetailState(
          status: LoadStatus.success,
          series: series,
          initialDayIndex:
              initialDayIndex(series.seriesContentSnippet, _clock()),
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(BibleSeriesDetailState(
          status: LoadStatus.failure,
          errorMessage: userMessageFor(e),
        ));
      }
    }
  }

  /// Re-reads the completion of one content (after returning from it).
  Future<void> refreshContent(String contentId) async {
    final series = state.series;
    if (series == null) return;
    try {
      final completion =
          await _completions.getCompletionOrNull(seriesContentId: contentId);
      if (!isClosed) {
        emit(state.copyWith(
          series: applyContentCompletion(state.series!, contentId, completion),
        ));
      }
    } catch (_) {
      // Keep the current status on failure.
    }
  }

  DayStatus dayStatus(SeriesContentSnippet day) => dayStatusFor(day, _clock());

  bool isToday(SeriesContentSnippet day) => isSameLocalDay(day.date, _clock());

  @override
  Future<void> close() async {
    await _eventsSub.cancel();
    return super.close();
  }
}
