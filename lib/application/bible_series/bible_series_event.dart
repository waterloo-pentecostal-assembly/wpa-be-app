part of 'bible_series_bloc.dart';

abstract class BibleSeriesEvent extends Equatable {
  const BibleSeriesEvent();
}

class RecentBibleSeriesRequested extends BibleSeriesEvent {
  final int amount;

  RecentBibleSeriesRequested({required this.amount});
  @override
  List<Object> get props => [amount];
}

class HasActiveBibleSeriesRequested extends BibleSeriesEvent {
  @override
  List<Object> get props => [];
}

class InitialBibleSeriesListRequested extends BibleSeriesEvent {
  final int limit;

  InitialBibleSeriesListRequested(this.limit);

  @override
  List<Object> get props => [limit];
}

class NextBibleSeriesListRequested extends BibleSeriesEvent {
  final int limit;

  NextBibleSeriesListRequested(this.limit);

  @override
  List<Object> get props => [limit];
}

class BibleSeriesDetailRequested extends BibleSeriesEvent {
  final String bibleSeriesId;

  BibleSeriesDetailRequested({required this.bibleSeriesId});

  @override
  List<Object> get props => [bibleSeriesId];
}

class ContentDetailRequested extends BibleSeriesEvent {
  final String bibleSeriesId;
  final String seriesContentId;
  final bool getCompletionDetails;

  ContentDetailRequested({
    required this.bibleSeriesId,
    required this.seriesContentId,
    required this.getCompletionDetails,
  });

  @override
  List<Object> get props => [seriesContentId];
}

class UpdateCompletionDetail extends BibleSeriesEvent {
  final BibleSeries bibleSeries;
  final int scsNum;
  final int actNum;

  UpdateCompletionDetail({required this.bibleSeries, required this.actNum, required this.scsNum});

  @override
  List<Object> get props => [bibleSeries, scsNum, actNum];
}

class RestoreState extends BibleSeriesEvent {
  final BibleSeries bibleSeries;
  RestoreState(this.bibleSeries);
  @override
  List<Object> get props => [bibleSeries];
}
